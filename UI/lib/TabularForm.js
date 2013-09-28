/* lsmb/lib/TabularForm
 * A tabular-form widget for LedgerSMB with some additional features
 * (loosely) inspired by Twitter Bootstrap(TM).
 *
 * Based on dojox/layout/TableContainer
 *
 * This widget is intended to be a generalized tabular data entry form layout
 * system.
 *
 * NODE CLASSES
 *
 * TabularForm supports a number of classes to help manage layouts for different
 * screen sizes.  While this is somewhat inspired by Twitter Bootstrap(TM), the
 * properties assign to the table instead of the grid column.  In other words
 * because this is for data entry forms, we simply manage the form as a whole 
 * and resize accordingly.  This is important because we typically want to 
 * preserve the logical structure of the form when we resize.
 *
 * For columns, we support the following classes.  Each is the number of 
 * columns of inputs supported, so would typically be double (i.e. col-1 is 
 * one column of inputs plus one column of labels).
 *
 * col-1
 * col-2
 * col-3
 * col-4
 *
 * cols can also be passed in via the constructor.
 *
 * For resizing support we support the following:
 *
 * vertsize-small
 * vertsize-med
 * vertsize-mobile
 *
 * mobile = width <= 480px wide
 * small = width 480-768 px wide
 * med = width 768-992px wide
 *
 * This allows generally three modes:
 *
 * 1.  Standard (larger than size), multi-columns supported, labels horizontal
 * 2.  Single column (within size), single columns, label horizontal
 * 3.  Small (smaller than size), single column, labels vertical.
 *
 * Note that for nested TabularForm components, they are resized independently.
 *
 * LAYOUT RULES
 * 
 * 1.  class input_row contains a group of inputs which are rendered together 
 * on one or more rows.  Rows are terminated after an input-row completes.
 * 2.  buttons are contained inside a content pane to suppress labels.
 *
 */

define([
    'dojox/layout/TableContainer',
    'dojo/domClass',
    'dijit/registry',
    'dojo/query',
    'dojo/_base/declare'
    ],
    function(TableContainer, cls, registry, query, declare) {
      return declare('dojox/layout/TableContainer',
        [TableContainer],
        {
        constructor: function (mixIn, domNode){
            
        },
        postCreate: function(){
        },
        resize: function(){
        }
        });
     });

