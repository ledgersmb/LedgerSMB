/** @format */

// MSW Handlers

// Stores
import { businessTypesHandlers } from "./store_business-types_handlers";
import { gifiHandlers } from "./store_gifi_handlers";
import { countriesHandlers } from "./store_countries_handlers";
import { languageHandlers } from "./store_language_handlers";
import { pricegroupHandlers } from "./store_pricegroups_handlers";
import { sessionUserHandlers } from "./store_sessionUser_handlers";
import { sicsHandlers } from "./store_sics_handlers";
import { warehousesHandlers } from "./store_warehouses_handlers";

// Views
import { loginHandlers } from "./login_handlers";

export const handlers = [
    // Stores
    ...businessTypesHandlers,
    ...countriesHandlers,
    ...gifiHandlers,
    ...languageHandlers,
    ...pricegroupHandlers,
    ...sessionUserHandlers,
    ...sicsHandlers,
    ...warehousesHandlers,
    // Views
    ...loginHandlers
];
