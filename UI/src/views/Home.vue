<!-- @format -->

<script>
export default {};
</script>

<template>
    <!-- eslint-disable prettier/prettier -->
    <div>
        <div id="welcome" class="width100">
            <h1 style="margin-bottom: 3em">{{ $t(`Welcome to LedgerSMB`) }}</h1>
            <div class="welcomed w1">
                <h2>{{ $t(`What is LedgerSMB`) }}</h2>
                <p>{{ $t(`LedgerSMB is a double entry accounting system offering a wide
                  variety of related functionalities, such as`) }}</p>
                <ul>
                    <li>{{ $t(`invoicing`) }}</li>
                    <li>{{ $t(`bank reconciliation`) }}</li>
                    <li>{{ $t(`ordering`) }}</li>
                    <li>{{ $t(`keeping stock`) }}</li>
                    <li>{{ $t(`tracking hours (timecards)`) }}</li>
                    <li>{{ $t(`shipping &amp; receiving`) }}</li>
                    <li>{{ $t(`tracking of unpaid invoices`) }}</li>
                </ul>
                <p>
                    Express your support and appreciation by Starring us on
                    <a href="https://github.com/ledgersmb/LedgerSMB">GitHub</a>.
                </p>
            </div>
            <div class="welcomed w2">
                <h2>{{ $t(`Community resources`) }}</h2>
                <p>{{ $t(`Community support for LedgerSMB is a available through various
                  channels, ranging from static all the way to near-realtime (depending
                  on availability of people):`) }}</p>
                <ul>
                    <li>The <a href="https://ledgersmb.org" target="_blank"
                               rel="noopener noreferrer">project
                        website</a></li>
                    <li>The <a href="https://ledgersmb.org/FAQ" target="_blank"
                               rel="noopener noreferrer">{{ $t(`FAQ`) }}</a></li>
                    <li>The <a href="http://archive.ledgersmb.org/" target="_blank"
                               rel="noopener noreferrer">mailing list
                        archives</a></li>
                </ul>
                <p>For a more interactive experience, please join
                    one of the <a href="http://lists.ledgersmb.org/" target="_blank"
                                  rel="noopener noreferrer">{{ $t(`mailing lists`) }}</a></p>

                <p>There's also the near-realtime chat experience in the
                    <a href="https://app.element.io/%23/room/%23ledgersmb:matrix.org"
                       target="_blank" rel="noopener noreferrer">matrix
                        &quot;LedgerSMB&quot; room</a></p>
            </div>
            <div class="welcomed w3">
                <h2>{{ $t(`Contributing`) }}</h2>
                <p>{{ $t(`The project is always looking for contributions. The easiest ways to
                  contribute to the project are:`) }}</p>
                <ul>
                    <li>Report your bugs and problems
                        to <a href="https://github.com/ledgersmb/LedgerSMB/issues/">the
                            project's GitHub bug tracker</a> or
                        <a href="https://lists.ledgersmb.org/">{{ $t(`mailing lists`) }}</a></li>
                    <li>Help translate the software through the <a href="https://www.transifex.com/ledgersmb/ledgersmb/">LedgerSMB
                        project Transifex web-based translation project</a></li>
                    <li>Fix a <a href="https://github.com/ledgersmb/LedgerSMB/issues?q=is%3aopen%20is%3aissue%20label%3abite-sized%20-label%3aenhancement">{{ $t(`bug`) }}</a> and
                        submit a &quot;Pull Request&quot;<br>
                        When you do, please start with one marked 'bite-sized' and contact
                        the development team through IRC and/or matrix for help getting
                        started.</li>
                </ul>
            </div>
        </div>
    </div>
</template>

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
