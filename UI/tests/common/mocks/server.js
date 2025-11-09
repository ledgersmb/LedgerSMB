/** @format */
/* global globalThis */

import { setupServer } from "msw/node";
import { handlers } from "./handlers";

// This configures a Service Server with the given request handlers.
export const server = setupServer(...handlers);
