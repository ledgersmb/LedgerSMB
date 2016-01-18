define([
    'dijit/layout/ContentPane',
    'dojo/_base/declare',
    'dojo/_base/event',
    'dijit/registry',
    'dojo/dom-style',
    'dojo/_base/lang',
    'dojo/promise/Promise',
    'dojo/on',
    'dojo/promise/all',
    'dojo/request/xhr',
    'dojo/query',
    'dojo/dom-class',
    ],
       function(ContentPane, declare, event, registry, style,
                lang, Promise, on, all, xhr, query, domClass) {
           return declare('lsmb/lib/MainContentPane',
                          [ContentPane],
              {
                  last_page: null,
                  set_main_div: function(doc){
                      var self = this;
                      var body = doc.match(/<body[^>]*>([\s\S]*)<\/body>/i);
                      var newbody = body[1];

                      this.destroyDescendants();
                      return this.set('content', newbody)
                          .then(function() {
                              self.show_main_div();
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
                              var d = registry.byId('errorDialog');
                              if (0 == err.response.status) {
                                  d.set('content',
                                        'Could not connect to server');
                              } else {
                                  d.set('content',err.response.data);
                              }
                              d.show();
                          });
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
                      style.set(this.domNode, 'opacity', "30%");
                      domClass.replace(this.domNode, 'parsing', 'done-parsing');
                  },
                  hide_main_div: function() {
                      style.set(this.domNode, 'visibility', 'hidden');
                      domClass.replace(this.domNode, 'done-parsing', 'parsing');
                  },
                  show_main_div: function() {
                      style.set(this.domNode, 'visibility', 'visible');
                  },
                  _patchAtags: function() {
                      var self = this;
                      query('a', self.domNode)
                          .forEach(function (dnode) {
                              if (! dnode.target && dnode.href) {
                                  self.own(on(dnode, 'click',
                                              function(e) {
                                                  event.stop(e);
                                                  self.load_link(dnode.href);
                                              }));
                              }
                          });
                  },
                  set: function() {
                      var newContent = null;
                      var contentOnly = 0;
                      var contentPromise = null;
                      var self = this;

                      if (arguments.length == 1
                          && lang.isObject(arguments[0])
                          && arguments[0]['content'] !== null) {
                          newContent = arguments[0]['content'];
                          delete (arguments[0])['content'];
                      } else if (arguments.length == 1
                                 && lang.isString(arguments[0])) {
                          newContent = arguments[0];
                          contentOnly = true;
                      } else if (arguments.length == 2
                                 && arguments[0] == 'content') {
                          newContent = arguments[1];
                          contentOnly = true;
                      }

                      if (newContent !== null) {
                          contentPromise =
                              this.inherited('set',arguments,
                                             ['content',newContent])
                              .then(function() {
                                  self._patchAtags();
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
