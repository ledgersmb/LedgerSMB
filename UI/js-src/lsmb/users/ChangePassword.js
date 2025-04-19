/** @format */
/* eslint-disable camelcase */

define([
    "dojo/_base/declare",
    "dijit/_WidgetBase",
    "dijit/_TemplatedMixin",
    "dijit/_WidgetsInTemplateMixin",
    "dijit/registry",
    "dojo/dom-attr",
    "dojo/on",
    "dojo/text!./templates/PasswordChange.html",
    "dojo/request"
], function (
    declare,
    _widgetbase,
    _templatedMixin,
    _widgetsInTemplateMixin,
    registry,
    domAttr,
    on,
    passwordChange,
    request
) {
    return declare(
        "lsmb/users/ChangePassword",
        [_widgetbase, _templatedMixin, _widgetsInTemplateMixin],
        {
            templateString: passwordChange,
            _lstrings: {
                title: "Change Password",
                "old password": "Old Password",
                "new password": "New Password",
                verify: "Verify",
                change: "Change Password",
                "no-oldpw": "No Old Password",
                strength: "Strength"
            },
            lstrings: {},
            text: function (toTranslate) {
                if (undefined === this.lstrings[toTranslate]) {
                    return toTranslate;
                }
                return this.lstrings[toTranslate];
            },
            startup: function () {
                for (var str in this._lstrings) {
                    if (this.lstrings[str]) {
                        continue;
                    }
                    this.lstrings[str] = this._lstrings[str];
                }
                document.getElementById("pwtitle").innerHTML =
                    this.lstrings.title;
                var I = this;
                on(this.newpw, "change", function () {
                    I.setStrengthClass();
                });
                on(this.newpw, "keyup", function () {
                    I.setStrengthClass();
                });

                domAttr.set(
                    "old-pw-label",
                    "innerHTML",
                    this.text("old password")
                );
                domAttr.set(
                    "new-pw-label",
                    "innerHTML",
                    this.text("new password")
                );
                domAttr.set(
                    "verify-pw-label",
                    "innerHTML",
                    this.text("verify")
                );
                domAttr.set(
                    "pw-strength-label",
                    "innerHTML",
                    this.text("strength")
                );
                registry
                    .byId("pw-change")
                    .set("innerHTML", this.text("change"));
                on(this.submitbutton, "click", function () {
                    I.submitForm();
                });
                this.inherited(arguments);
            },
            scorePassword: function () {
                var pass = this.newpw.get("value");
                var score = 0;
                if (!pass) {
                    return score;
                }
                var letters = {};
                for (var i = 0; i < pass.length; i++) {
                    letters[pass[i]] = (letters[pass[i]] || 0) + 1;
                    score += 5.0 / letters[pass[i]];
                }
                var variations = {
                    digits: /\d/.test(pass),
                    lower: /[a-z]/.test(pass),
                    upper: /[A-Z]/.test(pass),
                    nonWords: /\W/.test(pass)
                };
                var variationCount = 0;
                // eslint-disable-next-line guard-for-in
                for (var check in variations) {
                    variationCount += variations[check] === true ? 1 : 0;
                }
                score += (variationCount - 1) * 10;

                return parseInt(score, 10);
            },
            setStrengthClass: function () {
                var score = this.scorePassword();
                var bgclass = "";
                if (score > 80) {
                    bgclass = "strong";
                } else if (score > 60) {
                    bgclass = "good";
                } else if (score >= 30) {
                    bgclass = "weak";
                }
                domAttr.set("pw-strength", "class", bgclass);
                domAttr.set("pw-strength", "innerHTML", score);
            },
            submitForm: function () {
                var r = request;
                var oldPassword = this.oldpw.get("value");
                var newPassword = this.newpw.get("value");
                var confirmedPassword = this.verified.get("value");
                if (oldPassword === "" || newPassword === "") {
                    this.setFeedback(false, this.text("Password Required"));
                    return;
                }
                if (newPassword !== confirmedPassword) {
                    this.setFeedback(
                        false,
                        this.text("Confirmation did not match")
                    );
                    return;
                }
                r("user.pl", {
                    data: {
                        action: "change_password",
                        old_password: oldPassword,
                        new_password: newPassword,
                        confirm_password: confirmedPassword
                    },
                    method: "POST"
                })
                    .then(() => {
                        this.setFeedback(true, this.text("Password Changed"));
                    })
                    .otherwise((err) => {
                        if (err.response.status !== 200) {
                            if (err.response.status !== 500) {
                                this.setFeedback(
                                    false,
                                    this.text("Bad username/Password")
                                );
                            } else {
                                this.setFeedback(
                                    false,
                                    this.text("Error changing password.")
                                );
                            }
                        }
                    });
            },
            setFeedback: function (success, message) {
                if (success) {
                    this.feedback.set("class", "success");
                } else {
                    this.feedback.set("class", "failure");
                }
                this.feedback.set("innerHTML", message);
            }
        }
    );
});
