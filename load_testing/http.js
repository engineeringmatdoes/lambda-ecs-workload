import http from 'k6/http';
import { sleep, check } from 'k6';

const profile = __ENV.PROFILE || 'local';
const target_url = __ENV.TARGET_URL || 'http://localhost:8080';

const profiles = {
  cloud: {
    vus: 100,
    ramp_up: '20s',
    duration: '30s',
    cool_down: '10s',
  },
  local: {
    vus: 50,
    ramp_up: '10s',
    duration: '30s',
    cool_down: '5s',
  },
}

export const options = {
  cloud: {
    projectID: 3731031, // Replace with your project ID
    name: 'homepage requests',
    distribution: {
      distributionLabel1: { loadZone: 'amazon:au:sydney', percent: 100 },
    },
  },
  // Key configurations for Stress in this section
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
