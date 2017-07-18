@one-db @weasel
Feature: correct operation of the menu and immediate linked pages
  As an end-user, I want to be able to navigate the menu and open
  the screens from the available links. If my authorizations
  don't allow a specific screen, I expect the links not to be in
  the menu.



Background:
  Given a standard test company
  Given a logged in admin


#Scenario Outline: Navigate to menu and open tab
#   When I navigate the menu and select the item at "<path>"
#   And I select the "<tab>" tab
#   Then I should see the <screen> tab
#  Examples:
#    | path                                      | screen                   | tab           |
#    | Contacts > Add Contact                    | contact creation         | Company       |
##    | Contacts > Add Contact                    | contact creation         | Person        |
##    | General Journal > Year End                | year-end                 | Close Year    |
##    | General Journal > Year End                | year-end                 | Close Period  |
##    | General Journal > Year End                | year-end                 | Ro-open Books |


Scenario Outline: Navigate to menu and open screen
   When I navigate the menu and select the item at "<path>"
   Then I should see the <screen> screen
  Examples:
    | path                                       | screen                   |
    | AP > Add Transaction                       | AP transaction entry     |
    | AP > Debit Invoice                         | AP debit invoice entry   |
    | AP > Debit Note                            | AP note entry            |
    | AP > Import Batch                          | Batch import             |
#   | AP > Reports > AP Aging                    |                          |
#   | AP > Reports > Customer History            |                          |
#   | AP > Reports > Outstanding                 |                          |
#   | AP > Reports > Vendor History              |                          |
    | AP > Search                                | AP search                |
    | AP > Vendor Invoice                        | AP invoice entry         |
#   | AP > Vouchers > AP Voucher                 |                          |
#   | AP > Vouchers > Import AP Batch            |                          |
#   | AP > Vouchers > Invoice Vouchers           |                          |
#   | AR > Add Return                            | AR returns               |
    | AR > Add Transaction                       | AR transaction entry     |
    | AR > Credit Invoice                        | AR credit invoice entry  |
    | AR > Credit Note                           | AR note entry            |
    | AR > Import Batch                          | Batch import             |
#   | AR > Reports > AR Aging                    |                          |
#   | AR > Reports > Customer History            |                          |
#   | AR > Reports > Outstanding                 |                          |
    | AR > Sales Invoice                         | AR invoice entry         |
    | AR > Search                                | AR search                |
#   | AR > Vouchers > AR Voucher                 |                          |
#   | AR > Vouchers > Import AR Batch            |                          |
#   | AR > Vouchers > Invoice Vouchers           |                          |
#   | Budgets > Add Budget                       |                          |
    | Budgets > Search                           | Budget search            |
#   | Cash > Payment                             |                          |
#   | Cash > Receipt                             |                          |
#   | Cash > Reconciliation                      |                          |
#   | Cash > Reports                             |                          |
#   | Cash > Reports > Payments                  |                          |
#   | Cash > Reports > Receipts                  |                          |
#   | Cash > Reports > Reconciliation            |                          |
#   | Cash > Transfer                            |                          |
#   | Cash > Use AR Overpayment                  |                          |
#   | Cash > Use Overpayment                     |                          |
#   | Cash > Vouchers                            |                          |
#   | Cash > Vouchers > Payments                 |                          |
#   | Cash > Vouchers > Receipts                 |                          |
#   | Cash > Vouchers > Reverse AR Overpay       |                          |
#   | Cash > Vouchers > Reverse Overpay          |                          |
#   | Cash > Vouchers > Reverse Payment          |                          |
#   | Cash > Vouchers > Reverse Receipts         |                          |
    | Contacts > Search                          | Contact search           |
#   | Fixed Assets > Asset Classes               |                          |
#   | Fixed Assets > Asset Classes > Add Class   |                          |
#   | Fixed Assets > Asset Classes > List Classes|                          |
#   | Fixed Assets > Assets                      |                          |
#   | Fixed Assets > Assets > Add Assets         |                          |
#   | Fixed Assets > Assets > Depreciate         |                          |
#   | Fixed Assets > Assets > Disposal           |                          |
#   | Fixed Assets > Assets > Import             |                          |
#   | Fixed Assets > Assets > Reports            |                          |
#   | Fixed Assets > Assets > Reports > Depreciation |                      |
#   | Fixed Assets > Assets > Reports > Disposal |                          |
#   | Fixed Assets > Assets > Reports > Net Book Value |                    |
#   | Fixed Assets > Assets > Search Assets      |                          |
#   | General Journal > Add Accounts             |                          |
#   | General Journal > Chart of Accounts        |                          |
#   | General Journal > Import                   |                          |
#   | General Journal > Import Chart             |                          |
#   | General Journal > Journal Entry            |                          |
    | General Journal > Search and GL            | GL search                |
    | Goods and Services > Add Assembly          | assembly entry           |
#   | Goods and Services > Add Group             |                          |
    | Goods and Services > Add Overhead          | overhead entry           |
    | Goods and Services > Add Part              | part entry               |
#   | Goods and Services > Add Pricegroup        |                          |
    | Goods and Services > Add Service           | service entry            |
#   | Goods and Services > Enter Inventory       | Enter Inventory          |
#   | Goods and Services > Import Inventory      |                          |
#   | Goods and Services > Reports               |                          |
#   | Goods and Services > Reports > Inventory Activity |                   |
#   | Goods and Services > Search                | search for goods & services |
#   | Goods and Services > Search Groups         |                          |
#   | Goods and Services > Search Pricegroups    |                          |
#   | Goods and Services > Stock Assembly        |                          |
#   | Goods and Services > Translations          |                          |
#   | Goods and Services > Translations > Description |                     |
#   | Goods and Services > Translations > Partsgroup |                      |
#   | HR > Employees > Add Employee              |                          |
    | HR > Employees > Search                    | Employee search          |
#   | Logout                                     |                          |
#   | New Window                                 |                          |
    | Order Entry > Combine > Purchase Orders    | combine purchase order   |
    | Order Entry > Combine > Sales Orders       | combine sales order      |
    | Order Entry > Generate > Purchase Orders   | generate purchase order  |
    | Order Entry > Generate > Sales Orders      | generate sales order     |
    | Order Entry > Purchase Order               | Purchase order entry     |
    | Order Entry > Reports > Purchase Orders    | Purchase order search    |
    | Order Entry > Reports > Sales Orders       | Sales order search       |
    | Order Entry > Sales Order                  | Sales order entry        |
#   | Preferences                                |                          |
#   | Quotations > Quotation                     |                          |
    | Quotations > Reports > Quotations          | Quotation search         |
    | Quotations > Reports > RFQs                | RFQ search               |
#   | Quotations > RFQ                           |                          |
#   | Recurring Transactions                     |                          |
    | Reports > Balance Sheet                    | generate balance sheet   |
#   | Reports > Income Statement                 |                          |
#   | Reports > Inventory and COGS               |                          |
#   | Reports > Trial Balance                    |                          |
#   | Shipping > Receive                         |                          |
#   | Shipping > Ship                            |                          |
#   | Shipping > Transfer                        |                          |
    | System > Defaults                          | system defaults          |
#   | System > GIFI > Add GIFI                   |                          |
#   | System > GIFI > Import GIFI                |                          |
#   | System > GIFI > List GIFI                  |                          |
#   | System > HTML Templates > Invoicing > AP Transaction |                |
#   | System > HTML Templates > Invoicing > AR Transaction |                |
#   | System > HTML Templates > Invoicing > Invoice |                       |
#   | System > HTML Templates > Invoicing > Product Receipt |               |
#   | System > HTML Templates > Invoicing > Statement |                     |
#   | System > HTML Templates > Ordering > Purchase Order |                 |
#   | System > HTML Templates > Ordering > Quotation |                      |
#   | System > HTML Templates > Ordering > RFQ   |                          |
#   | System > HTML Templates > Ordering > Sales Order |                    |
#   | System > HTML Templates > Ordering > Work Order |                     |
#   | System > HTML Templates > Other > Letterhead |                        |
#   | System > HTML Templates > Other > Payment  |                          |
#   | System > HTML Templates > Other > Timecard |                          |
#   | System > HTML Templates > Shipping > Bin List |                       |
#   | System > HTML Templates > Shipping > Packing List |                   |
#   | System > HTML Templates > Shipping > Pick List |                      |
#   | System > Language > Add Language           |                          |
#   | System > Language > List Languages         |                          |
#   | System > LaTeX Templates > Invoicing > AP Transaction |               |
#   | System > LaTeX Templates > Invoicing > AR Transaction |               |
#   | System > LaTeX Templates > Invoicing > Invoice |                      |
#   | System > LaTeX Templates > Invoicing > Product Receipt |              |
#   | System > LaTeX Templates > Invoicing > Statement |                    |
#   | System > LaTeX Templates > Ordering > Purchase Order |                |
#   | System > LaTeX Templates > Ordering > Quotation |                     |
#   | System > LaTeX Templates > Ordering > RFQ  |                          |
#   | System > LaTeX Templates > Ordering > Sales Order |                   |
#   | System > LaTeX Templates > Ordering > Work Order |                    |
#   | System > LaTeX Templates > Other > Check   |                          |
#   | System > LaTeX Templates > Other > Check Base |                       |
#   | System > LaTeX Templates > Other > Letterhead |                       |
#   | System > LaTeX Templates > Other > Multiple Checks |                  |
#   | System > LaTeX Templates > Other > Receipt |                          |
#   | System > LaTeX Templates > Other > Timecard |                         |
#   | System > LaTeX Templates > Shipping > Bin List |                      |
#   | System > LaTeX Templates > Shipping > Envelope |                      |
#   | System > LaTeX Templates > Shipping > Packing List |                  |
#   | System > LaTeX Templates > Shipping > Pick List |                     |
#   | System > LaTeX Templates > Shipping > Shipping Label |                |
#   | System > Reporting Units                   |                          |
#   | System > Sequences                         |                          |
#   | System > Sessions                          |                          |
#   | System > SIC > Add SIC                     |                          |
#   | System > SIC > Import                      |                          |
#   | System > SIC > List SIC                    |                          |
    | System > Taxes                             | system taxes             |
#   | System > Type of Business > Add Business   |                          |
#   | System > Type of Business > List Businesses|                          |
#   | System > Warehouses > Add Warehouse        |                          |
#   | System > Warehouses > List Warehouse       |                          |
#   | Tax Forms > Add Tax Form                   |                          |
#   | Tax Forms > List Tax Forms                 |                          |
#   | Tax Forms > Reports                        |                          |
#   | Timecards > Add Timecard                   |                          |
#   | Timecards > Generate > Sales Orders        |                          |
#   | Timecards > Import                         |                          |
#   | Timecards > Search                         |                          |
#   | Timecards > Translations > Description     |                          |
#   | Transaction Approval > Batches             |                          |
#   | Transaction Approval > Drafts              |                          |
#   | Transaction Approval > Inventory           | unapproved inventory adjustments search screen |
#   | Transaction Approval > Reconciliation      |                          |
#   | Transaction Templates                      |                          |
