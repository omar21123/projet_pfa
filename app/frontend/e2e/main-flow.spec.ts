import { test, expect } from "../playwright-fixture";

test("main flow: home renders and search switch is visible", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByText("LBAL").first()).toBeVisible();
  await expect(page.getByRole("button", { name: /Membres|Members/i })).toBeVisible();
});
