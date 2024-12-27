/* global globalThis */

const { TextEncoder, TextDecoder } = require("node:util");
const { ReadableStream, TransformStream } = require("node:stream/web");
const { MessageChannel, MessagePort } = require("node:worker_threads");
const { performance } = require("node:perf_hooks");

Object.defineProperties(globalThis, {
    MessageChannel: { value: MessageChannel },
    MessagePort: { value: MessagePort },
    ReadableStream: { value: ReadableStream },
    TextDecoder: { value: TextDecoder },
    TextEncoder: { value: TextEncoder },
    TransformStream: { value: TransformStream },
    performance: { value: performance }
})

const { Blob } = require('node:buffer')
const { fetch, Headers, FormData, Request, Response } = require('undici')

Object.defineProperties(globalThis, {
    fetch: { value: fetch, writable: true },
    Blob: { value: Blob },
    Headers: { value: Headers },
    FormData: { value: FormData },
    Request: { value: Request, configurable: true },
    Response: { value: Response, configurable: true }
});
