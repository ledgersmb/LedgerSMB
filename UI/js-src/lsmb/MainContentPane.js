define([
    "dijit/layout/ContentPane",
    "dojo/_base/declare",
    "dojo/_base/event",
    "dijit/registry",
    "dojo/dom-style",
    "dojo/_base/lang",
    "dojo/promise/Promise",
    "dojo/on",
    "dojo/hash",
    "dojo/promise/all",
    "dojo/request/xhr",
    "dojo/query",
    "dojo/request/iframe",
    "dojo/dom-class"
    ],
       function(ContentPane, declare, event, registry, style,
                lang, Promise, on, hash, all, xhr, query, iframe,
                domClass) {
           return declare("lsmb/MainContentPane",
                          [ContentPane],
              {
                  last_page: null,
                  interceptClick: null,
                  report_request_error: function(err) {
                      var d = registry.byId("errorDialog");
                      if (0 === err.response.status) {
                          d.set("content",
                                "Could not connect to server");
                      } else {
                          d.set("content",err.response.data);
                      }
                      d.show();
                  },
                  report_error: function(content) {
                      var d = registry.byId("errorDialog");
                      d.set("content", content);
                      d.show();
                  },
                  set_main_div: function(doc){
                      var self = this;
                      var body = doc.match(/<body[^>]*>([\s\S]*)(<\/body>)?/i);

                      if (! body) {
                          this.report_error("Invalid server response: document lacks BODY tag");
                          return;
                      }
                      var newbody = body ? body[1] : "";
                      return this.set("content", newbody)
                          .then(
                              function() {
                                  self.show_main_div();
                              },
                              function() {
                                  self.report_error("Server return value invalid");
                              });
                  },
                  load_form: function(url, options) {
                      var self = this;
                      self.fade_main_div();
                      return xhr(url, options).then(
                          function(doc){
                              self.hide_main_div();
                              self.set_main_div(doc);
                          },
                          function(err){
                              self.show_main_div();
                              self.report_request_error(err);
                          });
                  },
                  download_link: function(href) {
                      // while it would have been nice for the code below
                      // to work, content downloaded into the iframe through
                      // dojo/request/iframe breaks all but the first request
                      // supposedly because the response never causes the
                      // 'onload' event to fire -- as the content isn't really
                      // loaded...

                      // var self = this;
                      // var deferred = iframe.get(href, { });
                      // iframe.doc();
                      // return deferred .then(
                      //     function() {
                      //         // we never reach success???
                      //     }, function(err) {
                      //         self.report_request_error(err);
                      //     });
                  },
                  load_link: function(href) {
                      if (this.last_page == href) {
                          return;
                      }
                      this.last_page = href;
                      return this.load_form(href,{"handlesAs": "text"});
                  },
                  fade_main_div: function() {
                      // mention we're processing the request
                      domClass.replace(this.domNode, "parsing", "done-parsing");
                      style.set(this.domNode, "opacity", "0.3");
                  },
                  hide_main_div: function() {
                      style.set(this.domNode, "visibility", "hidden");
                  },
                  show_main_div: function() {
                      style.set(this.domNode, "visibility", "visible");
                      style.set(this.domNode, "opacity", "1");
                      domClass.replace(this.domNode, "done-parsing", "parsing");
                  },
                  set: function() {
                      var newContent = null;
                      var contentOnly = 0;
                      var contentPromise = null;
                      var self = this;

                      if (arguments.length === 1
                          && lang.isObject(arguments[0])
                          && arguments[0]["content"] !== null) {
                          newContent = arguments[0]["content"];
                          delete (arguments[0])["content"];
                      } else if (arguments.length === 1
                                 && lang.isString(arguments[0])) {
                          newContent = arguments[0];
                          contentOnly = true;
                      } else if (arguments.length === 2
                                 && arguments[0] == "content") {
                          newContent = arguments[1];
                          contentOnly = true;
                      }

                      if (newContent !== null) {
                          contentPromise =
                              this.inherited("set",arguments,
                                             ["content",newContent])
                              .then(function() {
                                  query("a", self.domNode)
                                      .forEach(self.interceptClick);
                                  self.show_main_div();
                              });
                      }

                      if (contentOnly) {
                          return contentPromise;
                      }

                      var setPromise = this.inherited(arguments);
                      if (contentPromise !== null
                          && contentPromise instanceof Promise
                          && setPromise !== null
                          && setPromise instanceof Promise) {
                          return all([contentPromise, setPromise]);
                      } else if (contentPromise !== null
                                 && contentPromise instanceof Promise) {
                          return contentPromise;
                      } else {
                          return setPromise;
                      }
                  }
              });
       });
