import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import type { KeyboardEvent as ReactKeyboardEvent, MouseEvent as ReactMouseEvent, PointerEvent as ReactPointerEvent } from "react";
import { Icon, type IconName } from "./icons";
import {
  type Item,
  type Kind,
  albumItem,
  albumTracks,
  albums,
  artists,
  followers,
  playlists,
  rankedAlbums,
  rankedPlaylists,
  rankedTracks,
  trackItem,
  tracks,
} from "./data";

/*
 * A working copy of Lightify's home page (lib/pages/home_page.dart), drawn at
 * the app's own size and scaled to fit. Keys follow lib/components/search.dart
 * and the popup pages.
 */

export const WINDOW_W = 800;
export const WINDOW_H = 624;

const GREEN = "#1DB954";
const SEEK_STEP_MS = 5000; // Settings.seekStep default

type Repeat = "off" | "context" | "one";

type Page =
  | { type: "artist"; id: string }
  | { type: "album"; id: string }
  | { type: "playlist"; id: string }
  | { type: "user"; id: string }
  | { type: "queue" };

type Popup = { key: number; page: Page; closing: boolean };

// what Enter plays: a list of track ids, starting at one of them
type Play = { context: string[]; index: number };

const ALL_KINDS: Kind[] = ["track", "album", "playlist"];
const KIND_LETTER: Record<Kind, string> = { track: "T", album: "A", playlist: "P" };

// ---------- search results ----------

function matches(item: Item, q: string) {
  return `${item.name} ${item.subtitle}`.toLowerCase().includes(q);
}

function merge(lists: Item[][], interleave: boolean): Item[] {
  if (!interleave) return lists.flat();
  const out: Item[] = [];
  const longest = Math.max(0, ...lists.map((l) => l.length));
  for (let i = 0; i < longest; i++) for (const l of lists) if (i < l.length) out.push(l[i]);
  return out;
}

function computeShown(kinds: Set<Kind>, mine: boolean, query: string): Item[] {
  const q = query.trim().toLowerCase();
  const saved = {
    track: rankedTracks.filter((i) => tracks[i.id].saved),
    album: rankedAlbums.filter((i) => albums[i.id].saved),
    playlist: rankedPlaylists.filter((i) => playlists[i.id].saved),
  };
  const all = { track: rankedTracks, album: rankedAlbums, playlist: rankedPlaylists };
  const source = mine ? saved : all;
  const lists = ALL_KINDS.filter((k) => kinds.has(k)).map((k) => (q ? source[k].filter((i) => matches(i, q)) : source[k]));
  // search results mix by rank; your whole library reads better grouped
  return merge(lists, !mine || q.length > 0);
}

// ---------- pages ----------

type Row =
  | { type: "header"; kind: string; icon: IconName; name: string; details: string; cover: Item["cover"]; round: boolean }
  | { type: "title"; title: string }
  | { type: "label"; title: string }
  | { type: "empty"; title: string }
  | { type: "item"; item: Item; number?: number; icon?: IconName; play?: Play };

function creatorPage(item: Item): Page | null {
  if (item.kind === "track") return { type: "artist", id: tracks[item.id].artistId };
  if (item.kind === "album") return { type: "artist", id: albums[item.id].artistId };
  const owner = playlists[item.id].owner;
  return { type: "user", id: owner };
}

function albumPage(item: Item): Page | null {
  if (item.kind === "track") return { type: "album", id: tracks[item.id].albumId };
  if (item.kind === "album") return { type: "album", id: item.id };
  return null;
}

function collectionPage(item: Item): Page | null {
  if (item.kind === "album") return { type: "album", id: item.id };
  if (item.kind === "playlist") return { type: "playlist", id: item.id };
  return null;
}

function numbered(ids: string[], subtitle?: (id: string) => string): Row[] {
  return ids.map((id, i) => ({
    type: "item",
    item: trackItem(tracks[id], subtitle?.(id)),
    number: i + 1,
    play: { context: ids, index: i },
  }));
}

function pageRows(page: Page, now: string, queue: string[], upNext: string[]): Row[] {
  switch (page.type) {
    case "artist": {
      const a = artists[page.id];
      const popular = Object.values(tracks)
        .filter((t) => t.artistId === a.id)
        .slice(0, 5)
        .map((t) => t.id);
      const discography = Object.values(albums).filter((al) => al.artistId === a.id);
      return [
        { type: "header", kind: "Artist", icon: "verified", name: a.name, details: `${followers(a.followers)}  ·  ${a.genres}`, cover: a.cover, round: true },
        {
          type: "item",
          icon: "radio",
          item: { key: `radio:${a.id}`, kind: "track", id: popular[0], name: "Artist radio", subtitle: `Songs by ${a.name}, then similar music`, cover: a.cover },
          play: { context: popular, index: 0 },
        },
        { type: "title", title: "Popular" },
        ...numbered(popular, (id) => albums[tracks[id].albumId].name),
        { type: "title", title: "Discography" },
        ...discography.map((al): Row => ({ type: "item", item: { ...albumItem(al), subtitle: `${al.year}` } })),
      ];
    }
    case "album": {
      const al = albums[page.id];
      const ids = albumTracks(al.id).map((t) => t.id);
      const minutes = Math.round(ids.reduce((s, id) => s + tracks[id].durationMs, 0) / 60000);
      return [
        { type: "header", kind: "Album", icon: "album", name: al.name, details: `${artists[al.artistId].name}  ·  ${al.year}  ·  ${ids.length} songs, ${minutes} min`, cover: al.cover, round: false },
        { type: "title", title: "Tracks" },
        ...numbered(ids),
      ];
    }
    case "playlist": {
      const pl = playlists[page.id];
      return [
        { type: "header", kind: "Playlist", icon: "queueMusic", name: pl.name, details: `${pl.owner === "you" ? "You" : pl.owner}  ·  ${pl.trackIds.length} songs`, cover: pl.cover, round: false },
        { type: "title", title: "Tracks" },
        ...numbered(pl.trackIds),
      ];
    }
    case "user": {
      const owned = Object.values(playlists).filter((p) => p.owner === page.id);
      const name = page.id === "you" ? "You" : page.id;
      return [
        { type: "header", kind: "User profile", icon: "person", name, details: followers(page.id === "you" ? 12 : 318), cover: owned[0]?.cover ?? { bg: "#2A2B30" }, round: true },
        { type: "title", title: "Public playlists" },
        ...owned.map((p): Row => ({ type: "item", item: { key: `playlist:${p.id}`, kind: "playlist", id: p.id, name: p.name, subtitle: `${p.trackIds.length} songs`, cover: p.cover } })),
      ];
    }
    case "queue": {
      const next = [...queue, ...upNext];
      return [
        { type: "label", title: "Now playing" },
        { type: "item", item: trackItem(tracks[now]) },
        { type: "label", title: "Next up" },
        ...(next.length
          ? next.map((id, i): Row => ({ type: "item", item: { ...trackItem(tracks[id]), key: `q${i}:${id}` }, play: { context: next, index: i } }))
          : [{ type: "empty" as const, title: "Nothing queued" }]),
      ];
    }
  }
}

// ---------- small pieces ----------

function Art({ cover, size, radius, round, icon }: { cover: Item["cover"]; size: number; radius: number; round?: boolean; icon?: IconName }) {
  if (icon) {
    return (
      <span className="grid shrink-0 place-items-center" style={{ width: size, height: size, borderRadius: radius, background: "#1DB95426", color: GREEN }}>
        <Icon name={icon} size={24} />
      </span>
    );
  }
  return <span className="block shrink-0" style={{ width: size, height: size, borderRadius: round ? "50%" : radius, background: cover.bg }} />;
}

const noFocus = (e: ReactMouseEvent) => e.preventDefault();

function ItemTile({ item, selected, showKind, icon, onClick }: { item: Item; selected: boolean; showKind?: boolean; icon?: IconName; onClick: () => void }) {
  return (
    <div className="px-[10px]">
      <button
        type="button"
        tabIndex={-1}
        onMouseDown={noFocus}
        onClick={onClick}
        className="lf-row flex h-[64px] w-full items-center gap-4 rounded-[12px] px-4 text-left"
        style={{ background: selected ? "#FFFFFF14" : undefined }}
      >
        <span className="overflow-hidden rounded-[4px]">
          <Art cover={item.cover} size={48} radius={4} icon={icon} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate text-[16px] leading-[1.35]" style={{ color: selected ? GREEN : "#fff" }}>
            {item.name}
          </span>
          <span className="block truncate text-[11px] font-medium leading-[1.45]" style={{ color: selected ? GREEN : "#fff" }}>
            {item.subtitle}
          </span>
        </span>
        {showKind && (
          <span className="text-[13px]" style={{ color: selected ? GREEN : "#FFFFFF8A" }}>
            {KIND_LETTER[item.kind]}
          </span>
        )}
      </button>
    </div>
  );
}

function Pill({ label, selected, icon, onClick }: { label: string; selected: boolean; icon?: IconName; onClick: () => void }) {
  return (
    <button
      type="button"
      tabIndex={-1}
      onMouseDown={noFocus}
      onClick={onClick}
      aria-pressed={selected}
      className="lf-press mx-1 flex items-center gap-1.5 rounded-full border px-[14px] py-[7px] text-[13px] font-semibold leading-none"
      style={{
        background: selected ? "#1DB95426" : "transparent",
        borderColor: selected ? "#1DB95480" : "#FFFFFF3D",
        color: selected ? "#fff" : "#FFFFFF8A",
      }}
    >
      {icon && <Icon name={icon} size={14} className={selected ? "text-[#1DB954]" : ""} />}
      {label}
    </button>
  );
}

function Control({ icon, label, onClick, active, size = 20 }: { icon: IconName; label: string; onClick: () => void; active?: boolean; size?: number }) {
  const color = active === undefined ? "#FFFFFFB3" : active ? "#fff" : "#FFFFFF61";
  return (
    <button type="button" tabIndex={-1} onMouseDown={noFocus} onClick={onClick} title={label} aria-label={label} className="lf-press relative grid size-[38px] place-items-center rounded-full" style={{ color }}>
      <Icon name={icon} size={size} />
      {active && <span className="absolute bottom-[3px] size-1 rounded-full bg-white" />}
    </button>
  );
}

const fmt = (ms: number) => {
  const s = Math.floor(ms / 1000);
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
};

function ProgressBar({ current, duration, onSeek }: { current: number; duration: number; onSeek: (ms: number) => void }) {
  const [hover, setHover] = useState(false);
  const [drag, setDrag] = useState<number | null>(null);
  const barRef = useRef<HTMLDivElement>(null);
  const fraction = drag ?? (duration ? current / duration : 0);
  const active = hover || drag !== null;

  const at = (e: ReactPointerEvent) => {
    const r = barRef.current!.getBoundingClientRect();
    return Math.min(1, Math.max(0, (e.clientX - r.left) / r.width));
  };

  return (
    <div className="flex items-center text-[11px] tabular-nums" style={{ color: "#FFFFFF8A" }}>
      <span className="w-9">{fmt(drag !== null ? fraction * duration : current)}</span>
      <div
        ref={barRef}
        className="relative h-4 flex-1 cursor-pointer touch-none"
        onPointerEnter={() => setHover(true)}
        onPointerLeave={() => setHover(false)}
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          setDrag(at(e));
        }}
        onPointerMove={(e) => drag !== null && setDrag(at(e))}
        onPointerUp={(e) => {
          if (drag === null) return;
          onSeek(Math.round(at(e) * duration));
          setDrag(null);
        }}
      >
        <div className="lf-bar absolute inset-x-0 top-1/2 h-[5px] -translate-y-1/2" style={{ transform: `translateY(-50%) scaleY(${active ? 1 : 0.6})` }}>
          <div className="absolute inset-0 rounded-[3px] bg-white/25" />
          <div className="absolute inset-0 origin-left rounded-[3px]" style={{ transform: `scaleX(${fraction})`, background: active ? "#fff" : "#FFFFFFB3" }} />
        </div>
        {active && <span className="absolute top-1/2 size-3 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white" style={{ left: `${fraction * 100}%` }} />}
      </div>
      <span className="w-9 text-right">{fmt(duration)}</span>
    </div>
  );
}

// ---------- popup page ----------

type PageHandle = { onKey: (e: KeyboardEvent) => boolean };

function PopupPage({
  page,
  rows,
  onClose,
  onPlay,
  onQueue,
  onOpen,
  handleRef,
}: {
  page: Page;
  rows: Row[];
  onClose: () => void;
  onPlay: (play: Play) => void;
  onQueue: (trackId: string) => void;
  onOpen: (page: Page | null) => void;
  handleRef: (h: PageHandle | null) => void;
}) {
  const selectable = useMemo(() => rows.flatMap((r, i) => (r.type === "item" ? [i] : [])), [rows]);
  const [sel, setSel] = useState(0);
  const listRef = useRef<HTMLDivElement>(null);
  const rowRefs = useRef<(HTMLDivElement | null)[]>([]);

  const selectedRow = rows[selectable[sel]] as Extract<Row, { type: "item" }> | undefined;

  const activate = useCallback(
    (row: Extract<Row, { type: "item" }> | undefined) => {
      if (!row) return;
      if (row.play) onPlay(row.play);
      else if (row.item.kind === "track") onPlay({ context: [row.item.id], index: 0 });
      else onOpen(collectionPage(row.item));
    },
    [onPlay, onOpen],
  );

  useEffect(() => {
    handleRef({
      onKey: (e) => {
        const k = e.key;
        if (k === "j" || k === "ArrowDown") setSel((s) => Math.min(selectable.length - 1, s + 1));
        else if (k === "k" || k === "ArrowUp") setSel((s) => Math.max(0, s - 1));
        else if (k === "Enter") activate(selectedRow);
        else if (k === "q" && selectedRow?.item.kind === "track") onQueue(selectedRow.item.id);
        else if (k === "A" && selectedRow) onOpen(albumPage(selectedRow.item));
        else if (k === "O" && selectedRow) onOpen(collectionPage(selectedRow.item));
        else if (k === "P" && selectedRow) onOpen(creatorPage(selectedRow.item));
        else return false;
        return true;
      },
    });
    return () => handleRef(null);
  }, [handleRef, selectable, selectedRow, activate, onQueue, onOpen]);

  useLayoutEffect(() => {
    const list = listRef.current;
    const el = rowRefs.current[selectable[sel]];
    if (!list) return;
    // scrollTo returns a promise in newer Chrome, so never return it from an effect
    const top = !el || sel === 0 ? 0 : el.offsetTop - list.clientHeight * 0.38;
    list.scrollTo({ top, behavior: "smooth" });
  }, [sel, selectable]);

  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center gap-1 px-2 pt-2 pr-4">
        <button type="button" tabIndex={-1} onMouseDown={noFocus} onClick={onClose} title="Back (Esc)" aria-label="Back" className="lf-press grid size-12 place-items-center rounded-full text-white">
          <Icon name="back" />
        </button>
        {page.type === "queue" && <span className="text-[25px] text-white">Queue</span>}
      </div>
      <div ref={listRef} className="lf-scroll relative min-h-0 flex-1 overflow-y-auto pb-4">
        {rows.map((row, i) => {
          const ref = (el: HTMLDivElement | null) => {
            rowRefs.current[i] = el;
          };
          switch (row.type) {
            case "header":
              return (
                <div key={i} ref={ref} className="relative h-[190px] overflow-hidden">
                  <div className="absolute inset-[-40px] opacity-45 blur-[30px]" style={{ background: row.cover.bg }} />
                  <div className="absolute inset-0" style={{ background: "linear-gradient(180deg, #11121500, #111215EB)" }} />
                  <div className="relative flex h-full items-end gap-6 px-6 pb-5 pt-4">
                    <span className="overflow-hidden shadow-[0_0_20px_#00000099]" style={{ borderRadius: row.round ? "50%" : 6 }}>
                      <Art cover={row.cover} size={128} radius={6} round={row.round} />
                    </span>
                    <div className="min-w-0 flex-1">
                      <span className="inline-flex items-center gap-1.5 rounded-full border border-[#1DB95480] bg-[#1DB95426] px-2.5 py-1 text-[10px] font-bold uppercase leading-none tracking-[1.6px] text-white">
                        <Icon name={row.icon} size={12} className="text-[#1DB954]" />
                        {row.kind}
                      </span>
                      <div className="mt-2.5 truncate text-[36px] font-extrabold leading-[1.1] text-white">{row.name}</div>
                      <div className="mt-1.5 truncate text-[13px] text-white/70">{row.details}</div>
                    </div>
                  </div>
                </div>
              );
            case "title":
              return (
                <div key={i} ref={ref} className="px-4 pb-1 pt-5 text-[20px] font-bold text-white">
                  {row.title}
                </div>
              );
            case "label":
              return (
                <div key={i} ref={ref} className="px-6 pb-1 pt-3 text-[11px] font-semibold tracking-[1.2px] text-white/55 uppercase">
                  {row.title}
                </div>
              );
            case "empty":
              return (
                <div key={i} ref={ref} className="py-10 text-center text-[13px] text-white/55">
                  {row.title}
                </div>
              );
            case "item": {
              const index = selectable.indexOf(i);
              const selected = index === sel;
              return (
                <div key={row.item.key + i} ref={ref} className="flex items-center">
                  {row.number !== undefined && (
                    <span className="w-9 text-right text-[14px]" style={{ color: selected ? GREEN : "#FFFFFF8A" }}>
                      {row.number}
                    </span>
                  )}
                  <div className="min-w-0 flex-1">
                    <ItemTile
                      item={row.item}
                      icon={row.icon}
                      selected={selected}
                      onClick={() => {
                        setSel(index);
                        activate(row);
                      }}
                    />
                  </div>
                </div>
              );
            }
          }
        })}
      </div>
    </div>
  );
}

// ---------- the window ----------

export default function LightifyDemo({ summonSignal, onHiddenChange }: { summonSignal: number; onHiddenChange?: (hidden: boolean) => void }) {
  const rootRef = useRef<HTMLDivElement>(null);
  const windowRef = useRef<HTMLDivElement>(null);
  const searchRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  // filters and results
  const [kinds, setKinds] = useState<Set<Kind>>(() => new Set(ALL_KINDS));
  const [mine, setMine] = useState(false);
  const [text, setText] = useState("");
  const [query, setQuery] = useState("");
  const shown = useMemo(() => computeShown(kinds, mine, query), [kinds, mine, query]);
  const [selected, setSelected] = useState(0);
  const [playerSelected, setPlayerSelected] = useState(false);
  const beforeSearch = useRef({ selected: 0, player: false, query: "" });

  // playback
  const [now, setNow] = useState<Play>({ context: albumTracks("glasswork").map((t) => t.id), index: 0 });
  const [playing, setPlaying] = useState(true);
  const [shuffle, setShuffle] = useState(true);
  const [repeat, setRepeat] = useState<Repeat>("off");
  const [base, setBase] = useState({ ms: 62_000, at: Date.now() });
  const [queue, setQueue] = useState<string[]>([]);
  const [, tick] = useState(0);

  // popups and window
  const [popups, setPopups] = useState<Popup[]>([]);
  const popupKey = useRef(0);
  const pageHandle = useRef<PageHandle | null>(null);
  const [hidden, setHidden] = useState(false);
  const [scale, setScale] = useState(1);

  const nowId = now.context[now.index];
  const nowTrack = tracks[nowId];
  const duration = nowTrack.durationMs;
  const current = Math.min(duration, base.ms + (playing ? Date.now() - base.at : 0));

  // ----- playback actions -----

  const startTrack = useCallback((play: Play, ms = 0) => {
    setNow(play);
    setBase({ ms, at: Date.now() });
    setPlaying(true);
  }, []);

  const next = useCallback(() => {
    if (queue.length) {
      const [id, ...rest] = queue;
      setQueue(rest);
      startTrack({ context: [id, ...now.context.slice(now.index + 1)], index: 0 });
      return;
    }
    const n = now.context.length;
    const index = shuffle && n > 1 ? (now.index + 1 + Math.floor(Math.random() * (n - 1))) % n : (now.index + 1) % n;
    startTrack({ ...now, index });
  }, [queue, now, shuffle, startTrack]);

  const previous = useCallback(() => {
    if (current > 3000 || now.index === 0) setBase({ ms: 0, at: Date.now() });
    else startTrack({ ...now, index: now.index - 1 });
  }, [current, now, startTrack]);

  const togglePlay = useCallback(() => {
    setBase({ ms: current, at: Date.now() });
    setPlaying((p) => !p);
  }, [current]);

  const seek = useCallback((ms: number) => setBase({ ms: Math.max(0, Math.min(duration - 1000, ms)), at: Date.now() }), [duration]);

  // advance the bar, and move on at the end of a song
  useEffect(() => {
    if (!playing || hidden) return;
    const id = setInterval(() => {
      tick((n) => n + 1);
    }, 250);
    return () => clearInterval(id);
  }, [playing, hidden]);
  useEffect(() => {
    if (!playing || current < duration) return;
    if (repeat === "one") setBase({ ms: 0, at: Date.now() });
    else next();
  });

  const playItem = useCallback(
    (item: Item) => {
      if (item.kind === "track") {
        if (mine) {
          // a liked song plays inside your liked songs
          const liked = shown.filter((i) => i.kind === "track").map((i) => i.id);
          startTrack({ context: liked, index: liked.indexOf(item.id) });
        } else {
          const ids = albumTracks(tracks[item.id].albumId).map((t) => t.id);
          startTrack({ context: ids, index: ids.indexOf(item.id) });
        }
      } else if (item.kind === "album") {
        startTrack({ context: albumTracks(item.id).map((t) => t.id), index: 0 });
      } else {
        startTrack({ context: playlists[item.id].trackIds, index: 0 });
      }
    },
    [mine, shown, startTrack],
  );

  // ----- popups -----

  const openPage = useCallback((page: Page | null) => {
    if (!page) return;
    const key = ++popupKey.current;
    setPopups((ps) => [...ps.filter((p) => !p.closing), { key, page, closing: false }]);
  }, []);

  const closePage = useCallback(() => {
    setPopups((ps) => {
      const top = ps[ps.length - 1];
      return top ? [{ ...top, closing: true }] : ps;
    });
  }, []);

  const onPopupAnimationEnd = (p: Popup, index: number) => {
    if (p.closing) setPopups((ps) => ps.filter((x) => x.key !== p.key));
    // a replacement finished sliding in: drop the ones it covers
    else if (index > 0) setPopups((ps) => ps.slice(ps.findIndex((x) => x.key === p.key)));
  };

  const setHandle = useCallback((h: PageHandle | null) => {
    pageHandle.current = h;
  }, []);

  // ----- window -----

  const focusList = () => rootRef.current?.focus({ preventScroll: true });

  const hide = useCallback(() => {
    setPopups([]);
    setPlayerSelected(false);
    setHidden(true);
  }, []);

  // like opening the real window: the search field takes focus. Runs once
  // the window is on screen, so it waits for a render when it was hidden
  const [summoned, setSummoned] = useState(0);
  const show = useCallback(() => {
    setHidden(false);
    setSummoned((n) => n + 1);
  }, []);
  useLayoutEffect(() => {
    if (!summoned) return;
    beforeSearch.current = { selected: Math.max(0, selected), player: playerSelected, query: text.trim() };
    setSelected(-1);
    setPlayerSelected(false);
    searchRef.current?.focus({ preventScroll: true });
    summonAnimation(windowRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [summoned]);

  // the window opens with the page, the same way it opens on your Mac
  useEffect(() => {
    summonAnimation(windowRef.current, 900);
  }, []);

  useEffect(() => {
    onHiddenChange?.(hidden);
  }, [hidden, onHiddenChange]);

  const firstSignal = useRef(summonSignal);
  useEffect(() => {
    if (summonSignal === firstSignal.current) return;
    if (hidden || !rootRef.current?.contains(document.activeElement)) show();
    else hide();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [summonSignal]);

  // fit the 800px window into the page
  useLayoutEffect(() => {
    const el = rootRef.current?.parentElement;
    if (!el) return;
    const ro = new ResizeObserver(([entry]) => setScale(Math.min(1, entry.contentRect.width / WINDOW_W)));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  // keep the selection in view, a little above the middle
  useLayoutEffect(() => {
    const list = listRef.current;
    if (!list) return;
    const row = selected > 0 ? (list.children[selected] as HTMLElement | undefined) : undefined;
    list.scrollTo({ top: row ? row.offsetTop - list.clientHeight * 0.38 : 0, behavior: "smooth" });
  }, [selected, shown]);

  // ----- filters -----

  const reselect = (nextShown: Item[]) => {
    if (selected < 0) return;
    const prevKey = shown[selected]?.key;
    const index = nextShown.findIndex((i) => i.key === prevKey);
    setSelected(index >= 0 ? index : Math.max(0, Math.min(selected, nextShown.length - 1)));
  };

  const toggleKind = (kind: Kind) => {
    // keep at least one kind on, so the list is never empty by accident
    if (kinds.has(kind) && kinds.size === 1) return;
    const nextKinds = new Set(kinds);
    if (!nextKinds.delete(kind)) nextKinds.add(kind);
    setKinds(nextKinds);
    reselect(computeShown(nextKinds, mine, query));
  };

  const toggleMine = () => {
    setMine(!mine);
    reselect(computeShown(kinds, !mine, query));
  };

  // search as you type, after a pause
  useEffect(() => {
    const q = text.trim();
    if (q === query) return;
    const id = setTimeout(() => setQuery(q), 400);
    return () => clearTimeout(id);
  }, [text, query]);

  const submitSearch = () => {
    const q = text.trim();
    const unchanged = q === beforeSearch.current.query;
    setQuery(q);
    const nextShown = computeShown(kinds, mine, q);
    setSelected(unchanged ? Math.max(0, Math.min(beforeSearch.current.selected, nextShown.length - 1)) : 0);
    setPlayerSelected(unchanged && beforeSearch.current.player);
    focusList();
  };

  const focusSearch = () => {
    beforeSearch.current = { selected, player: playerSelected, query: text.trim() };
    setPlayerSelected(false);
    setSelected(-1);
    searchRef.current?.focus({ preventScroll: true });
  };

  // ----- keys -----

  const selectedItem: Item | null = playerSelected ? trackItem(nowTrack) : selected >= 0 ? (shown[selected] ?? null) : null;

  const moveSelection = (delta: number) => {
    if (playerSelected) {
      if (delta > 0 && shown.length) {
        setPlayerSelected(false);
        setSelected(0);
      }
      return;
    }
    if (delta < 0 && selected <= 0) {
      setPlayerSelected(true);
      return;
    }
    if (!shown.length) return;
    setSelected(Math.max(0, Math.min(shown.length - 1, selected + delta)));
  };

  const onBaseKey = (e: KeyboardEvent): boolean => {
    const k = e.key;
    switch (k) {
      case "Tab":
        focusSearch();
        break;
      case "j":
      case "ArrowDown":
        moveSelection(1);
        break;
      case "k":
      case "ArrowUp":
        moveSelection(-1);
        break;
      case " ":
        togglePlay();
        break;
      case "h":
        previous();
        break;
      case "l":
        next();
        break;
      case "H":
        seek(current - SEEK_STEP_MS);
        break;
      case "L":
        seek(current + SEEK_STEP_MS);
        break;
      case "s":
        setShuffle((s) => !s);
        break;
      case "r":
        setRepeat((r) => (r === "off" ? "context" : r === "context" ? "one" : "off"));
        break;
      case "t":
        toggleKind("track");
        break;
      case "a":
        toggleKind("album");
        break;
      case "p":
        toggleKind("playlist");
        break;
      case "m":
        toggleMine();
        break;
      case "q":
        if (selectedItem?.kind === "track") setQueue((q) => [...q, selectedItem.id]);
        break;
      case "Q":
        openPage({ type: "queue" });
        break;
      case "A":
        if (selectedItem) openPage(albumPage(selectedItem));
        break;
      case "O":
        if (selectedItem) openPage(collectionPage(selectedItem));
        break;
      case "P":
        if (selectedItem) openPage(creatorPage(selectedItem));
        break;
      case "C":
        setPlayerSelected(true);
        listRef.current?.scrollTo({ top: 0, behavior: "smooth" });
        break;
      case "Enter":
        // the playing song is already playing
        if (!playerSelected && selectedItem) playItem(selectedItem);
        break;
      default:
        return false;
    }
    return true;
  };

  const onKey = (e: KeyboardEvent) => {
    if (hidden || e.metaKey || e.ctrlKey || e.altKey) return;
    const active = document.activeElement;
    const inside = rootRef.current?.contains(active);
    // only take keys meant for the page: nothing else focused, or the demo is
    if (!inside && active !== document.body && active !== null) return;
    // the field handles its own keys (Enter there moves focus to the list
    // before this listener runs, so check where the key was typed)
    if (e.target === searchRef.current || active === searchRef.current) return;

    // a popup that's sliding away no longer takes keys
    const popupOpen = popups.some((p) => !p.closing);
    let handled: boolean;
    if (e.key === "Escape") {
      if (popupOpen) closePage();
      else hide();
      handled = true;
    } else if (popupOpen) {
      handled = pageHandle.current?.onKey(e) ?? false;
      // the base page is out of reach while a popup is open, but Tab still
      // shouldn't move focus away
      if (e.key === "Tab" && inside) handled = true;
    } else {
      // Tab only belongs to the demo once it has focus
      handled = e.key === "Tab" && !inside ? false : onBaseKey(e);
    }
    if (handled) {
      e.preventDefault();
      if (!inside) focusList();
    }
  };

  const onKeyRef = useRef(onKey);
  onKeyRef.current = onKey;
  useEffect(() => {
    const listener = (e: KeyboardEvent) => onKeyRef.current(e);
    window.addEventListener("keydown", listener);
    return () => window.removeEventListener("keydown", listener);
  }, []);

  const onSearchKey = (e: ReactKeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      submitSearch();
    } else if (e.key === "Escape") {
      e.preventDefault();
      hide();
    }
  };

  const upNext = now.context.slice(now.index + 1, now.index + 9);
  const visiblePopups = popups.map((p, i) => ({ p, i, rows: pageRows(p.page, nowId, queue, upNext) }));
  const filterLabels: [Kind, string][] = [
    ["track", "Tracks"],
    ["album", "Albums"],
    ["playlist", "Playlists"],
  ];

  return (
    <div style={{ height: WINDOW_H * scale }} className="relative">
      <div
        ref={rootRef}
        tabIndex={-1}
        aria-label="Lightify, working demo. Use the keyboard shortcuts listed below."
        role="application"
        className="lf-root absolute left-1/2 top-0 origin-top outline-none"
        style={{ width: WINDOW_W, height: WINDOW_H, transform: `translateX(-50%) scale(${scale})` }}
      >
        {hidden ? (
          <div className="grid h-full place-items-center">
            <button type="button" onClick={show} className="lf-reopen flex flex-col items-center gap-4 rounded-[20px] bg-white/55 px-8 py-6 text-ink shadow-[var(--shadow-elevated)] ring-1 ring-ink/5 backdrop-blur-xl">
              <span className="flex gap-2">
                {["⌘", "⇧", "S"].map((k) => (
                  <kbd key={k} className="cap size-12 rounded-[11px] font-sans text-[20px] font-medium">
                    {k}
                  </kbd>
                ))}
              </span>
              <span className="font-sans text-[15px] text-slate">Lightify is hidden. Press the shortcut, or click here, to bring it back.</span>
            </button>
          </div>
        ) : (
          <div
            ref={windowRef}
            className="lf-window relative h-full overflow-hidden rounded-[12px] text-white"
            onMouseDown={(e) => {
              if (e.target !== searchRef.current) {
                e.preventDefault();
                focusList();
              }
            }}
          >
            <div className="flex h-full flex-col">
              {/* NowPlaying */}
              <div className="mx-[10px] mb-1 mt-[10px] flex items-center gap-[18px] rounded-[12px] p-[10px]" style={{ background: playerSelected ? "#FFFFFF14" : undefined }}>
                <span className="size-[92px] shrink-0 overflow-hidden rounded-[8px] shadow-[0_0_16px_#00000066]">
                  <Art cover={albums[nowTrack.albumId].cover} size={92} radius={8} />
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center">
                    <div className="min-w-0 flex-1">
                      <div className="truncate text-[18px] font-semibold leading-[1.25]" style={{ color: playerSelected ? GREEN : "#fff" }}>
                        {nowTrack.name}
                      </div>
                      <div className="mt-[3px] truncate text-[13px] text-white/60">{artists[nowTrack.artistId].name}</div>
                    </div>
                    <div className="ml-3 flex items-center">
                      <Control icon="shuffle" label="Shuffle (S)" active={shuffle} onClick={() => setShuffle(!shuffle)} />
                      <Control icon="previous" label="Previous (H)" size={26} onClick={previous} />
                      <button
                        type="button"
                        tabIndex={-1}
                        onMouseDown={noFocus}
                        onClick={togglePlay}
                        title={playing ? "Pause (Space)" : "Play (Space)"}
                        aria-label={playing ? "Pause" : "Play"}
                        className="lf-press mx-1 grid size-[38px] place-items-center rounded-full bg-white text-black"
                      >
                        <Icon name={playing ? "pause" : "play"} size={24} />
                      </button>
                      <Control icon="next" label="Next (L)" size={26} onClick={next} />
                      <Control icon={repeat === "one" ? "repeatOne" : "repeat"} label="Repeat (R)" active={repeat !== "off"} onClick={() => setRepeat(repeat === "off" ? "context" : repeat === "context" ? "one" : "off")} />
                    </div>
                  </div>
                  <div className="mt-[14px]">
                    <ProgressBar current={current} duration={duration} onSeek={seek} />
                  </div>
                </div>
              </div>

              {/* Search */}
              <div className="p-2">
                <label className="lf-search flex h-[44px] items-center rounded-full border border-white/25 bg-white/[0.06]">
                  <span className="grid w-12 place-items-center text-white/55">
                    <Icon name="search" size={20} />
                  </span>
                  <input
                    ref={searchRef}
                    value={text}
                    onChange={(e) => setText(e.target.value)}
                    onKeyDown={onSearchKey}
                    onFocus={() => {
                      if (selected >= 0) focusSearch();
                    }}
                    placeholder="Search…"
                    aria-label="Search"
                    spellCheck={false}
                    className="h-full min-w-0 flex-1 bg-transparent pr-4 text-[15px] text-white caret-white/70 outline-none placeholder:text-white/40"
                  />
                </label>
              </div>

              {/* WindowSelection */}
              <div className="flex items-center justify-between px-1 pb-2">
                <div className="flex">
                  {filterLabels.map(([kind, label]) => (
                    <Pill key={kind} label={label} selected={kinds.has(kind)} onClick={() => toggleKind(kind)} />
                  ))}
                </div>
                <Pill label="Mine" icon="favorite" selected={mine} onClick={toggleMine} />
              </div>

              {/* results */}
              <div ref={listRef} className="lf-scroll relative min-h-0 flex-1 overflow-y-auto">
                {shown.map((item, i) => (
                  <ItemTile
                    key={item.key}
                    item={item}
                    showKind
                    selected={i === selected && !playerSelected}
                    onClick={() => {
                      setPlayerSelected(false);
                      setSelected(i);
                      playItem(item);
                    }}
                  />
                ))}
                {shown.length === 0 && <div className="py-12 text-center text-[13px] text-white/55">Nothing matches “{query}”</div>}
              </div>
              <div className="h-4 shrink-0" />
            </div>

            {/* PopupHost */}
            {visiblePopups.map(({ p, i, rows }) => (
              <div key={p.key} className="absolute inset-0">
                {i === 0 && <div className={`absolute inset-0 bg-black/35 ${p.closing ? "lf-fade-out" : "lf-fade-in"}`} />}
                <div
                  className={`absolute inset-x-6 bottom-0 top-10 overflow-hidden rounded-[12px] border-t border-white/[0.12] bg-[#111215EB] shadow-[0_-4px_24px_#00000099] ${p.closing ? "lf-slide-out" : "lf-slide-in"}`}
                  onAnimationEnd={(e) => e.target === e.currentTarget && onPopupAnimationEnd(p, i)}
                >
                  <PopupPage
                    page={p.page}
                    rows={rows}
                    onClose={closePage}
                    onPlay={(play) => startTrack(play)}
                    onQueue={(id) => setQueue((q) => [...q, id])}
                    onOpen={openPage}
                    handleRef={i === visiblePopups.length - 1 && !p.closing ? setHandle : noop}
                  />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function noop() {}

// only transform and opacity, and nothing kept afterwards: a lingering
// transform on the window would switch off its backdrop blur
function summonAnimation(el: HTMLElement | null, duration = 520) {
  if (!el || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  el.animate(
    [
      { opacity: 0, transform: "translateY(16px) scale(0.97)" },
      { opacity: 1, transform: "none" },
    ],
    { duration, easing: "cubic-bezier(0.16, 1, 0.3, 1)" },
  );
}
