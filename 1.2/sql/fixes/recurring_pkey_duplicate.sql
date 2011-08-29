-- SC: Corrects the primary key constraints on the recurringemail and print
--     tables.  The original primary keys are too restrictive and go against
--     how the application works in that they don't allow for printing or
--     emailing multiple forms as part of a recurring transaction.
--
--     Related adjustments also are made to the status table.

ALTER TABLE recurringemail DROP CONSTRAINT recurringemail_pkey;
ALTER TABLE recurringemail ADD PRIMARY KEY (id, formname);
ALTER TABLE recurringprint DROP CONSTRAINT recurringprint_pkey;
ALTER TABLE recurringprint ADD PRIMARY KEY (id, formname);
ALTER TABLE status DROP CONSTRAINT status_pkey;
ALTER TABLE status ADD PRIMARY KEY (trans_id, formname);
