import { expect, test } from "@playwright/test";

const desktopRoutes = [
  "/",
  "/menu",
  "/stages",
  "/briefing",
  "/formation",
  "/battle",
  "/inspector",
  "/dialogue",
  "/duel",
  "/result",
  "/officers",
  "/save",
  "/settings",
  "/game-over",
] as const;

const mobileRoutes = ["/", "/stages", "/battle", "/result"] as const;

async function expectFlutterShell(page: import("@playwright/test").Page) {
  await page.waitForLoadState("domcontentloaded");
  await page.waitForTimeout(1500);
  await expect(
    page.locator("flt-glass-pane, flutter-view, canvas").first(),
  ).toBeVisible();
  await expect(page.locator("body")).not.toContainText("Exception");
  await expect(page.locator("body")).not.toContainText("RenderFlex overflowed");
}

test.describe("route sweep", () => {
  for (const route of desktopRoutes) {
    test(`desktop renders ${route}`, async ({ page }) => {
      await page.goto(route);
      await expect(page).toHaveURL(
        new RegExp(`${route === "/" ? "/$" : `${route}$`}`),
      );
      await expectFlutterShell(page);
    });
  }

  for (const route of mobileRoutes) {
    test(`mobile renders ${route}`, async ({ page, browserName }, testInfo) => {
      test.skip(
        testInfo.project.name !== "mobile-chromium",
        "mobile-only sweep",
      );
      await page.goto(route);
      await expect(page).toHaveURL(
        new RegExp(`${route === "/" ? "/$" : `${route}$`}`),
      );
      await expectFlutterShell(page);
      expect(browserName).toBeTruthy();
    });
  }
});
