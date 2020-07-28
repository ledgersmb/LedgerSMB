
# CSV import format documentation

All CSV files start with the column headings on the first row.

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

