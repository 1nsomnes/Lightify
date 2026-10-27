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

const browser = await puppeteer.launch();
const page = await browser.newPage();
await page.setViewport({ width: Number(width), height: 900, deviceScaleFactor: 1 });
await page.goto(url, { waitUntil: "networkidle0" });
await new Promise((r) => setTimeout(r, 1200));
await page.screenshot({ path: file, fullPage: true });
await browser.close();
console.log(file);
