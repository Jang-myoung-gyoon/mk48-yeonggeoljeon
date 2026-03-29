import fs from 'node:fs/promises';
import path from 'node:path';
import { chromium, devices } from 'playwright';

const baseURL = process.env.RALPHTHON_BASE_URL ?? 'http://127.0.0.1:7357';
const reportDir = path.resolve('playwright-report');
const screenshotDir = path.join(reportDir, 'failures');

const desktopRoutes = [
  '/',
  '/menu',
  '/stages',
  '/briefing',
  '/formation',
  '/battle',
  '/inspector',
  '/dialogue',
  '/duel',
  '/result',
  '/officers',
  '/save',
  '/settings',
  '/game-over',
];

const mobileRoutes = ['/', '/stages', '/battle', '/result'];

const projects = [
  {
    name: 'desktop',
    use: { viewport: { width: 1440, height: 1024 } },
    routes: desktopRoutes,
  },
  {
    name: 'mobile',
    use: devices['iPhone 13'],
    routes: mobileRoutes,
  },
];

await fs.mkdir(screenshotDir, { recursive: true });

const results = [];
let failures = 0;

for (const project of projects) {
  const browser = await chromium.launch();
  const context = await browser.newContext(project.use);
  const page = await context.newPage();

  for (const route of project.routes) {
    const url = new URL(route, baseURL).toString();
    const entry = { project: project.name, route, ok: true, screenshot: null };
    try {
      await page.goto(url, { waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(2000);
      const body = await page.locator('body').innerText();
      if (body.includes('RenderFlex overflowed') || body.includes('Exception')) {
        throw new Error('Layout/runtime error text detected');
      }
      if (!page.url().endsWith(route === '/' ? '/' : route)) {
        throw new Error(`Unexpected URL after navigation: ${page.url()}`);
      }
    } catch (error) {
      failures += 1;
      entry.ok = false;
      entry.error = String(error);
      const safeRoute = route === '/' ? 'root' : route.replaceAll('/', '_');
      const screenshotPath = path.join(screenshotDir, `${project.name}-${safeRoute}.png`);
      try {
        await page.screenshot({ path: screenshotPath, fullPage: true });
        entry.screenshot = screenshotPath;
      } catch (screenshotError) {
        entry.screenshot = `unavailable: ${String(screenshotError)}`;
      }
    }
    results.push(entry);
  }

  await context.close();
  await browser.close();
}

const summary = { baseURL, failures, checked: results.length, results };
await fs.mkdir(reportDir, { recursive: true });
await fs.writeFile(
  path.join(reportDir, 'route-sweep-report.json'),
  JSON.stringify(summary, null, 2),
  'utf8',
);

console.log(JSON.stringify({ baseURL, failures, checked: results.length }, null, 2));
if (failures > 0) {
  process.exit(1);
}
