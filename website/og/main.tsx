import { createRoot } from "react-dom/client";
import LightifyDemo from "../src/demo/LightifyDemo";
import "../src/index.css";

// The stroke from the Lightify logo (brand_assets/lightify_icon.svg)
const LOGO_PATH =
  "M-8 102 C 18 94, 50 72, 65 42 C 75 20, 69 6, 59 12 C 47 20, 44 58, 50 82 C 55 101, 73 105, 91 95 C 105 87, 115 76, 130 62";

// 1200x630, composed around the center so square crops still read
function Card() {
  return (
    <div className="backdrop relative h-[630px] w-[1200px] overflow-hidden">
      <div className="grain pointer-events-none absolute inset-0" />

      <div className="relative z-10 flex flex-col items-center pt-[58px] text-center">
        <span className="flex gap-3">
          {["⌘", "⇧", "S"].map((k) => (
            <kbd key={k} className="cap size-[68px] rounded-[16px] font-sans text-[28px] font-medium text-ink">
              {k}
            </kbd>
          ))}
        </span>
        <h1 className="mt-7 font-display text-[54px] leading-[1.04] tracking-[-0.03em] text-ink">
          Spotify, from anywhere
          <br /> on your Mac.
        </h1>
      </div>

      <div className="absolute left-1/2 top-[338px] w-[600px] -translate-x-1/2">
        <svg
          viewBox="-10 0 140 120"
          aria-hidden="true"
          className="stroke-fade pointer-events-none absolute left-1/2 top-[200px] w-[720px] max-w-none -translate-x-1/2 -translate-y-1/2 text-ink"
        >
          <path d={LOGO_PATH} fill="none" stroke="currentColor" strokeWidth={4} strokeLinecap="round" strokeLinejoin="round" />
        </svg>
        <div className="relative">
          <LightifyDemo summonSignal={0} />
        </div>
      </div>
    </div>
  );
}

document.body.style.margin = "0";
createRoot(document.getElementById("root")!).render(<Card />);
