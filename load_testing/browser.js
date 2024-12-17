import { browser } from 'k6/browser';
import { check } from 'k6';

const target_url = __ENV.TARGET_URL || 'http://localhost:8080';

export const options = {
  cloud: {
    projectID: 3731032, // Replace with your project ID
    name: 'browser requests',
    distribution: {
      distributionLabel1: { loadZone: 'amazon:au:sydney', percent: 100 },
    },
  },
  scenarios: {
    browser: {
      executor: 'constant-vus',
      exec: 'browserTest',
      vus: 1,
      duration: '10s',
      options: {
        browser: {
          type: 'chromium',
        },
      },
    },
   },
};

export async function browserTest() {
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    const res = await page.goto(`${target_url}/`);
    await page.waitForLoadState('domcontentloaded');

    const req = res.request();
    const response = await req.response();

    await page.screenshot({ path: `load_testing/screenshots/browser-test-results-${new Date().toISOString()}.png` });

    const text = page.locator('//div/div/header/p');

    check(text, {
      'text is visible': text.isVisible(),
      'text contains - save and reload': /and save to reload/.test(await text.innerText())
    });

    check(response, {
        'status is OK': (r) => r.ok(),
    });

  } finally {
    await page.close();
  }
}
