/** @format */

// Import Quasar css
// import "quasar/dist/quasar.css";

// Import icon libraries
import "@quasar/extras/mdi-v7";
import "@quasar/extras/material-icons/material-icons.css";
import "@quasar/extras/roboto-font/roboto-font.css";

// Specify the components you need
import {
    Quasar,
    ClosePopup,
    Dialog,
    Notify,
    LocalStorage,
    Ripple,
    QLayout,
    QHeader,
    QDrawer,
    QPageContainer,
    QPage,
    QToolbar,
    QToolbarTitle,
    QBtn,
    QIcon,
    QList,
    QItem,
    QItemSection,
    QItemLabel,
    QTable,
    QTh,
    QTr,
    QTd,
    QInput,
    QForm,
    QSelect,
    QCheckbox,
    QRadio,
    QDate,
    QSplitter,
    QTime,
    QToggle,
    QDialog,
    QCard,
    QCardSection,
    QCardActions,
    QSeparator,
    QBadge,
    QChip,
    QSpinner,
    QPopupEdit
} from "quasar";

// Configure Quasar with the components and plugins you need
const quasarConfig = {
    components: {
        QLayout,
        QHeader,
        QDrawer,
        QPageContainer,
        QPage,
        QToolbar,
        QToolbarTitle,
        QBtn,
        QIcon,
        QList,
        QItem,
        QItemSection,
        QItemLabel,
        QTable,
        QTh,
        QTr,
        QTd,
        QInput,
        QForm,
        QSelect,
        QCheckbox,
        QRadio,
        QDate,
        QSplitter,
        QTime,
        QToggle,
        QDialog,
        QCard,
        QCardSection,
        QCardActions,
        QSeparator,
        QBadge,
        QChip,
        QSpinner,
        QPopupEdit
    },
    directives: {
        ClosePopup,
        Ripple
    },
    plugins: {
        Dialog,
        Notify,
        LocalStorage
    },
    removeDefaultCss: true,
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
