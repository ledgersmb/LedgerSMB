<!-- @format -->
<!-- eslint-disable -->

<template>
    <form name="login" style="max-width:fit-content">
      <div class="login" id="logindiv">
        <div class="login" align="center">
          <a href="http://www.ledgersmb.org/"
             target="_top">
            <img src="images/ledgersmb.png"
                 class="logo"
                 alt="LedgerSMB Logo" /></a>
          <div id="maindiv" style="position:relative; min-width:max-content; height:15em;">
            <div style="z-index: 10; position: absolute;
                     top: 50%; left: 50%;
                     transform: translate(-50%, -50%);
                     width: fit-content;
                     height: fit-content;">
              <h1 class="login" align="center">
                LedgerSMB {{ version }}
              </h1>
              <div>
                <div id="company_div">
                  <lsmb-text name="login" size="20"
                             id="username" :title="$t('User Name')"
                             tabindex="1"
                             :value="username"
                             v-update:username=""
                             autocomplete="off" />
                  <lsmb-password name="password"
                                 id="password" size="20"
                                 :title="$t('Password')"
                                 :value="password" v-update:password=""
                                 tabindex="2" autocomplete="off" />
                  <lsmb-text name="company"
                             id="company" size="20"
                             :title="$t('Company')" tabindex="3"
                             :value="company"
                             v-update:company="" />
                </div>
                <lsmb-button tabindex="4" id="login" @click="login" :disabled="loginDisabled">{{ $t('Login') }}</lsmb-button>
              </div>
            </div>
          </div>
          <transition>
             <div v-if="inProgress">{{ $t("Logging in... Please wait.") }}</div>
          </transition>
        </div>
      </div>
    </form>
</template>

<script>
/* eslint-disable */
import { defineComponent } from "vue";
import { useI18n } from "vue-i18n";
import { setI18nLanguage } from "@/i18n";

export default defineComponent({
   name: "LoginPage",
   setup() {
      const { t, locale } = useI18n({ useScope: "global" });
      setI18nLanguage(locale);
      return { t };
   },
   data() {
      return {
         version: window.lsmbConfig.version,
         password: "",
         username: "",
         company: "",
         inProgress: false
      };
   },
   computed: {
      loginDisabled() {
         return !this.username || !this.password || !this.company
      }
   },
   methods: {
      async login() {
          this.inProgress = true;
          let r = await fetch("login.pl?action=authenticate&company=" + encodeURI(this.company), {
             method: "POST",
             body: JSON.stringify({
                company: this.company,
                password: this.password,
                login: this.username
             }),
             headers: new Headers({
                "X-Requested-With": "XMLHttpRequest",
                "Content-Type": "application/json"
             })
         });
         if (r.ok) {
            let data = await r.json();
            window.location.href = data.target;
            return;
         }
         if (r.status === 454) {
            alert(this.$t("Company does not exist"));
         } else if (r.status === 401) {
            alert(this.$t("Access denied: Bad username or password"));
         } else if (r.status === 521) {
            alert(this.$t("Database version mismatch"));
         } else {
            alert(this.$t("Unknown error preventing login"));
         }
         this.inProgress = false;
      }
   },
   mounted() {
     document.body.setAttribute("data-lsmb-done", "true");
   }
});
</script>
