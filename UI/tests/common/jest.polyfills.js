/* @format */
/* global globalThis */

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
