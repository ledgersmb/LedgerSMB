define("lsmb/PrintButton", [
    'dojo/_base/declare',
    'dojo/_base/event',
    'dojo/dom-attr',
    'dijit/form/Button'
],
       function(declare, event, domattr, Button) {
           return declare('lsmb/PrintButton',
                          [Button],
               {
                   onClick: function(evt) {
                       var f; // our form node
                       f = this.valueNode.form;

                       if (f.media.value == 'screen') {
                           var url = domattr.get(f, 'action')
                               + '?action=' + this.valueNode.value
                               + '&id=' + f.id.value
                               + '&vc=' + f.vc.value
                               + '&formname=' + f.formname.value
                               + '&media=screen'
                               + '&format=' + f.format.value;

                           window.location.href = url;
                           event.stop(evt);
                           return;
                       }

                       return this.inherited(arguments);
                   }
               });
       });
