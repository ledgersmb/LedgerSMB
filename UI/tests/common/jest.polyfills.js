/* @format */
/* global globalThis */

const { MessagePort } = require ("node:worker_threads");
const { WritableStream } = require("node:stream/web");

Object.defineProperties(globalThis, {
    MessagePort: { value: MessagePort }
});
Object.defineProperties(globalThis, {
    WritableStream: { value: WritableStream }
});
