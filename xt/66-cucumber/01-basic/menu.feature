@one-db @weasel @weasel-one-session
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


Scenario Outline: Navigate to menu "<path>" and open screen "<screen>"
   When I navigate the menu and select the item at "<path>"
   Then I should see the <screen> screen

  Examples:
    | path                                       | screen                   |
    | Accounts Payable > Add Transaction                       | AP transaction entry     |
    | Accounts Payable > Debit Invoice                         | AP debit invoice entry   |
    | Accounts Payable > Debit Note                            | AP note entry            |

  @wip
  Examples:
    | path                                       | screen                   |
    | Accounts Payable > Import Batch                          | Batch import             |
    | Accounts Payable > Reports > AP Aging                    |                          |
    | Accounts Payable > Reports > Customer History            |                          |
    | Accounts Payable > Reports > Outstanding                 |                          |
    | Accounts Payable > Reports > Vendor History              |                          |

  Examples:
    | path                                       | screen                   |
    | Accounts Payable > Search                                | AP search                |
    | Accounts Payable > Vendor Invoice                        | AP invoice entry         |

  @wip
  Examples:
    | path                                       | screen                   |
    | Accounts Payable > Vouchers > AP Voucher                 |                          |
    | Accounts Payable > Vouchers > Import AP Batch            |                          |
    | Accounts Payable > Vouchers > Invoice Vouchers           |                          |
    | Accounts Receivable > Add Return                            | AR returns               |

  Examples:
    | path                                       | screen                   |
    | Accounts Receivable > Add Transaction                       | AR transaction entry     |
    | Accounts Receivable > Credit Invoice                        | AR credit invoice entry  |
    | Accounts Receivable > Credit Note                           | AR note entry            |

  @wip
  Examples:
    | path                                       | screen                   |
    | Accounts Receivable > Import Batch                          | Batch import             |
    | Accounts Receivable > Reports > AR Aging                    |                          |
  Examples:
    | path                                       | screen                   |
    | Accounts Receivable > Reports > Customer History            | Purchase History Search  |

  @wip
  Examples:
    | path                                       | screen                   |
    | Accounts Receivable > Reports > Outstanding                 |                          |
  Examples:
    | path                                       | screen                   |
    | Accounts Receivable > Sales Invoice                         | AR invoice entry         |
    | Accounts Receivable > Search                                | AR search                |

  @wip
  Examples:
    | path                                       | screen                   |
    | Accounts Receivable > Vouchers > AR Voucher                 |                          |
    | Accounts Receivable > Vouchers > Import AR Batch            |                          |
    | Accounts Receivable > Vouchers > Invoice Vouchers           |                          |
  Examples:
    | path                                       | screen                   |
    | Budgets > Add Budget                       | Budget                   |
    | Budgets > Search                           | Budget search            |
    | Cash & Banking > Payment                             | Single Payment Vendor Selection   |
    | Cash & Banking > Receipt                             | Single Payment Customer Selection |

  @wip
  Examples:
    | path                                       | screen                   |
    | Cash & Banking > Reconciliation                      |                          |
    | Cash & Banking > Reports                             |                          |
    | Cash & Banking > Reports > Payments                  |                          |
    | Cash & Banking > Reports > Receipts                  |                          |
  Examples:
    | path                                       | screen                   |
    | Cash & Banking > Reports > Reconciliation            | Search Reconciliation Reports |

  @wip
  Examples:
    | path                                       | screen                   |
    | Cash & Banking > Transfer                            |                          |
    | Cash & Banking > Use AR Overpayment                  |                          |
    | Cash & Banking > Use Overpayment                     |                          |
    | Cash & Banking > Vouchers                            |                          |
    | Cash & Banking > Vouchers > Payments                 |                          |
    | Cash & Banking > Vouchers > Receipts                 |                          |
    | Cash & Banking > Vouchers > Reverse AR Overpay       |                          |
    | Cash & Banking > Vouchers > Reverse Overpay          |                          |
    | Cash & Banking > Vouchers > Reverse Payment          |                          |
    | Cash & Banking > Vouchers > Reverse Receipts         |                          |

  Examples:
    | path                                       | screen                   |
    | Contacts > Search                          | Contact Search           |
    | Contacts > Add Entity                      | Edit Contact             |

  Examples:
    | path                                        | screen                   |
    | Fixed Assets > Asset Classes > Add Class    | asset class edit         |
    | Fixed Assets > Asset Classes > List Classes | asset class search       |
    | Fixed Assets > Assets > Add Assets          | asset edit               |

  @wip
  Examples:
    | path                                             | screen |
    | Fixed Assets > Assets > Depreciate          | asset depreciation start |
    | Fixed Assets > Assets > Disposal                 |        |
    | Fixed Assets > Assets > Import                   |        |
    | Fixed Assets > Assets > Reports > Depreciation   |        |
    | Fixed Assets > Assets > Reports > Disposal       |        |
    | Fixed Assets > Assets > Reports > Net Book Value |        |

  Examples:
    | path                                  | screen            |
    | Fixed Assets > Assets > Search Assets | asset search      |
    | General Journal > Chart of Accounts   | Chart of Accounts |

  @wip
  Examples:
    | path                                       | screen                   |
    | General Journal > Import                   |                          |
    | General Journal > Import Chart             |                          |
  Examples:
    | path                              | screen         |
    | General Journal > Journal Entry   | GL entry       |
    | General Journal > Search          | GL search      |
    | Goods & Services > Add Assembly | assembly entry |


  @wip
  Examples:
    | path                                       | screen                   |
    | Goods & Services > Add Group             |                          |
  Examples:
    | path                                       | screen                   |
    | Goods & Services > Add Overhead          | overhead entry           |
    | Goods & Services > Add Part              | part entry               |

  @wip
  Examples:
    | path                                       | screen                   |
    | Goods & Services > Add Pricegroup        |                          |
  Examples:
    | path                                       | screen                   |
    | Goods & Services > Add Service           | service entry            |

  @wip
  Examples:
    | path                                       | screen                   |
    | Goods & Services > Enter Inventory       | Enter Inventory          |
    | Goods & Services > Import > Goods        |                          |
    | Goods & Services > Import > Services     |                          |
    | Goods & Services > Import > Overhead     |                          |
    | Goods & Services > Import > Inventory    |                          |
    | Goods & Services > Reports               |                          |
    | Goods & Services > Reports > Inventory Activity |                   |
    | Goods & Services > Search                | search for goods & services |
    | Goods & Services > Search Groups         |                          |
    | Goods & Services > Search Pricegroups    |                          |
    | Goods & Services > Stock Assembly        |                          |
    | Goods & Services > Translations          |                          |
    | Goods & Services > Translations > Description |                     |
    | Goods & Services > Translations > Partsgroup |                      |
    | HR > Employees > Add Employee              |                          |
  Examples:
    | path                                       | screen                   |
    | HR > Employees > Search                    | Employee Search          |

  @wip
  Examples:
    | path                                       | screen                   |
    | Logout                                     |                          |
    | New Window                                 |                          |
  Examples:
    | path                                       | screen                   |
    | Order Entry > Combine > Purchase Orders    | combine purchase order   |
    | Order Entry > Combine > Sales Orders       | combine sales order      |
    | Order Entry > Generate > Purchase Orders   | generate purchase order  |
    | Order Entry > Generate > Sales Orders      | generate sales order     |
    | Order Entry > Purchase Order               | Purchase order entry     |
    | Order Entry > Reports > Purchase Orders    | Purchase order search    |
    | Order Entry > Reports > Sales Orders       | Sales order search       |
    | Order Entry > Sales Order                  | Sales order entry        |

  @wip
  Examples:
    | path                                       | screen                   |
    | Quotations > Quotation                     |                          |
  Examples:
    | path                                       | screen                   |
    | Preferences                                | Preferences              |
    | Quotations > Reports > Quotations          | Quotation search         |
    | Quotations > Reports > RFQs                | RFQ search               |

  @wip
  Examples:
    | path                                       | screen                   |
    | Quotations > RFQ                           |                          |
    | Recurring Transactions                     |                          |
  Examples:
    | path                                       | screen                   |
    | Reports > Balance Sheet                    | generate balance sheet   |

  @wip
  Examples:
    | path                                       | screen                   |
    | Reports > Income Statement                 |                          |
    | Reports > Inventory and COGS               |                          |
    | Reports > Trial Balance                    |                          |
    | Shipping > Receive                         |                          |
    | Shipping > Ship                            |                          |
    | Shipping > Transfer                        |                          |
  Examples:
    | path                                       | screen                   |
    | System > Currency > Edit currencies        | Edit currencies          |
    | System > Currency > Edit rate types        | Edit rate types          |
    | System > Currency > Edit rates             | Edit rates               |
    | System > Defaults                          | system defaults          |

  @wip
  Examples:
    | path                                       | screen                   |
    | System > GIFI > Add GIFI                   |                          |
    | System > GIFI > Import GIFI                |                          |
    | System > GIFI > List GIFI                  |                          |
  Examples:
    | path                                       | screen                   |
    | System > Templates                         | system templates         |
    | System > Files                             | system files             |

  @wip
  Examples:
    | path                                       | screen                   |
    | System > Language > Add Language           |                          |
    | System > Language > List Languages         |                          |
    | System > Reporting Units                   |                          |
    | System > Sequences                         |                          |
    | System > Sessions                          |                          |
    | System > SIC > Add SIC                     |                          |
    | System > SIC > Import                      |                          |
    | System > SIC > List SIC                    |                          |
  Examples:
    | path                                       | screen                   |
    | System > Taxes                             | system taxes             |

  @wip
  Examples:
    | path                                        | screen                                         |
    | System > Type of Business > Add Business    |                                                |
    | System > Type of Business > List Businesses |                                                |
    | System > Warehouses > Add Warehouse         |                                                |
    | System > Warehouses > List Warehouse        |                                                |
    | Tax Forms > Add Tax Form                    |                                                |
    | Tax Forms > List Tax Forms                  |                                                |
    | Tax Forms > Reports                         |                                                |
    | Timecards > Add Timecard                    |                                                |

  Examples:
    | path                                        | screen                                         |
    | Timecards > Generate > Sales Orders         | timecard order generation                      |

  @wip
  Examples:
    | path                                        | screen                                         |
    | Timecards > Import                          |                                                |
    | Timecards > Search                          |                                                |
    | Timecards > Translations > Description      |                                                |
    | Transaction Approval > Batches              |                                                |
    | Transaction Approval > Drafts               |                                                |
    | Transaction Approval > Inventory            | unapproved inventory adjustments search screen |
    | Transaction Approval > Reconciliation       |                                                |
    | Transaction Templates                       |                                                |
