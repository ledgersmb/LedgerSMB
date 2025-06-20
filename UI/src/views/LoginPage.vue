<script>
import { defineComponent, ref } from "vue";
import { useI18n } from "vue-i18n";
import { setI18nLanguage } from "@/i18n";
import { createLoginMachine } from "./LoginPage.machines.js";

export default defineComponent({
    name: "LoginPage",
    props: ["successFn"],
    setup(props) {
        const { t, locale } = useI18n({ useScope: "global" });
        setI18nLanguage(locale);
        let data = {
            t: t,
            password: ref(""),
            username: ref(""),
            company: ref(""),
            form: ref(null),
            errorText: ref(""),
            successFn: (d) => {
                props.successFn(d);
            },
        };
        let { service, state } = createLoginMachine(data);

        return {
            machine: service,
            version: window.lsmbConfig.version,
            state,
            ...data
        };
    },
    mounted() {
        document.body.setAttribute("data-lsmb-done", "true");
    },
    methods: {
        update(e) {
            this[e.target.name] = e.target.value;
            this.machine.send('input', e);
        }
    }
});
</script>

<template>
    <form ref="form" name="login" style="max-width:fit-content">
      <div id="logindiv">
        <div class="login" align="center">
          <a href="http://www.ledgersmb.org/"
             target="_top">
            <img src="images/ledgersmb.png"
                 class="logo"
                 alt="LedgerSMB Logo" /></a>
          <div id="maindiv">
            <div class="maindivContent">
              <div>
                  <div id="company_div">
                      <lsmb-text id="username"
                                 name="username"
                                 size="20"
                                 :label="$t('User Name')"
                                 :value="username"
                                 tabindex="1"
                                 autocomplete="off"
                                 required
                                 @keyup.enter="machine.send('submit')"
                                 @input="update"
                      />
                      <lsmb-password id="password"
                                     name="password"
                                     size="20"
                                     :label="$t('Password')"
                                     :value="password"
                                     tabindex="2"
                                     autocomplete="off"
                                     required
                                     @keyup.enter="machine.send('submit')"
                                     @input="update"
                      />
                      <lsmb-text id="company"
                                 name="company" size="20"
                                 :label="$t('Company')" tabindex="3"
                                 :value="company"
                                 @keyup.enter="machine.send('submit')"
                                 @input="update"
                      />
                </div>
                <lsmb-button v-if="state !== 'failed'"
                  id="login"
                  tabindex="4"
                  :disabled="state !== 'ready'"
                  @click="machine.send('submit')">
                  {{ $t('Login') }}
                </lsmb-button>
                <div v-else id="errorText" >{{ errorText }}</div>
              </div>
            </div>
          </div>
          <transition>
              <div v-if="state === 'submitting'">{{ $t("Logging in... Please wait.") }}</div>
          </transition>
        </div>
      </div>
    </form>
    <h1 class="login" align="center">
        {{ version }}
    </h1>
</template>

<style scoped>
#maindiv {
  position:relative;
  min-width:max-content;
  height:15em;
}
.maindivContent {
  z-index: 10;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: fit-content;
  height: fit-content;
}
</style>
