# 0113 Changes to outstanding balance of AR/AP items

Date: 2026-09-05

## Status

Draft

## Summary

Describes a design for handling changes to the outstanding balance of
AR/AP items and how to reflect those on the entry screens.

## Context

Traditionally changes to the remaining amount of AR/AP items were
entered as payments. For a long time, overpayments have been "supported",
but reductions of outstanding amounts on AR/AP items originating from
overpayments, were not shown on the entry screen.

The list of changes on the remaining amount includes the following
types (and their reversals):

1. Allocation from a payment (cash transaction)
2. Allocation from an overpayment (available balance, non-cash)
3. Allocation from a voiding invoice to a voided invoice
4. Write-off
5. Free-form outstanding modifications (GL transactions modifying
   the AR/AP open item balance)

The existing UI supports only case (1) where it shows the payment
amount to the current AR/AP item and several payment characteristics:
payment account, source and memo. Each of these are taken from
the payment journal line. Which line is the payment line, is derived
from the account_id stamped into the payment header. There is no
support for cases (2)-(5): recently case (2) was added, but this was
broken again by the payments-as-first-order transactions change.

To add support for cases (2)-(5) on the entry screen, several things
should be noted:

1. There is no transaction support for overpayments, voiding or
   write-off as there is for payments; most importantly, one where
   the counter-account is recorded
2. Overpayments add complexity (over payments) as multiple overpayment
   open items can be used in a single transaction where payments only
   consist of a single journal line on the cash account, prohibiting
   derivation of account, source and memo the same way
3. The entry screen should show exactly for each line what type of change
   to the outstanding amount it is

## Available options

These options were identified:

1. Show the commonality of (1)-(5)
2. Show payment allocations (1) as-is, handle (2)-(5) as option (1)
3. Harmonize payments, overpayments and voids, handle (4) and (5) as option (1)

### Option 1: show the commonality of (1)-(5)

The common fields of (1)-(5) are:

1. Date
2. Type
3. Amount

Optionally, the transaction ID and/or transaction reference could be added.
These fields are (to be made) available on the journal line presented and
its transaction header:

| field  | source                                                    |
|--------|-----------------------------------------------------------|
| Date   | transactions.transdate (Posting Date)                     |
| Type   | transactions.trans_type_code (transaction classification) |
| Amount | acc\_trans.amount\_bc and/or acc\_trans.amount\_tc        |


A variant of this option would allow clicking on the transaction ID to show
the complete ledger transaction in a popup for viewing by the user.

### Option 2: show payment allocation (1) as-is, handle (2)-(5) as option (1)

In this option the 'Type' column would be added to all rows. The rows for
payments would show their current fields (date, source, memo, amount and account)
while the other rows would only show the fields of option 1 (date and amount).

A variant of this option - like option 1 - would allow clicking on a link to
pop up transaction details for viewing.

### Option 3: Harmonize payments, overpayments and voids, handle (4) and (5) as option (1)

In this option the 'Type' column would be added to all rows. The rows for
payments, overpayments and voids would show the fields date, source, memo,
amount and account. The fields would be filled as per the table:

| field   | payment value     | overpayment value   | void value    |
|---------|-------------------|---------------------|---------------|
| Date    | posting date      | posting date        | posting date  |
| Source  | from cash account | (empty)             | (empty)       |
| Memo    | from cash account | from AR/AP account  | (empty)       |
| Account | cash account      | overpayment account | AR/AP account |

This setup requires one restriction: overpayment transactions can affect
a single account only (but could affect multiple overpayment balances
on that single account).

Cases Write-Off (4) and Free-Form change (5) are expected to happen
sporadically. These would show the fields 'Date', 'Type' and 'Amount'
as per option (1).


## Decision


## Consequences


## Annotations

