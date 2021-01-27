
# CSV import format documentation

Notes about the format:

 * All CSV files start with the column headings on the first row
 * Column separator is a comma (,)
 * Numbers are parsed using the number format of the importing user(!)  
   **Caveat**: if the importing user uses a comma as the decimal separator,
   a different format has to be selected temporarily during the import

## Chart of Accounts

The import of the chart of accounts should list the folowing columns,
in order:

 * accno  
   The number (field: alphanumeric) by which an account or heading
   is identified.
 * description  
   The text to show for the account. Usually a few words.
 * charttype  
   'A' when the line is an Account, 'H' when the line is a Heading
 * category  
   'L' for liability account, 'Q' for equity account, 'A' for asset account,
   'E' for expense account or 'I' for income account
 * contra  
   '0' for false, '1' for true; indicating that the account is a contra
   account -- i.e. an account offseting another one in its own category.
   An example of a contra account is the 'cumulative depreciation' account
   which offsets the account holding the purchase value of an asset.
 * tax  
   '0' for false, '1' for true; indicating that the account is to be
   associated with a sales tax or VAT rate.
 * link  
   This is a list concatenated values specifying account properties; e.g.
   'AP_paid:AR_paid:IC_taxservice'. The full list of availabe identifiers
   is described in https://book.ledgersmb.org/1.3/split-book/sec-coa-account-configuration.html;
   please note that that section is written with a user looking at the account
   configuration screen (General Journal > Add account) in mind.
 * heading  
   The 'accno' of the heading to be associated with this row; please note
   that accounts *require* headings and headings *may have* a heading of
   their own.
 * gifi_accno  
   Generally not applicable: GIFI is required in Canada. This field can be used
   to associate an alternative account number.

The import is sensitive to the order in which accounts are being imported: each
account must reference a heading and the referenced heading must exist (i.e.
be imported on an earlier import run or on a prior line).

# General Ledger

## Single transaction

## Batch of transactions

This functionality imports a batch of 2-line transaction. Each line in the csv has
the following columns:

 * debit_accno  
   GL account code (accno) associated with the line representing the debit row in the transaction
 * credit_accno  
   GL account code (accno) associated with the line representing the debit row in the transaction
 * amount  
   The (functional currency) amount in the transaction; posted both on the credit and debit side
   of the transaction -- uses the same number format as configured for the uploading user
 * curr  
   The currency code of the transaction; if the transaction is local (functional) currency only,
   set this field to the default currency code (i.e. if the functional currency is USD and the
   transaction is in USD, fill the field with USD)
 * amount_fx  
   The transaction currency amount; if the transaction is functional currency, use the same amount
   as the "amount" column -- uses the same number format as configured for the uploading user
 * reference  
   The reference number to use for the transaction
 * transdate  
   The transaction date to be used, in the same date format as configured in the user-settings of
   the user uploading the file
 * description  
   The description field of the transaction
 * source_debit  
   The value of the "Source" field to be used for the debit row of the transaction
 * source_credit  
   The value of the "Source" field to be used for the credit row of the transaction
 * memo  
   The value of the "Memo" field to be used on the credit and debit rows of the transaction

Uploaded batches can be approved through "Transaction Approval > Batch".

# Parts (Goods & Services)

In LedgerSMB there exist 4 types of "parts":

 1. Goods / Parts
 2. Services
 3. Overhead
 4. Assemblies

At the time of writing (2020-07-29), no import exists for the Bill-of-Materials
part of assemblies. Contact the project through its mailing lists in case you
need it.

The same applies to parts translations: part descriptions which can be used
for international sales.

## Goods & Assemblies

The import of goods (stockable unassembled items) should list the following
columns, in order:

 * partnumber  
   The name of the part used on invoices and for lookup throughout the system
 * description  
   Description of the part to be shown on in conjunction with the partnumber
   e.g. on invoices
 * unit (optional)  
   The unit in which the part is registered. Any alphanumeric sequence allowed,
   however the advice is to keep them short: ea (each; "per 1 unit"), hr (hour),
   kg (kilogram), etc
 * listprice (optional)  
   Informational; not used . Only used to calculate the aggregate list price of assemblies
   when part of a BoM. Intended as listed purchase price, not used to pre-fill
   a vendor invoice.
 * sellprice (optional)  
   Sales price. Used on sales invoices to seed the "Price" column.
 * lastcost (optional)  
   Informational. Price of the last purchase.
 * weight (optional)  
   Informational. Weight of the item.
 * notes (optional)  
   Informational.
 * makemodel  
   @@TODO
 * assembly  
   Indicates whether the item is an assembly. '0' indicates non-assembly part;
   '1' indicates an assembly.
 * alternate  
   Partnumber of a part that may be used instead of this one.
 * rop (optional)  
   Re-order point: number of items below which the item should be re-stocked.
   Can be used to set up an e-mail notification on short parts.
 * inventory_accno  
   Account number on which inventory of the part is to be booked
 * income_accno  
   Account number on which income due to sales of the part is to be booked
 * expense_accno  
   Account number on which expense (cost of goods sold) due to sales of the part
   is to be booked
 * returns_accno  
   @@TODO
 * bin (optional)  
   Warehouse location where the part is stored. Can be any alphanumeric value.
 * bom (optional)  
   @@TODO
 * image (optional)  
   Reference to an external image document
 * drawing (optional)  
   Reference to an external drawing document
 * microfiche (optional)  
   Reference to a microfiche storage
 * partsgroup (optional)  
   Which parts group to assign the part to; leave empty for "none"
 * avgcost (optional)  
   Informational. Average cost of purchase of the part
 * taxaccnos  
   List of ':'-separated GL account numbers (which are associated with a tax rate)
   which are applicable to the part



## Services

Services are non-stockable items. The following columns apply. Documentation
as per the colums documented for Goods.


 * partnumber
 * description
 * unit
 * listprice
 * sellprice
 * lastcost
 * notes
 * income_accno
 * expense_accno
 * partsgroup
 * taxaccnos


## Overhead

Overhead items are non-sellable items. They are intended for inclusion in
the BoM for assemblies. The following columns apply, with documentation as
above.


 * partnumber
 * description
 * unit
 * listprice
 * sellprice
 * lastcost
 * notes
 * inventory_accno
 * expense_accno
 * bom
 * partsgroup

