/** @format */

define([
    "dojo/_base/declare",
    "dojo/on",
    "dojo/_base/lang",
    "dojo/parser",
    "dojo/dom-class",
    "dojo/request/xhr",
    "dijit/_WidgetBase",
    "dijit/_WidgetsInTemplateMixin",
    "dijit/_AttachMixin",
    "dijit/_Container"
], function (
    declare,
    on,
    lang,
    parser,
    domClass,
    xhr,
    _WidgetBase,
    _WidgetsInTemplateMixin,
    _AttachMixin,
    _Container
) {
    return declare(
        "lsmb/TemplateManager",
        [_WidgetBase, _AttachMixin, _WidgetsInTemplateMixin, _Container],
        {
            stopParser: 1,
            state: "",
            restorableContent: "",
            buildRendering: function () {
                this.inherited(arguments);

                parser.parse(this.srcNodeRef);
            },
            __handleBtnClick: function (btn, tgtState) {
                this.own(
                    on(
                        this[btn],
                        "click",
                        lang.hitch(this, function () {
                            if (this.state === "edit" && tgtState !== "edit") {
                                this.templateContent.set(
                                    "value",
                                    this.restorableContent
                                );
                            }
                            this.setState(tgtState);
                        })
                    )
                );
            },
            __handleSelectChange: function (selName) {
                this.own(
                    on(
                        this[selName],
                        "change",
                        lang.hitch(this, function () {
                            this.__syncShadowValues();
                            this.updateButtons();
                        })
                    )
                );
            },
            __syncShadowValues: function () {
                this.shadowFormat.setAttribute(
                    "value",
                    this.templateFormat.value
                );
                this.shadowTemplate.setAttribute(
                    "value",
                    this.templateName.value
                );
                this.shadowLanguage.setAttribute(
                    "value",
                    this.templateLanguage.value
                );
            },
            postCreate: function () {
                this.inherited(arguments);

                this.__syncShadowValues();
                this.setState(this.state);
                this.updateButtons();
                this.__handleBtnClick("createButton", "edit");
                this.__handleBtnClick("editButton", "edit");
                this.__handleBtnClick("uploadButton", "upload");
                this.__handleBtnClick("uploadCancelButton", "view");
                this.__handleBtnClick("editCancelButton", "view");
                this.__handleSelectChange("templateName");
                this.__handleSelectChange("templateFormat");
                this.__handleSelectChange("templateLanguage");
            },
            updateButtons: function () {
                var disabled =
                    this.templateName.value === "" ||
                    this.templateFormat.value === "";

                // how to choose between 'create' and 'edit'?!
                this.createButton.set("disabled", disabled);
                this.editButton.set("disabled", disabled);
                this.uploadButton.set("disabled", disabled);
                if (!disabled) {
                    this.updateTemplate();
                }
            },
            updateTemplate: function () {
                return xhr(
                    "erp/api/v0/templates/" +
                        this.templateName.value +
                        "/" +
                        this.templateFormat.value +
                        "/" +
                        this.templateLanguage.value,
                    { handlesAs: "text" }
                ).then(
                    lang.hitch(this, function (doc) {
                        this.restorableContent = doc;
                        this.templateContent.set("value", doc);
                        this.editButton.set("disabled", false);
                        this.createButton.set("disabled", true);
                        this.setState("view");
                    }),
                    lang.hitch(this, function (err) {
                        if (err.response.status === 404) {
                            this.restorableContent = "";
                            this.editButton.set("disabled", true);
                            this.createButton.set("disabled", false);
                            this.templateContent.set("value", "");
                        }
                    })
                );
            },
            setState: function (newValue) {
                var old = this.state;
                var _newValue = newValue;
                this.state = _newValue;
                domClass.replace(
                    this.srcNodeRef,
                    "state-" + _newValue,
                    "state-" + old
                );
                if (_newValue === "view") {
                    _newValue = "";
                }
                this.templateName.set("disabled", _newValue !== "");
                this.templateFormat.set("disabled", _newValue !== "");
                this.templateLanguage.set("disabled", _newValue !== "");
                this.templateContent.set("readonly", _newValue === "");
            }
        }
    );
});
