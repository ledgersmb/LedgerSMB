/** @format */

// Import Quasar css
// import "quasar/dist/quasar.css";

// Import icon libraries
// import "@quasar/extras/mdi-v7";
import iconSet from "quasar/icon-set/mdi-v7";
import "@quasar/extras/mdi-v7/mdi-v7.css";
import "@quasar/extras/roboto-font/roboto-font.css";

// Specify the components you need
import { Quasar, Notify } from "quasar";

// Configure Quasar with the components and plugins you need
const quasarConfig = {
    plugins: {
        Notify
    },
    iconSet: iconSet,
    extras: ["mdi-v7"],
    config: {
        // Optional Quasar configs
        notify: {
            position: "top-right",
            timeout: 2500
        }
    }
};

// Export a function to initialize Quasar in your Vue app
export function installQuasar(app) {
    app.use(Quasar, quasarConfig);
}
