/* @format */
/* global globalThis */

const { WritableStream } = require("node:stream/web");

Object.defineProperties(globalThis, {
    WritableStream: { value: WritableStream }
});
