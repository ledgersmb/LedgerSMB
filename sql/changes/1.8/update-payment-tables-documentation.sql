
COMMENT ON TABLE payment IS
$$ This table tracks header data for payments.

Its purpose is to maintain references to a gl transaction (overpayments)
and purchase/sales orders (prepayments).

Together with the payment_links table, it assembles data spread across multiple
transactions into a single payment for reconciliation purposes.

This table exists to record as a single payment 'acc_trans' lines spread over
multiple AR/AP transactions: payment lines use the same 'trans_id' as the
AR/AP item which they are payments to. This means that there is a need for
a secondary table to track the various parts of a payment. E.g. when a 30USD
payment is entered for 2 invoices (INV1 @ 10USD, INV2 @ 20USD), one might
expect it to be recorded as

  +----------+--------+-------+---------+------+
  | trans_id | amount | DB/CR | account | ref  |
  +----------+--------+-------+---------+------+
  |  25      |  30.00 | DB    | Bank    |      |
  |  25      |  10.00 | CR    | AR      | INV1 |
  |  25      |  20.00 | CR    | AR      | INV2 |
  +----------+--------+-------+---------+------+

However, the payment is actually recorded in the 'acc_trans' table  as
below (assuming INV1 has trans_id 1 and INV2 has trans_id 2):

  +----------+--------+-------+---------+------+
  | trans_id | amount | DT/CR | account | ref  |
  +----------+--------+-------+---------+------+
  |    1     |  10.00 | DT    | Bank    |      |
  |    1     |  10.00 | CR    | AR      | INV1 |
  +----------+--------+-------+---------+------+
  |    2     |  20.00 | DT    | Bank    |      |
  |    2     |  20.00 | CR    | AR      | INV2 |
  +----------+--------+-------+---------+------+

To track the lines spread across the two transactions into a single payment,
the 'payment_links' table references each of the lines as well as a line in
the 'payment' table.  Each line in the 'payment_links' table has a 'type',
which has one of the three values below. For non-overpayment lines, the type
is always '1'.

Overpayments are entered into the ledger as a GL transaction of two lines; one
line posts against the cash account; the other against the overpayment account.
The overpayment gets entered into this table with payment_links of type 2 to the
associated acc_trans lines. E.g.

  +----------+---------+-------+---------+--------------+--------+
  | trans_id |  amount | DT/CR | account | payment type | eca_id |
  +----------+---------+-------+---------+--------------+--------+
  |   15     |   40.00 |  DT   | Bank    |   2          | 21     |
  |   15     |   40.00 |  CR   | Prepay  |   2          | 21     |
  +----------+---------+-------+---------+--------------+--------+

Note that the 'payment type' is the 'type' field in the 'payment_links' table
and that the 'eca_id' field is the 'entity_credit_id' from the 'payment'
table.


Allocations of overpayments to invoices are entered as 2 lines of an AR/AP
transaction, linking the associated acc_trans lines to a payment using
payment_links of type 0. In case the payment involves a foreign currency gain
or loss, the allocation consists of 3 lines. All three lines are included
in the payment_links.
A 4th line may be involved when an early payment discount is in order.

E.g. when an overpayment gets used to pay the two invoices from the example
above, the transactions will look like this (when the payment is payment_id
'20' and the overpayment is payment_id '15' -- as created above):

  +----------+--------+-------+---------+------+------------+--------+
  | trans_id | amount | DT/CR | account | ref  | payment_id | ovp_id |
  +----------+--------+-------+---------+------+------------+--------+
  |    1     |  10.00 | DT    | Prepay  |      |    20      |   15   |
  |    1     |  10.00 | CR    | AR      | INV1 |    20      |   N/A  |
  +----------+--------+-------+---------+------+------------+--------+
  |    2     |  20.00 | DT    | Prepay  |      |    20      |   15   |
  |    2     |  20.00 | CR    | AR      | INV2 |    20      |   N/A  |
  +----------+--------+-------+---------+------+------------+--------+

Note that 'payment_id' is the 'id' field from the 'payment' table for the
payment currently being entered.  The 'ovp_id' is the same 'id' field in
the 'payment' table, but links to the overpayment-creation payment record.

The links to the 'payment_id' and 'ovp_id' are created using 2 records in
the 'payment_links' table for the same 'acc_trans' row, with values '1'
and '0' for the payment and overpayment-use respectively.

$$;


COMMENT ON COLUMN payment.gl_id IS
$$ Pre- and overpayments are linked to the GL;
AR/AP payment lines are directly connected to 'ar' or 'ap' records which means
this field isn't used in those cases. $$; -- '

COMMENT ON COLUMN payment.payment_class IS
$$ 1 = payment , 2 = receipt
following the values of entity_class (1=vendor, 2=customer) $$;

COMMENT ON TABLE payment_links IS
$$ Ties acc_trans lines in ar/ap/gl items to payments

The key to linking transaction lines  to payments is the 'type' column. See
there for more documentation on how to use this table.

Note that *all* lines resulting from a payment should be linked. This includes
foreign currency difference lines on ar/ap items and means that the lines
linked to a single payment must be balanced. $$;

COMMENT ON COLUMN payment_links.type IS $$
 * A type '0' means the link is referencing an ar/ap  and was created
   using an overpayment movement after the receipt was created
 * A type '1' means the link is referencing an ar/ap and  was made
   on the payment creation, its not the product of an overpayment movement
 * A type '2' means the link is not referencing an ar/ap and it is the product
   of the overpayment logic

 With this idea in order we can do the following

 To get the payment amount we will sum the entries with type > 0.
 To get the used amount we will sum the entries with type < 2.
 The overpayment account can be obtained from the entries with type = 2.

Note that fx difference lines are expected to be included in the list of
references for types 0 and 1.

Note that every acc_trans entry is expected be in exactly one payment_link
record.
$$;
