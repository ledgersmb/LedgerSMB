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

#### Description

The common fields of (1)-(5) are:

1. Date
2. Type
3. Amount

Optionally, the transaction ID and/or transaction reference could be added.
These fields are (to be made) available on the journal line presented and
its transaction header:

| field  | source                                                      |
|--------|-------------------------------------------------------------|
| Date   | `transactions.transdate` (Posting Date)                     |
| Type   | `transactions.trans_type_code` (transaction classification) |
| Amount | `acc_trans.amount_bc` and/or `acc_trans.amount_tc`          |


A variant of this option would allow clicking on the transaction ID to show
the complete ledger transaction in a popup for viewing by the user.

#### Implementation

This option can be implemented without extending the schema or registering
extra information: the information presented is taken from the journal line
and its transaction posted against the open item.

As an addition, each row in the list of allocated amounts
could present a link which pops up all lines of the underlying transaction.
That way, the user can inspect details from payments and/or overpayments from
which the allocation was taken.

#### Pros and cons

Downside to this option is that information from payments entered directly
on the transaction entry screen, will not be presented after the transaction
and its payment are saved (and/or posted).

### Option 2: show payment allocation (1) as-is, handle (2)-(5) as option (1)

#### Description

In this option the 'Type' column would be added to all rows. The rows for
payments would show their current fields (date, source, memo, amount and account)
while the other rows would only show the fields of option 1 (date and amount).

A variant of this option - like option 1 - would allow clicking on a link to
pop up transaction details for viewing.

#### Implementation

This option can be implemented without extending the schema or registering
extra information. This option specializes allocations from payments to show
the allocated amount and the payment details currently shown on transaction
screens (date, source, memo, etc).

Other types of allocations will only show the data as proposed under option (1):
date, amount and type of allocation (overpayment, write-off, etc).

### Option 3: Harmonize payments, overpayments and voids, handle (4) and (5) as option (1)

#### Description

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

#### Implementation

Since allocation to an invoice from overpayment can be done from
multiple overpayments in a single transaction, it is impossible to take
the source, memo and other fields from _the_ overpayment journal line the
same way the existing implementation takes these fields from the payment
journal line.

A different means of establishing the relationship between the invoice
allocation and the source allocated from. This relationship must be
created when an allocation is created from a payment, overpayment or
void. There are two ways to create this relationship:

1. Create an `allocation` table which links the source to the allocation
   linking two journal lines within the same transaction providing a
   specification of the amounts and origins of the allocated amount.  
   In this implementation each source and each allocation have a single
   journal line with the rows in the `allocation` table specifying the
   full cross product of sources and allocations.
2. Cross reference payment allocations against their sources by recording
   an `acc_trans` line for each allocation source per allocation target.  
   In this implementation, the `acc_trans` lines are extended by a column
   which indicates the allocation source `acc_trans` line for the allocation
   line.

Both under option (1) and (2) the journal lines which are cross referenced
are part of the same transaction.

Option (1) produces the minimum number of journal lines required to register
correct accounting while option (2) prevents the addition of a new table at
the expense of generating additional journal lines and an additional column.

The presentation on the invoice can then use the amount from the allocation
`acc_trans` line while using the `source`, `accno` and `memo` values from
the allocation source line.

This scheme can't work for case (5 - manual adjustment/allocation) because
manual transactions wouldn't set up the allocation source reference. For
case (4 - write-off) it wouldn't make sense to report the source, account
and memo since the source (and possibly the memo) would be empty and the
account name would likely mirror the type (including the words "write-off").

## Decision


## Consequences


## Annotations

