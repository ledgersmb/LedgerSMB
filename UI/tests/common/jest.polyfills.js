/* @format */
/* global globalThis */

import { WritableStream } from "node:stream/web";

Object.defineProperties(globalThis, {
    WritableStream: { value: WritableStream }
});
