<template>
    <div>
        <div id="welcome" class="width100">
            <h1 style="margin-bottom: 3em">{{ $t(`Welcome to LedgerSMB`) }}</h1>
            <div class="welcomed w1">
                <h2>{{ $t(`What is LedgerSMB`) }}</h2>
                <p>{{ $t(`i18n.home.ledgersmbIntro`) }}</p>
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
                <p>{{ $t(`i18n.home.communitySupport`) }}</p>
                <ul>
                  <i18n-t keypath="i18n.home.projectWebsite.text" tag="li" scope="global">
                    <template #url><a :href="website_url" target="_blank" rel="noopener noreferrer">
                        {{ $t("i18n.home.projectWebsite.link") }}
                    </a></template>
                  </i18n-t>
                  <i18n-t keypath="i18n.home.FAQ.text" tag="li" scope="global">
                    <template #url><a :href="faq_url" target="_blank" rel="noopener noreferrer">
                        {{ $t("i18n.home.FAQ.link") }}
                    </a></template>
                  </i18n-t>
                  <i18n-t keypath="i18n.home.mailingListsArchives.text" tag="li" scope="global">
                    <template #url><a :href="mailingListsArchives_url" target="_blank" rel="noopener noreferrer">
                        {{ $t("i18n.home.mailingListsArchives.link") }}
                    </a></template>
                  </i18n-t>
                </ul>

                <i18n-t keypath="i18n.home.experience.text" tag="p" scope="global">
                  <template #url><a :href="experience_url" target="_blank" rel="noopener noreferrer">
                      {{ $t("i18n.home.experience.link") }}
                  </a></template>
                </i18n-t>

                <i18n-t keypath="i18n.home.nearRealtime.text" tag="p" scope="global">
                  <template #url><a :href="nearRealtime_url" target="_blank" rel="noopener noreferrer">
                    {{ $t("i18n.home.nearRealtime.link") }}
                  </a></template>
                </i18n-t>
            </div>
            <div class="welcomed w3">
                <h2>{{ $t(`Contributing`) }}</h2>
                <p>{{ $t("i18n.home.contributions") }}</p>
                <ul>
                  <i18n-t keypath="i18n.home.reportBugs.text" tag="li" scope="global">
                    <template #url1><a :href="reportBugs_url1" target="_blank" rel="noopener noreferrer">
                        {{ $t("i18n.home.reportBugs.link1") }}
                    </a></template>
                    <template #url2><a :href="reportBugs_url2" target="_blank" rel="noopener noreferrer">
                        {{ $t("i18n.home.reportBugs.link2") }}
                    </a></template>
                  </i18n-t>
                <i18n-t keypath="i18n.home.translate.text" tag="li" scope="global">
                    <template #url><a :href="translate_url" target="_blank" rel="noopener noreferrer">
                        {{ $t("i18n.home.translate.link") }}
                    </a></template>
                  </i18n-t>
                  <i18n-t keypath="i18n.home.fixBugs.text" tag="li" scope="global">
                    <template #url><a :href="fixBugs_url" target="_blank" rel="noopener noreferrer">
                        {{ $t("i18n.home.fixBugs.link") }}
                    </a></template>
                  </i18n-t>
                </ul>
            </div>
        </div>
    </div>
</template>

<script>

export default {
  data() {
    return {
      experience_url: "http://lists.ledgersmb.org/",
      faq_url: "https://ledgersmb.org/FAQ",
      fixBugs_url: "https://github.com/ledgersmb/LedgerSMB/issues?q=is%3aopen%20is%3aissue%20label%3abite-sized%20-label%3aenhancement",
      mailingListsArchives_url: "http://archive.ledgersmb.org/",
      nearRealtime_url: "https://app.element.io/%23/room/%23ledgersmb:matrix.org",
      reportBugs_url1: "https://github.com/ledgersmb/LedgerSMB/issues/",
      reportBugs_url2: "https://lists.ledgersmb.org/",
      translate_url: "https://www.transifex.com/ledgersmb/ledgersmb/",
      website_url: "https://ledgersmb.org"
    }
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
