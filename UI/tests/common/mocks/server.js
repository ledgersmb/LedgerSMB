/** @format */
/* global globalThis */

import { setupServer } from "msw/node";
import { handlers } from "./handlers";
const { MessageChannel, MessagePort } = require("node:worker_threads");

// This configures a Service Server with the given request handlers.
export const server = setupServer(...handlers);

Object.defineProperties(globalThis, {
    MessageChannel: { value: MessageChannel },
    MessagePort: { value: MessagePort }
});
