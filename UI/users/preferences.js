
function change_pw() {
    require(
        ["dojo/request", "dijit/registry"],
        function(r, registry) {
            console.log("change_pw clicked");
        var login = document.getElementById("username").value;
        var old_password = document.prefs.old_password.value;
        var new_password = document.prefs.new_password.value;
        var confirm_pass = document.prefs.confirm_password.value;
        if (old_password != "" && new_password != "" && confirm_pass != "") {
            r("user.pl",
              {
                  "data": {
                      "action": "change_password",
                      "old_password": old_password,
                      "new_password": new_password,
                      "confirm_password": confirm_pass
                  },
                  "method": "POST",
              }).otherwise(function(err) {
                  if (err.response.status != 200){
                      if (err.response.status != "454"){
                          alert("Access Denied:  Bad username/Password ("+res.status+")");
                      } else {
                          alert("Company does not exist.");
                      }
                  }
              });
            }
        });
}

