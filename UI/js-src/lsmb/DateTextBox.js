/** @format */
/* global lsmbConfig */

define([
    "dijit/form/DateTextBox",
    "dojo/date/locale",
    "dojo/i18n",
    "dojo/on",
    "dojo/_base/declare",
    "dojo/_base/lang",
    "dojo/dom-attr"
], function (DateTextBox, locale, i18n, on, declare, lang, domAttr) {
    var isoDate = /^\d\d\d\d-\d\d-\d\d$/;
    return declare("lsmb/DateTextBox", [DateTextBox], {
        _formattedValue: null,
        _oldValue: "",
        constructor: function (params, srcNodeRef) {
            if (srcNodeRef) {
                this._formattedValue = srcNodeRef.value;
            } else {
                this._formattedValue = "";
            }

            /* Provide default 'old code' doesn't include in its templates */
            if (!params.constraints) {
                params.constraints = {};
            }
            if (!params.constraints.datePattern && lsmbConfig.dateformat) {
                params.constraints.datePattern = lsmbConfig.dateformat.replace(
                    /mm/,
                    "MM"
                );
            }
            if (!params.placeholder && lsmbConfig.dateformat) {
                params.placeholder = lsmbConfig.dateformat;
            }
            // end of 'old code' support block

            /* retrieve format to add it as the placeholder
             * (unless there's a placeholder already) */
            params.constraints.formatLength ||= "short";
            if (!params.placeholder) {
                var l = i18n.normalizeLocale(params.locale);
                var formatLength = params.constraints.formatLength;
                var bundle = locale._getGregorianBundle(l);

                if (params.constraints.selector === "year") {
                    params.placeholder =
                        bundle["dateFormatItem-yyyy"] || "yyyy";
                } else if (params.constraints.selector === "time") {
                    params.placeholder =
                        params.constraints.timePattern ||
                        bundle["timeFormat-" + formatLength];
                } else {
                    params.placeholder =
                        params.constraints.datePattern ||
                        bundle["dateFormat-" + formatLength];
                }
                params.constraints.datePattern = params.placeholder;
                params.placeholder = params.placeholder
                    .replace(/M/g, "m")
                    .replace(/yy?y?y?/g, "yyyy");
            }
        },
        postMixInProperties: function () {
            this.inherited(arguments);
            if (
                this._formattedValue &&
                (!this.value || !isoDate.test(this.value))
            ) {
                /* This code purely compensates for the fact that most
                     LedgerSMB server code sends the date according to the
                     user's selected preference, instead of in ISO format,
                     which the widget expects */
                this.value = this.parse(this._formattedValue, this.constraints);
            }
        },
        startup: function () {
            this.inherited(arguments);

            /* Live insertion of date separators based on the lsmbConfig.Dateformat.
             * The linter rule is disabled to allow assignment within the while() */
            /* eslint no-cond-assign: 0 */
            on(
                this.domNode,
                "keydown",
                lang.hitch(this, function (e) {
                    this._oldValue = domAttr.get(e.target, "value");
                })
            );
            on(
                this.domNode,
                "keyup",
                lang.hitch(this, function (e) {
                    let value = domAttr.get(e.target, "value");

                    if (this._oldValue.length > value.length) {
                        // allow removing characters; separators and others alike
                        return;
                    }
                    /* Extract the separator and location into an array and if
                     * needed add the separator. */
                    const re = /[^a-z]/gi;
                    let position;
                    while (
                        (position = re.exec(lsmbConfig.dateformat)) !== null
                    ) {
                        if (value !== "" && position.index === value.length) {
                            domAttr.set(
                                e.target,
                                "value",
                                (value += position[0])
                            );
                        }
                        // Adjust for finger memory by removing duplicate separators
                        if (
                            value !== "" &&
                            value.endsWith(position[0]) &&
                            value.endsWith(position[0], value.length - 1)
                        ) {
                            domAttr.set(e.target, "value", value.slice(0, -1));
                            break;
                        }
                    }
                })
            );
            // End of code block related to date separation
        },
        parse: function (value) {
            if (!isoDate.test(value)) {
                return this.inherited(arguments);
            }
            return locale.parse(value, {
                datePattern: "yyyy-MM-dd",
                selector: "date"
            });
        }
    });
});
