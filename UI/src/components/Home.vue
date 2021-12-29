<!-- @format -->

<template>
    <div>
        <div id="welcome" class="width100">
            <h1 style="margin-bottom: 3em">{{ $t(`Welcome to LedgerSMB`) }}</h1>
            <div class="welcomed w1">
                <h2>{{ $t(`What is LedgerSMB`) }}</h2>
                <p>
                    {{ $t(`LedgerSMB is a double entry accounting system offering a wide variety of related functionalities, such as`) }}
                </p>
                <ul>
                    <li>{{ $t(`invoicing`) }}</li>
                    <li>{{ $t(`bank reconciliation`) }}</li>
                    <li>{{ $t(`ordering`) }}</li>
                    <li>{{ $t(`keeping stock`) }}</li>
                    <li>{{ $t(`tracking hours (timecards)`) }}</li>
                    <li>{{ $t(`shipping &amp; receiving`) }}</li>
                    <li>{{ $t(`tracking of unpaid invoices`) }}</li>
                </ul>
            </div>
            <div class="welcomed w2">
                <h2>{{ $t(`Community resources`) }}</h2>
                <p>
                    {{ $t(`Community support for LedgerSMB is a available through various channels, ranging from static all the way to near-realtime (depending on availability of people):`) }}
                </p>
                <ul>
                    <li>
                        The
                        <a
                            href="https://ledgersmb.org"
                            target="_blank"
                            rel="noopener noreferrer"
                            >{{ $t(`project >project website`) }}</a
                        >
                    </li>
                    <li>
                        The
                        <a
                            href="https://ledgersmb.org/FAQ"
                            target="_blank"
                            rel="noopener noreferrer"
                            >{{ $t(`FAQ`) }}</a
                        >
                    </li>
                    <li>
                        The
                        <a
                            href="http://archive.ledgersmb.org/"
                            target="_blank"
                            rel="noopener noreferrer"
                            >{{ $t(`mailing list`) }} >
                        </a>
                    </li>
                </ul>
                <p>
                    {{ $t(`For a more interactive experience, please join one of the`) }}
                    <a
                        href="http://lists.ledgersmb.org/"
                        target="_blank"
                        rel="noopener noreferrer"
                        >{{ $t(`mailing lists`) }}</a
                    >
                </p>

                <p>
                    {{ $t(`There's also the near-realtime chat experience in the`) }}
                    <a
                        href="https://app.element.io/%23/room/%23ledgersmb:matrix.org"
                        target="_blank"
                        rel="noopener noreferrer"
                        >matrix >matrix &quot;LedgerSMB&quot; room</a
                    >
                </p>
            </div>
            <div class="welcomed w3">
                <h2>{{ $t(`Contributing`) }}</h2>
                <p>
                    {{ $t(`The project is always looking for contributions. The easiest ways to contribute to the project are:`) }}
                </p>
                <ul>
                    <li>
                        {{ $t(`Report your bugs and problems to`) }}
                        <a href="https://github.com/ledgersmb/LedgerSMB/issues/"
                            >{{ $t(`the project's GitHub bug tracker`) }}</a
                        >
                        or
                        <a href="https://lists.ledgersmb.org/">{{ $t(`mailing lists`) }}</a>
                    </li>
                    <li>
                        {{ $t(`Help translate the software through the`) }}
                        <a href="https://www.transifex.com/ledgersmb/ledgersmb/">
                            LedgerSMB >{{ $t(`LedgerSMB project Transifex web-based
                            translation translation project`) }}
                        </a>
                    </li>
                    <li>
                        Fix a
                        <a href="https://github.com/ledgersmb/LedgerSMB/issues?q=is%3aopen%20is%3aissue%20label%3abite-sized%20-label%3aenhancement"
                            >{{ $t(`bug`) }}
                        </a>
                        and submit a &quot;Pull Request&quot;<br />
                        {{ $t(`When you do, please start with one marked 'bite-sized' and contact the development team through IRC and/or matrix for help getting started.`) }}
                    </li>
                </ul>
            </div>
        </div>
      <form class="language">
        <label for="locale-select">{{ $t('Languages') }}</label>
        <select id="locale-select" v-model="currentLocale">
          <option
            v-for="optionLocale in supportLocales"
            :key="optionLocale"
            :value="optionLocale"
          >
            {{ optionLocale }}
          </option>
        </select>
      </form>
    </div>
</template>

<script>
import { watch, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { SUPPORT_LOCALES } from '@/i18n'

function markDone() {
    document.getElementById("maindiv").classList.add("done-parsing");
}

export default {
    mounted() {
        markDone();
    },
    updated() {
        markDone();
    },
    setup() {
        const router = useRouter()
        const { t, locale } = useI18n({ useScope: 'global' })

        /**
         * select locale value for language select form
         *
         * If you use the vue-i18n composer `locale` property directly, it will be re-rendering
         * component when this property is changed,
         * before dynamic import was used to asynchronously load and apply locale messages
         * To avoid this, use the another locale reactive value.
         */
        const currentLocale = ref(locale.value)

        /**
         * when change the locale, go to locale route
         *
         * when the changes are detected, load the locale message and set the language via vue-router navigation guard.
         * change the vue-i18n locale too.
         */
        watch(currentLocale, val => {
            router.push({
                name: 'home',
                params: { locale: val }
            })
        })

        return { t, locale, currentLocale, supportLocales: SUPPORT_LOCALES }
    }
};
</script>

<style scoped>
.width100 {
    width: 100%;
}
.welcomed {
    border-radius: 0.5em;
    border: 1px solid black;
    box-sizing: border-box;
    float: left;
    margin: 0.5em;
    min-width: 300px;
    padding: 1em;
}
.w1 {
    width: calc(33.3% - 1em);
}
.w2 {
    width: calc(33.4% - 1em);
}
.w3 {
    width: calc(33.3% - 1em);
}
</style>

<!-- Local overrides -->
<i18n lang="json" global>
{
  "en": {
    "Welcome to LedgerSMB": "Welcome to LedgerSMB",
    "invoicing": "invoicing",
    "bank reconciliation": "bank reconciliation",
    "ordering": "ordering",
  },
  "fr_CA": {
    "Welcome to LedgerSMB": "Bienvenue à LedgerSMB",
    "invoicing": "facturation",
    "bank reconciliation": "concilliation bancaire",
  }
}
</i18n>
