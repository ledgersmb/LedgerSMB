// MSW Handlers

// Stores
import { businessTypesHandlers} from "./store_business-types_handlers";
import { languageHandlers } from "./store_language_handlers";

export const handlers = [
  // Stores
  ...businessTypesHandlers,
  ...languageHandlers,
];
