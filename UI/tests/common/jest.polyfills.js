/* @format */
/* global globalThis */

const { ReadableStream, TransformStream } = require("node:stream/web");
const { performance } = require("node:perf_hooks");

Object.defineProperties(globalThis, {
    ReadableStream: { value: ReadableStream },
    TransformStream: { value: TransformStream },
    performance: { value: performance }
});

const { Blob } = require("node:buffer");
const { fetch, Headers, FormData, Request, Response } = require("undici");

Object.defineProperties(globalThis, {
    fetch: { value: fetch, writable: true },
    Blob: { value: Blob },
    Headers: { value: Headers },
    FormData: { value: FormData },
    Request: { value: Request, configurable: true },
    Response: { value: Response, configurable: true }
});
