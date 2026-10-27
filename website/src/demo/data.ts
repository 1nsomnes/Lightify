// A small made-up catalog for the demo. Artwork is generated so the page
// doesn't ship anyone's real album covers.

export type Kind = "track" | "album" | "playlist";

export type Cover = { bg: string };

export type Track = {
  id: string;
  name: string;
  artistId: string;
  albumId: string;
  durationMs: number;
  saved?: boolean;
};

export type Album = {
  id: string;
  name: string;
  artistId: string;
  year: number;
  cover: Cover;
  saved?: boolean;
};

export type Artist = {
  id: string;
  name: string;
  followers: number;
  genres: string;
  cover: Cover;
};

export type Playlist = {
  id: string;
  name: string;
  owner: string;
  cover: Cover;
  trackIds: string[];
  saved?: boolean;
};

// a row in any list: what ItemTile shows
export type Item = {
  key: string;
  kind: Kind;
  id: string;
  name: string;
  subtitle: string;
  cover: Cover;
};

type Palette = [string, string, string];

function cover(style: number, [a, b, c]: Palette): Cover {
  const styles = [
    `radial-gradient(circle at 32% 34%, ${c} 0 17%, transparent 18%), linear-gradient(140deg, ${a}, ${b})`,
    `radial-gradient(circle at 50% 120%, ${c}cc, transparent 60%), repeating-linear-gradient(90deg, ${a} 0 14%, ${b} 14% 28%)`,
    `conic-gradient(from 210deg at 62% 58%, ${a}, ${b}, ${c}, ${a})`,
    `radial-gradient(circle at 50% 56%, ${c} 0 22%, transparent 23%), linear-gradient(180deg, ${a} 0 58%, ${b} 58%)`,
    `radial-gradient(circle at 74% 78%, ${b}, transparent 62%), radial-gradient(circle at 22% 20%, ${c}, transparent 52%), ${a}`,
  ];
  return { bg: styles[style % styles.length] };
}

export const artists: Record<string, Artist> = {
  juno: { id: "juno", name: "Juno Vale", followers: 482_310, genres: "dream pop", cover: cover(4, ["#2b3a55", "#d9a3b8", "#9fd6e0"]) },
  harbor: { id: "harbor", name: "Pale Harbor", followers: 1_204_877, genres: "indie rock", cover: cover(4, ["#22302b", "#7fa37a", "#e7d9b0"]) },
  orchard: { id: "orchard", name: "The Night Orchard", followers: 96_542, genres: "shoegaze", cover: cover(4, ["#1d1a2b", "#6b4fa0", "#f0a35e"]) },
  ostra: { id: "ostra", name: "Ostra", followers: 2_871_005, genres: "electronic", cover: cover(4, ["#0f2a33", "#2fa3a0", "#f3e7c4"]) },
  field: { id: "field", name: "Field Theory", followers: 233_118, genres: "ambient", cover: cover(4, ["#33291f", "#c47b48", "#efe2cf"]) },
};

export const albums: Record<string, Album> = {
  glasswork: { id: "glasswork", name: "Glasswork", artistId: "juno", year: 2024, cover: cover(0, ["#7cc6d9", "#f2c6de", "#fff6c9"]), saved: true },
  lowtide: { id: "lowtide", name: "Low Tide Hymns", artistId: "harbor", year: 2022, cover: cover(3, ["#9cb8c9", "#2d3f4a", "#f0e3b8"]), saved: true },
  orchard: { id: "orchard", name: "Orchard Lights", artistId: "orchard", year: 2023, cover: cover(2, ["#2a1e3f", "#c0603a", "#f2c46b"]) },
  saltwater: { id: "saltwater", name: "Saltwater Radio", artistId: "ostra", year: 2025, cover: cover(1, ["#12343d", "#1f5a60", "#7be0c8"]), saved: true },
  smallhours: { id: "smallhours", name: "Small Hours", artistId: "field", year: 2021, cover: cover(0, ["#4a3a2c", "#b98a5e", "#f4ead6"]) },
  flicker: { id: "flicker", name: "Flicker EP", artistId: "juno", year: 2021, cover: cover(2, ["#3b2b4f", "#e08fa8", "#a7e0e9"]) },
};

const t = (id: string, name: string, albumId: string, min: number, sec: number, saved = false): Track => ({
  id,
  name,
  albumId,
  artistId: albums[albumId].artistId,
  durationMs: (min * 60 + sec) * 1000,
  saved,
});

export const tracks: Record<string, Track> = Object.fromEntries(
  [
    t("glasshouses", "Glass Houses", "glasswork", 3, 47, true),
    t("weightless", "Weightless", "glasswork", 4, 12),
    t("softfocus", "Soft Focus", "glasswork", 3, 21, true),
    t("pools", "Swimming Pools in March", "glasswork", 5, 2),
    t("afterglow", "Afterglow", "flicker", 3, 38),
    t("ribbons", "Ribbons", "flicker", 2, 56, true),
    t("lighthouse", "Lighthouse Keeper", "lowtide", 4, 31, true),
    t("undertow", "Undertow", "lowtide", 3, 54),
    t("northwind", "North Wind, South Shore", "lowtide", 4, 8),
    t("anchors", "Anchors", "lowtide", 3, 12, true),
    t("lanterns", "Lanterns", "orchard", 5, 44),
    t("bloom", "Night Bloom", "orchard", 4, 19, true),
    t("static", "Static Hymn", "orchard", 6, 2),
    t("tidal", "Tidal", "saltwater", 3, 33, true),
    t("signal", "Signal Fade", "saltwater", 4, 47),
    t("coastline", "Coastline (Long Version)", "saltwater", 7, 15),
    t("frequency", "Low Frequency", "saltwater", 3, 59, true),
    t("kettle", "Kettle Steam", "smallhours", 2, 48),
    t("fouram", "4 AM", "smallhours", 3, 27, true),
    t("windows", "Rain on Windows", "smallhours", 5, 11),
  ].map((tr) => [tr.id, tr]),
);

export const playlists: Record<string, Playlist> = {
  latenight: {
    id: "latenight",
    name: "Late Night Drive",
    owner: "you",
    cover: cover(3, ["#1b2340", "#0d1020", "#f6b06b"]),
    trackIds: ["signal", "bloom", "glasshouses", "undertow", "coastline", "fouram"],
    saved: true,
  },
  focus: {
    id: "focus",
    name: "Deep Work",
    owner: "you",
    cover: cover(1, ["#20302a", "#2f4a3e", "#b8e6c4"]),
    trackIds: ["windows", "kettle", "frequency", "static", "pools"],
    saved: true,
  },
  sunday: {
    id: "sunday",
    name: "Sunday Slow",
    owner: "mara",
    cover: cover(0, ["#e9b9a0", "#c46a5a", "#fff1d6"]),
    trackIds: ["softfocus", "lighthouse", "ribbons", "anchors", "afterglow"],
  },
};

export const albumTracks = (albumId: string) => Object.values(tracks).filter((tr) => tr.albumId === albumId);

export function trackItem(tr: Track, subtitle?: string): Item {
  return {
    key: `track:${tr.id}`,
    kind: "track",
    id: tr.id,
    name: tr.name,
    subtitle: subtitle ?? artists[tr.artistId].name,
    cover: albums[tr.albumId].cover,
  };
}

export function albumItem(al: Album): Item {
  return { key: `album:${al.id}`, kind: "album", id: al.id, name: al.name, subtitle: artists[al.artistId].name, cover: al.cover };
}

export function playlistItem(pl: Playlist): Item {
  return { key: `playlist:${pl.id}`, kind: "playlist", id: pl.id, name: pl.name, subtitle: pl.owner === "you" ? "You" : pl.owner, cover: pl.cover };
}

// results per kind, ranked the way a search would return them
export const rankedTracks = [
  "glasshouses", "lighthouse", "tidal", "bloom", "softfocus", "fouram", "signal", "undertow",
  "weightless", "ribbons", "lanterns", "frequency", "anchors", "kettle", "coastline", "afterglow",
  "northwind", "static", "windows", "pools",
].map((id) => trackItem(tracks[id]));
export const rankedAlbums = ["glasswork", "saltwater", "lowtide", "orchard", "smallhours", "flicker"].map((id) => albumItem(albums[id]));
export const rankedPlaylists = ["latenight", "focus", "sunday"].map((id) => playlistItem(playlists[id]));

export const followers = (n: number) => `${n.toLocaleString("en-US")} followers`;
