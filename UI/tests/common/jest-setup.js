/* eslint-disable no-console */

import { beforeAll, afterAll, afterEach } from "@jest/globals";
import "whatwg-fetch";

import { server } from './mocks/server.js'

beforeAll(() => {
  // Establish API mocking before all tests.
  server.listen({
    onUnhandledRequest(req) {
      console.error( // eslint-disable-line no-console
        'Found an unhandled %s request to %s',
        req.method,
        req.url.href
      )
    }
  })
})

afterAll(() => {
  // Clean up after the tests are finished.
  server.close();
})

// Reset any request handlers that we may add during the tests,
// so they don't affect other tests.
afterEach(() => {
  server.resetHandlers();
});

// Helper function to wait for DOM updates
/* eslint no-unused-expressions: ["error", { "allowTernary": true }] */
export const retry = (assertion, { interval = 20, timeout = 1000 } = {}) => {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();

    const tryAgain = () => {
      setTimeout(() => {
        try {
          resolve(assertion());
        } catch (err) {
          Date.now() - startTime > timeout ? reject(err) : tryAgain();
        }
      }, interval);
    };

    tryAgain();
  });
};

window.retry = retry;
