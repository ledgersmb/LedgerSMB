define([
    'dijit/form/Form',
    'dojo/_base/declare',
    'dojo/_base/event',
    'dojo/on',
    'dojo/dom-attr',
    'dojo/dom-form',
    'dojo/query',
    'dijit/registry',
    ],
       function(Form, declare, event, on, domattr, domform,
                query, registry) {
           return declare('lsmb/lib/Form',
                          [Form],
              {
                  clickedAction: null,
                  startup: function() {
                      var self = this;
                      this.inherited(arguments);

				          // <button> tags get rewritten to <input type="submit" tags...
				          query('input[type="submit"]', this.domNode)
                          .forEach(function(b) {
					               on(b, 'click', function(){
                                  self.clickedAction = domattr.get(b, 'value');
					               });
				              });

                  },
                  onSubmit: function(evt) {
                      event.stop(evt);
                      this.submit();
                  },
                  submit: function() {
                      if (! this.validate())
                          return;

						    var method = this.method;
						    var qobj = domform.toQuery(this.domNode);
						    qobj = 'action='
							     + this.clickedAction
							     + '&' + qobj;
						    if (undefined == method){
							     method = 'GET';
						    }
						    var url = this.action;

						    var options = { "handleAs": "text" };
						    if ('get' == method.toLowerCase()){
							     url = url + '?' + qobj;
                          registry.byId('maindiv').load_link(url);
						    } else {
							     options['method'] = method;
							     options['data'] = qobj;
						        registry.byId('maindiv').load_form(url, options);
						    }
                  },
              });
       }
    );
