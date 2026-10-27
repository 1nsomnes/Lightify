// Renders og/index.html to public/og.png, the link preview image.
// Usage: start the dev server (node serve.mjs), then node og.mjs [url]
import puppeteer from "puppeteer";
import fs from "node:fs";

const [url = "http://localhost:3001/og/"] = process.argv.slice(2);

const systemChrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const browser = await puppeteer.launch(fs.existsSync(systemChrome) ? { executablePath: systemChrome } : {});
const page = await browser.newPage();
await page.setViewport({ width: 1200, height: 630, deviceScaleFactor: 1 });
await page.goto(url, { waitUntil: "networkidle0" });
await page.evaluate(() => document.fonts.ready);
await new Promise((r) => setTimeout(r, 1500)); // let the demo's entrance finish
await page.screenshot({ path: "public/og.png", clip: { x: 0, y: 0, width: 1200, height: 630 } });
await browser.close();
console.log("public/og.png");
