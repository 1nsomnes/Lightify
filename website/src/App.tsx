import { useEffect, useState } from "react";
import LightifyDemo from "./demo/LightifyDemo";

const DOWNLOAD_URL = "https://github.com/1nsomnes/Lightify/releases/latest";
const REPO_URL = "https://github.com/1nsomnes/Lightify";

// The stroke from the Lightify logo (brand_assets/lightify_icon.svg)
const LOGO_PATH =
  "M-8 102 C 18 94, 50 72, 65 42 C 75 20, 69 6, 59 12 C 47 20, 44 58, 50 82 C 55 101, 73 105, 91 95 C 105 87, 115 76, 130 62";

const BINDS: { keys: string[]; label: string }[] = [
  { keys: ["J", "K"], label: "Move" },
  { keys: ["Enter"], label: "Play" },
  { keys: ["Space"], label: "Pause" },
  { keys: ["H", "L"], label: "Previous, next" },
  { keys: ["Q"], label: "Queue" },
  { keys: ["T", "A", "P"], label: "Filter results" },
  { keys: ["M"], label: "Your library" },
  { keys: ["⇧", "P"], label: "Open artist" },
  { keys: ["⇧", "A"], label: "Open album" },
  { keys: ["⇧", "Q"], label: "Open queue" },
  { keys: ["Tab"], label: "Search" },
  { keys: ["Esc"], label: "Back" },
];

function normalize(e: KeyboardEvent): string {
  if (e.key === "Meta") return "⌘";
  if (e.key === "Shift") return "⇧";
  if (e.key === " ") return "Space";
  if (e.key === "Escape") return "Esc";
  return e.key.length === 1 ? e.key.toUpperCase() : e.key;
}

function usePressedKeys() {
  const [down, setDown] = useState<Set<string>>(new Set());
  const [summons, setSummons] = useState(0);

  useEffect(() => {
    const onDown = (e: KeyboardEvent) => {
      const k = normalize(e);
      if (k === "Space" && e.target === document.body) e.preventDefault();
      if (e.metaKey && e.shiftKey && k === "S") {
        e.preventDefault();
        setSummons((n) => n + 1);
      }
      setDown((prev) => new Set(prev).add(k));
    };
    const onUp = (e: KeyboardEvent) => {
      const k = normalize(e);
      setDown((prev) => {
        const next = new Set(prev);
        next.delete(k);
        // macOS swallows keyups for other keys while ⌘ is held
        if (k === "⌘") return new Set();
        return next;
      });
    };
    const clear = () => setDown(new Set());
    window.addEventListener("keydown", onDown);
    window.addEventListener("keyup", onUp);
    window.addEventListener("blur", clear);
    return () => {
      window.removeEventListener("keydown", onDown);
      window.removeEventListener("keyup", onUp);
      window.removeEventListener("blur", clear);
    };
  }, []);

  return { down, summons };
}

function Mark({ className, viewBox = "0 0 120 120", weight = 11 }: { className?: string; viewBox?: string; weight?: number }) {
  return (
    <svg viewBox={viewBox} aria-hidden="true" className={className}>
      <path
        d={LOGO_PATH}
        fill="none"
        stroke="currentColor"
        strokeWidth={weight}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function AppleGlyph() {
  return (
    <svg viewBox="0 0 17 20" aria-hidden="true" className="h-[18px] w-[16px] -translate-y-px">
      <path
        fill="currentColor"
        d="M14.1 10.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9-.8 0-2-.9-3.4-.9C3.6 4.8 2 5.8 1.1 7.4c-1.9 3.2-.5 8 1.3 10.6.9 1.3 1.9 2.7 3.3 2.6 1.3-.1 1.8-.9 3.4-.9s2 .9 3.4.8c1.4 0 2.3-1.3 3.2-2.6 1-1.5 1.4-2.9 1.4-3-.1 0-2.9-1.1-3-4.3ZM11.5 3c.7-.9 1.2-2 1-3.2-1 0-2.3.7-3 1.5-.7.8-1.2 2-1.1 3.1 1.2.1 2.3-.6 3.1-1.4Z"
      />
    </svg>
  );
}

const linkStates =
  "rounded-md outline-none transition-opacity duration-200 hover:opacity-70 active:opacity-50 focus-visible:ring-2 focus-visible:ring-ink/40 focus-visible:ring-offset-4 focus-visible:ring-offset-frost";

export default function App() {
  const { down, summons } = usePressedKeys();
  const isDown = (k: string) => (down.has(k) ? "true" : "false");

  return (
    <div className="backdrop relative min-h-screen overflow-x-clip">
      <div className="grain pointer-events-none absolute inset-0 z-0" aria-hidden="true" />

      <header className="relative z-20 mx-auto flex max-w-[1120px] items-center justify-between px-6 pt-6 sm:px-10 sm:pt-8">
        <a href="/" className={`flex items-center gap-2.5 ${linkStates}`}>
          <span className="grid size-8 place-items-center overflow-hidden rounded-[9px] bg-white shadow-[var(--shadow-elevated)]">
            <Mark className="size-8 text-ink" />
          </span>
          <span className="text-[15px] font-semibold tracking-[-0.01em]">Lightify</span>
        </a>
        <a href={REPO_URL} className={`text-[14px] font-medium text-slate ${linkStates}`}>
          Source on GitHub
        </a>
      </header>

      <main className="relative z-10 mx-auto max-w-[1120px] px-6 sm:px-10">
        <section className="flex flex-col items-center pt-20 text-center sm:pt-28">
          <h1 className="font-display text-[44px] leading-[1.04] tracking-[-0.03em] sm:text-[72px]">
            <span className="mb-5 flex justify-center gap-2.5 sm:mb-7 sm:gap-3.5" aria-label="Command Shift S">
              {["⌘", "⇧", "S"].map((k) => (
                <kbd
                  key={k}
                  data-down={isDown(k)}
                  className="cap size-[60px] rounded-[14px] font-sans text-[26px] font-medium text-ink sm:size-[84px] sm:rounded-[18px] sm:text-[34px]"
                >
                  {k}
                </kbd>
              ))}
            </span>
            Spotify, from anywhere
            <br className="hidden sm:block" /> on your Mac.
          </h1>

          <p className="mt-6 max-w-[34rem] text-pretty text-[17px] text-slate sm:mt-8 sm:text-[18px]">
            Lightify is a Spotlight-style Spotify player. Summon it, search, queue and play
            with vim keys, then get back to what you were doing.
          </p>

          <div className="mt-10 flex flex-col items-center gap-3">
            <a
              href={DOWNLOAD_URL}
              className="group inline-flex items-center gap-2.5 rounded-full bg-ink py-3.5 pl-6 pr-7 text-[16px] font-medium text-white shadow-[var(--shadow-elevated)] outline-none transition-transform duration-300 ease-[var(--ease-spring)] hover:-translate-y-0.5 active:translate-y-0 active:scale-[0.98] focus-visible:ring-2 focus-visible:ring-ink/50 focus-visible:ring-offset-4 focus-visible:ring-offset-frost"
            >
              <AppleGlyph />
              Download for Mac
            </a>
            <span className="text-[13px] text-slate/80">Version 1.0.0, free</span>
          </div>
        </section>

        <section className="relative mx-auto mt-16 max-w-[860px] sm:mt-24" aria-label="Lightify demo">
          {/* the logo's stroke, running behind the glass */}
          <Mark
            viewBox="-10 0 140 120"
            weight={5}
            className="stroke-fade pointer-events-none absolute left-1/2 top-1/2 w-[135%] max-w-none -translate-x-1/2 -translate-y-[47%] text-ink sm:w-[118%]"
          />

          <div className="relative">
            <LightifyDemo summonSignal={summons} />
          </div>
        </section>

        <section className="mx-auto mt-14 max-w-[900px] sm:mt-16" aria-label="Keybinds">
          <ul className="flex flex-wrap justify-center gap-x-6 gap-y-3.5">
            {BINDS.map(({ keys, label }) => (
              <li key={label} className="flex items-center gap-2.5 text-[14px] text-slate">
                <span className="flex gap-1">
                  {keys.map((k) => (
                    <kbd
                      key={k}
                      data-down={isDown(k)}
                      className="cap h-7 min-w-7 rounded-[7px] px-2 font-sans text-[12px] font-medium text-ink"
                    >
                      {k}
                    </kbd>
                  ))}
                </span>
                {label}
              </li>
            ))}
          </ul>
          <p className="mt-6 text-center text-[13px] text-slate/70">
            The window above is a working copy of Lightify, playing made-up music. Every
            shortcut is in the{" "}
            <a href={`${REPO_URL}#keybinds`} className={`text-ink underline decoration-ink/25 underline-offset-4 ${linkStates}`}>
              README
            </a>
            .
          </p>
        </section>
      </main>

      <footer className="relative z-10 mx-auto mt-28 flex max-w-[1120px] flex-col gap-2 px-6 pb-10 text-[13px] text-slate/70 sm:flex-row sm:justify-between sm:px-10">
        <span>Lightify is an independent project and is not affiliated with Spotify.</span>
        <a href={`${REPO_URL}/blob/main/LICENSE`} className={`self-start sm:self-auto ${linkStates}`}>
          CC BY-NC 4.0
        </a>
      </footer>
    </div>
  );
}
