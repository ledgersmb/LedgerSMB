# 0111 Migration of payments and overpayments to open items

Date: 2026-07-31

## Status

Accepted

## Summary

This ADR seeks to disambiguate the terms 'payment' and 'overpayment' and
to detail the related change in semantics of these terms in the application.
The term 'payment' refers both to cash transfers as well as the use to reduce
outstanding invoice amounts.

## Context

### Clarification of terminology

In the current situation, the verb 'to pay' (and the associated noun 'payment')
mean two things:

1. Cash transfer
2. Apply to invoice

This ADR proposes to reduce the meaning of the term 'pay' (and 'payment') to
*only* mean 'cash transfer' and to use the new term 'allocate' (and 'allocation')
to mean 'apply to'.

### Change in semantics

The introduction of open items and the change of payments to first-class
transactions, triggered a change of semantics in payments and overpayments:

* Payments used to be an "annotation" of journal lines across many transactions
  with added logic to derive the actual payment on the cash account
* Overpayments used the same annotation system, but required a GL transaction
  for the initial payment, lacking other transactions to add the journal lines to

After the changes, the semantics change:

* Payments become first-class (cash) transactions with journal lines annotated to
  indicate which invoices they are used to pay
* Overpaymemnts change from being a cash transaction with "use tracking" through
  annotation of journal lines in AR/AP transactions to being created as a consequence
  from a payments transaction.

This change of semantics has two consequences:

1. The term payment no longer designates how a cash transfer is used; it can be
   added to an overpayment balance and/or it can be used with outstanding invoices.
2. Due to (1), overpayments can no longer be used to "pay" invoices; after all,
   there is no cash transfer going on. Under the new semantics an overpayment is
   "allocated" to an invoice.


### Change in transactions

Transaction types differ between the original and the new way of handling
overpayments. In the original model, the use of overpayments was recorded
with journal lines part of an AR or AP transaction (similar to how payments
were recorded on invoices). Creation of an overpayment was recorded using a
GL transaction.

In the new design, creation of an overpayment is triggered by payments, which
are first-class transactions now. The *use* of overpayments can no longer be
recorded as journal lines on AR or AP transactions, because only the opening
position is posted as part of that transaction. All changes to the outstanding
amount are annotationally linked to the initial transaction through open items.
Thus a new type of transaction is required.

At the time of the original (over)payments design there were only three types
of transactions: AR, AP and GL. Since then, a redesign has been done on the
transaction types with a much broader range of transactions supported now,
including Year-end, Fixed Asset and multiple others.

## Decisions

### Terminology

1. The use of payments towards invoice and overpayment balances, will be called
   "allocation" of payments;
2. The use of an overpayment balance towards invoice balances, will be called
   "allocation" of overpayments

### Transaction types

1. Payment transactions create overpayments
2. Overpayment allocation transactions will be a separate transaction type
   used to register overpayment-use

## Consequences

Handling of the change in semantics of both payments and overpayments is a
complex topic and a consequence of the decisions above. Since the introduction
of overpayments-as-open-items and the change of payments to be first-class
transactions are two separate steps, they have their own database schema
migrations. They are however tightly coupled and of sufficient complexity to
warrant detailed description below.

### Table of changes in database schema (by scenario)
The table below describes three situations of the migration:

1. Current: before the introduction of overpayments and payments changes
2. Intermediate: After overpayments and before payments changes
3. Target: after both overpayment and payments changes

#### Column descriptions

Grouping
: Grouping of transactions; 'Single' for ungrouped transactions. 'Batch' for grouped

Phase
: Which part of the lifecycle the transaction is in; either 'Initial' or 'Reversed'

Concept
: Which aspect the transaction cover (in "current" terminology)

\#
: Number of the row in the table; for referencing

Current
: Column group describing the state of the application pre-migration

Intermediate
: Column group describing the state of the application post-overpayment-migration, but pre-payment-migration

Target
: Column group describing the state of the application after both migrations

Type (of concept)
: Type of business event; "Payment", "Overpayment creation" or "Overpayment use"

Impact (of concept)
: Impact of business event; "Cash", "Invoice" or "Balance" (of overpayment)

Transaction
: Classification of the transaction as recorded in the system; "AR", "AP", "GL", "Payment" or "Overpayment Use"

Balance tracking
: Tracking of the balance of e.g., an overpayment or invoice

Cross transaction tracking
: When journal lines span multiple transactions, indicates which table (concept) is used to track which lines belong together


#### Migration impact table

<table>
    <thead>
        <tr>
            <th rowspan="2" colspan="1">Grouping</th>
            <th rowspan="2" colspan="1">Phase</th>
            <th rowspan="1" colspan="2">Concept</th>
            <th rowspan="2" colspan="1">#</th>
            <th colspan="3">Current</th>
            <th colspan="3">Intermediate</th>
            <th colspan="3">Target</th>
            <th rowspan="2">Notes</th>
        </tr>
        <tr>
            <th>Type</th>
            <th>Impact</th>
            <th>Transaction</th>
            <th>Balance tracking</th>
            <th>Cross transaction tracking</th>
            <th>Transaction</th>
            <th>Balance tracking</th>
            <th>Cross transaction tracking</th>
            <th>Transaction</th>
            <th>Balance tracking</th>
            <th>Cross transaction tracking</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th rowspan="12">Single</th>
            <th rowspan="6">Initial</th>
            <th rowspan="2">Payment</th>
            <th>Cash</th>
            <td>1</td>
            <td rowspan="2">AR/AP</td>
            <td>payment links on cash account</td>
            <td rowspan="2">Payment</td>
            <td rowspan="2">AR/AP</td>
            <td>payment links on cash account</td>
            <td rowspan="2">Payment</td>
            <td rowspan="2"><s>AR/AP</s><br><mark>Payment</mark></td>
            <td><s>payment links on cash account</s><br><mark>&mdash;</mark></td>
            <td rowspan="2"><s>Payment</s><br><mark>N/A</mark><span title="Not applicable: journal lines within the transaction record allocation to invoices">*</span></td>
            <td rowspan="2">If a payment involves both allocation to invoices *and* allocation to overpayment, the AR/AP lines must be merged into the existing overpayment (GL) transaction in the payments migration</td>
        </tr>
        <tr>
            <th>Invoice</th>
            <td>2</td>
            <td>AR/AP open item</td>
            <td>AR/AP open item</td>
            <td>AR/AP open item</td>
        </tr>
        <tr>
            <th rowspan="2">Overpayment create</th>
            <th>Cash</th>
            <td>3</td>
            <td rowspan="2">GL</td>
            <td>&mdash;</td>
            <td rowspan="2">&mdash;</td>
            <td rowspan="2">GL</td>
            <td>&mdash;</td>
            <td rowspan="2">&mdash;</td>
            <td rowspan="2"><s>GL</s><br><mark>Payment</mark></td>
            <td>&mdash;</td>
            <td rowspan="2">&mdash;</td>
            <td rowspan="2">Granularity: one open item per overpayment account per overpayment, due to back-reference in overpayment-use.</td>
        </tr>
        <tr>
            <th>Balance</th>
            <td>4</td>
            <td>Payment</td>
            <td>Payment <mark>&amp; Overpayment open item<span title="open item creation skipped for accounts not marked as AR_overpayment/AP_overpayment">*</span></mark> </td>
            <td><s>Payment &amp;</s> Overpayment open item</td>
        </tr>
        <tr>
            <th rowspan="2">Overpayment use</th>
            <th>Balance</th>
            <td>5</td>
            <td rowspan="2">AR/AP</td>
            <td>Payment</td>
            <td rowspan="2">Payment</td>
            <td rowspan="2"><s>AR/AP</s><br><mark>Overpayment Use</mark></td>
            <td><s>Payment</s><br><mark>Overpayment open item<span title="open item creation skipped for accounts not marked as AR_overpayment/AP_overpayment">*</span></mark></td>
            <td rowspan="2"><s>Payment</s><br><mark>N/A</mark><span title="Not applicable: journal lines within the transaction record allocation to invoices">*</span></td>
            <td rowspan="2">New Overpayment Use</td>
            <td>Overpayment open item</td>
            <td rowspan="2">N/A<span title="Not applicable: journal lines within the transaction record allocation to invoices">*</span></td>
            <td rowspan="2">Payment links type==0 point to the original overpayment. Combining with the current journal line's account, this limits granularity to one per account per overpayment.</td>
        </tr>
        <tr>
            <th>Invoice</th>
            <td>6</td>
            <td>AR/AP open item </td>
            <td>AR/AP open item</td>
            <td>AR/AP open item</td>
        </tr>
        <tr>
            <th rowspan="6">Reverse</th>
            <th rowspan="2">Payment<span title="Payment reversals only exist as vouchers (batches); this line applies to 'vouchers for single payments'">*</span></th>
            <th>Cash</th>
            <td>7</td>
            <td rowspan="2">AR/AP<span title="Not applicable: journal lines linked to vouchers &amp; batches of types 4 or 7">*</span></td>
            <td>payment links on cash account</td>
            <td rowspan="2">Payment</td>
            <td rowspan="2">AR/AP<span title="Not applicable: journal lines linked to vouchers of types 4 or 7">*</span>?</td>
            <td>payment links on cash account</td>
            <td rowspan="2">Payment</td>
            <td rowspan="2"><s>AR/AP*?</s><br><mark>Payment</mark></td>
            <td rowspan="1"><s>payment links on cash account</s><br><mark>&mdash;</mark></td>
            <td rowspan="2"><s>Payment</s><br><mark>N/A</mark><span title="Not applicable: journal lines within the transaction record allocation to invoices">*</span></td>
            <td rowspan="2"><!-- notes --></td>
        </tr>
        <tr>
            <th>Invoice</th>
            <td>8</td>
            <td>AR/AP open item</td>
            <td>AR/AP open item</td>
            <td>AR/AP open item</td>
        </tr>
        <tr>
            <th rowspan="2">Overpayment create</th>
            <th>Cash</th>
            <td>9</td>
            <td rowspan="2">GL<span title="voucher of type 4 or 7 with trans_id matching the GL record&apos;s id">*</span></td>
            <td>&mdash;</td>
            <td rowspan="2">&mdash;</td>
            <td rowspan="2">GL<span title="voucher of type 4 or 7 with trans_id matching the GL record&apos;s id">*</span></td>
            <td>&mdash;</td>
            <td rowspan="2">&mdash;</td>
            <td rowspan="2"><s>GL*</s><br><mark>Payment</mark></td>
            <td>&mdash;</td>
            <td rowspan="2">&mdash;</td>
            <td rowspan="2"><!-- notes --></td>
        </tr>
        <tr>
            <th>Balance</th>
            <td>10</td>
            <td><span title="This case does not have payment_links inserted, which breaks marking the original as used.">(broken)</span></td>
            <td>(broken) <mark>&amp; Overpayment open item<span title="open item creation skipped for accounts not marked as AR_overpayment/AP_overpayment">*</span></mark></td>
            <td><s>(broken) &amp;</s> Overpayment open item</td>
        </tr>
        <tr>
            <th rowspan="2">Overpayment use</th>
            <th>Balance</th>
            <td>11</td>
            <td rowspan="2" colspan="9">Not implemented</td>
            <td rowspan="2"><!-- notes --></td>
        </tr>
        <tr>
            <th>Invoice</th>
            <td>12</td>
        </tr>
        <tr>
            <th rowspan="12">Batch</th>
            <th rowspan="6">Initial</th>
            <th rowspan="2">Payment</th>
            <th>Cash</th>
            <td>13</td>
            <td rowspan="2">AR/AP</td>
            <td>Voucher on cash account</td>
            <td rowspan="2">Voucher (&amp; Payment, since 1.8)</td>
            <td rowspan="2">AR/AP</td>
            <td>Voucher on cash account</td>
            <td rowspan="2">Voucher (&amp; Payment, since 1.8)</td>
            <td rowspan="2"><s>AR/AP</s><br><mark>Payment</mark></td>
            <td><s>Voucher on cash account</s><br><mark>&mdash;</mark></td>
            <td rowspan="2"><s>Voucher (&amp; Payment, since 1.8)</s><br><mark>N/A</mark><span title="Not applicable: journal lines within the transaction record allocation to invoices">*</span></td>
            <td rowspan="2">Target: batches are collections of transactions; no vouchers</td>
        </tr>
        <tr>
            <th>Invoice</th>
            <td>14</td>
            <td>AR/AP open item </td>
            <td>AR/AP open item</td>
            <td>AR/AP open item</td>
        </tr>
        <tr>
            <th rowspan="2">Overpayment create</th>
            <th>Cash</th>
            <td>15</td>
            <td rowspan="2" colspan="9">Not implemented</td>
            <td rowspan="2"><!-- notes --></td>
        </tr>
        <tr>
            <th>Balance</th>
            <td>16</td>
        </tr>
        <tr>
            <th rowspan="2">Overpayment use</th>
            <th>Balance</th>
            <td>17</td>
            <td rowspan="2" colspan="9">Not implemented</td>
            <td rowspan="2"><!-- notes --></td>
        </tr>
        <tr>
            <th>Invoice</th>
            <td>18</td>
        </tr>
        <tr>
            <th rowspan="6">Reverse</th>
            <th rowspan="2">Payment</th>
            <th>Cash</th>
            <td>19</td>
            <td rowspan="2">AR/AP<span title="Not applicable: journal lines linked to vouchers of types 4 or 7">*</span>?</td>
            <td>payment links on cash account</td>
            <td rowspan="2">Payment</td>
            <td rowspan="2">AR/AP<span title="Not applicable: journal lines linked to vouchers of types 4 or 7">*</span>?</td>
            <td>payment links on cash account</td>
            <td rowspan="2">Payment</td>
            <td rowspan="2"><s>AR/AP*?</s><br><mark>Payment</mark></td>
            <td rowspan="1"><s>payment links on cash account</s><br><mark>&mdash;</mark></td>
            <td rowspan="2"><s>Payment</s><br><mark>N/A</mark><span title="Not applicable: journal lines within the transaction record allocation to invoices">*</span></td>
            <td rowspan="2"><!-- notes --></td>
        </tr>
        <tr>
            <th>Invoice</th>
            <td>20</td>
            <td>AR/AP open item </td>
            <td>AR/AP open item</td>
            <td>AR/AP open item</td>
        </tr>
        <tr>
            <th rowspan="2">Overpayment create</th>
            <th>Cash</th>
            <td>21</td>
            <td rowspan="2" colspan="9">Not implemented</td>
            <td rowspan="2"><!-- notes --></td>
        </tr>
        <tr>
            <th>Balance</th>
            <td>22</td>
        </tr>
        <tr>
            <th rowspan="2">Overpayment use</th>
            <th>Balance</th>
            <td>23</td>
            <td rowspan="2" colspan="9">Not implemented</td>
            <td rowspan="2"><!-- notes --></td>
        </tr>
        <tr>
            <th>Invoice</th>
            <td>24</td>
        </tr>
    </tbody>
</table>

\* Hover the asterisk for details (depends on your Markdown renderer)

Yellow highlighting may be available to show items added since the previous state (depends on your Markdown renderer)

## Annotations

