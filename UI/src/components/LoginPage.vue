<template>
    <form name="login">
      <div class="login" id="logindiv">
        <div class="login" align="center">
          <a href="http://www.ledgersmb.org/"
             target="_top">
            <img src="images/ledgersmb.png"
                 class="logo"
                 alt="LedgerSMB Logo" /></a>
          <div id="maindiv" style="position:relative; width:100%; height:15em;">

            <div style="z-index:10; position:absolute; top:0; left:0; width:100%; height:100%;">
              <h1 class="login" align="center">
                LedgerSMB {{ version }}
              </h1>
              <div>
                <div id="company_div">
                  <lsmb-text type="text" name="login" size="20"
                             id="username" title="User Name"
                             tabindex="1"
                             :value="username"
                             v-update:username=""
                             autocomplete="off" />
                  <lsmb-password type="password" name="password"
                                 id="password" size="20"
                                 title="Password"
                                 :value="password" v-update:password=""
                                 tabindex="2" autocomplete="off" />
                  <lsmb-text type="text" name="company" size="20"
                             title="Company" tabindex="3"
                             :value="company"
                             v-update:company="" />
                </div>
                <lsmb-button tabindex="4" id="login" :disabled="password===''" @click="login">Login</lsmb-button>
              </div>
            </div>
          </div>
          <div v-show="inProgress">
             Logging in... Please wait.
          </div>
        </div>
      </div>
    </form>
</template>

<script>

export default {
   data() {
      return {
         version: window.lsmbConfig.version,
         password: "",
         username: "",
         company: "",
         inProgress: false
      };
   },
   methods: {
      async login() {
          let headers = new Headers();
          headers.set("X-Requested-With", "XMLHttpRequest");
          headers.set("Content-Type", "application/json");
          this.inProgress = true;
          let r = await fetch("login.pl?action=authenticate&company=" + encodeURI(this.company), {
             method: "POST",
             body: JSON.stringify({
                company: this.company,
                password: this.password,
                login: this.username
             }),
             headers: headers
         });
         if (r.ok) {
            let data = await r.json();
            window.location.href = data.target;
            return;
         } else if (r.status === 454) {
            alert("Company does not exist");
         } else if (r.status === 401) {
            alert("Access denied: Bad username or password");
         } else if (r.status === 521) {
            alert("Database version mismatch");
         } else {
            alert("Unknown error preventing login");
         }
         this.inProgress = false;
      }
   },
   mounted() {
     document.body.setAttribute("data-lsmb-done", "true");
   }
}
</script>
