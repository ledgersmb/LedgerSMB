
-- This is a separate file because the original didn't include creation
-- of workflow contexts, which breaks handling of unfinished workflows

insert into workflow_context (workflow_id, context)
select workflow_id,
       json_build_object(
         'id', c.id,
         'account_id', c.chart_id,
         'end_date', c.end_date,
         'ending_balance', c.their_total
       )
  from cr_report c;
