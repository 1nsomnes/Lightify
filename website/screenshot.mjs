// Usage: node screenshot.mjs <url> [label] [width]
import puppeteer from "puppeteer";
import fs from "node:fs";
import path from "node:path";

const [url = "http://localhost:3001", label, width = "1440"] = process.argv.slice(2);
const dir = path.resolve("temporary screenshots");
fs.mkdirSync(dir, { recursive: true });

const taken = fs.readdirSync(dir)
  .map((f) => Number(f.match(/^screenshot-(\d+)/)?.[1]))
  .filter((n) => !Number.isNaN(n));
const n = (taken.length ? Math.max(...taken) : 0) + 1;
const file = path.join(dir, `screenshot-${n}${label ? `-${label}` : ""}.png`);

// use the installed Chrome when there is one: Puppeteer's bundled build can lag
// behind and miss bugs that only show in current Chrome
const systemChrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const browser = await puppeteer.launch(fs.existsSync(systemChrome) ? { executablePath: systemChrome } : {});
const page = await browser.newPage();
await page.setViewport({ width: Number(width), height: 900, deviceScaleFactor: 1 });
await page.goto(url, { waitUntil: "networkidle0" });
await new Promise((r) => setTimeout(r, 1200));
await page.screenshot({ path: file, fullPage: true });
await browser.close();
console.log(file);
