import http from 'k6/http';
import { sleep, check } from 'k6';

const profile = __ENV.PROFILE || 'light';
const target_url = __ENV.TARGET_URL || 'http://localhost:8080';

const profiles = {
  light: {
    vus: 50,
    ramp_up: '10s',
    duration: '30s',
    cool_down: '5s',
  },
  moderate: {
    vus: 250,
    ramp_up: '20s',
    duration: '60s',
    cool_down: '10s',
  },
  baseline: { // The peak load a single ECS container can handle
    vus: 370,
    ramp_up: '20s',
    duration: '60s',
    cool_down: '10s',
  },
  moderate_2x: { // Lambda stability testing
    vus: 500,
    ramp_up: '20s',
    duration: '60s',
    cool_down: '10s',
  },
  moderate_3x: { // Lambda stability testing
    vus: 750,
    ramp_up: '20s',
    duration: '60s',
    cool_down: '10s',
  },
  moderate_4x: { // Lambda stability testing
    vus: 900,
    ramp_up: '60s',
    duration: '120s',
    cool_down: '30s',
  },
  heavy: {
    vus: 1000,
    ramp_up: '60s',
    duration: '120s',
    cool_down: '30s',
  },
  very_heavy: {
    vus: 2000,
    ramp_up: '60s',
    duration: '120s',
    cool_down: '30s',
  },
  ultra_heavy: {
    vus: 3000,
    ramp_up: '60s',
    duration: '120s',
    cool_down: '30s',
  },
  excessive: {
    vus: 5000,
    ramp_up: '60s',
    duration: '120s',
    cool_down: '30s',
  },
}

export const options = {
  stages: [
    { duration: profiles[profile].ramp_up, target: profiles[profile].vus }, // traffic ramp-up from 1 to a higher user count over the defined time.
    { duration: profiles[profile].duration, target: profiles[profile].vus }, // stay at higher users for the defined duration
    { duration: profiles[profile].cool_down, target: 0 }, // cool down to 0 users
  ],
};

export default function Homepage() {
  const params = {
    'sec-ch-ua': '"Chromium";v="94", "Google Chrome";v="94", ";Not A Brand";v="99"',
    'accept-encoding': 'gzip, deflate, br',
    'accept-language': 'en-GB,en;q=0.9',
  };

  // 01. Go to the homepage
  let responses = http.batch([
    ['GET', target_url, params],
    ['GET', `${target_url}/static/js/main.7094825f.js`, params],
    ['GET', `${target_url}/static/css/main.f855e6bc.css`, params],
    ['GET', `${target_url}/static/media/logo.6ce24c58023cc2f8fd88fe9d219db6c6.svg`, params],
    ['GET', `${target_url}/favicon.ico`, params],
    ['GET', `${target_url}/manifest.json`, params],
    ['GET', `${target_url}/logo512.png`, params],

  ]);
  check(responses, {
    'Homepage loaded': (r) => JSON.stringify(r).includes('save to reload'),
  });

  sleep(0.5);
}
