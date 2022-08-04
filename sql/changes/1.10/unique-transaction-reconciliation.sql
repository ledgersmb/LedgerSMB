
-- make sure data is compliant with the table constraint we're
-- about tot introduce
update cr_report set submitted = true
 where approved and not submitted;

alter table cr_report
  add constraint cr_report_approved_submitted_check
  CHECK ( submitted or not approved );

comment on constraint cr_report_approved_submitted_check on cr_report is
$$Make sure approved reports are also submitted in order to make sure that
the triggers attached to the 'submitted' column have run.
$$;

alter table cr_report_line_links
  add column unique_exempt boolean not null default false,
  add column cleared boolean not null default false;

comment on column cr_report_line_links.unique_exempt is
$$Excludes the current row from check of acc_trans lines being included
in exactly one reconciliation.

The only known reason for this value to be 'true' is data that originated
outside the current reconcliiation system. Either before 1.8 or by data
migration.
$$;

comment on column cr_report_line_links.cleared is
$$Indicates that the associated acc_trans line is (going to be) marked as
cleared. This prevents the line from being included in other reconciliations
which are either submitted or approved.

The value is maintained by triggers on the 'cr_report' and 'cr_report_line'
tables. It is defined as 'cr_report.submitted and cr_report_line.cleared'. An
INSERT trigger on the 'cr_report_line_links' table ensures the value to be
correct when creating new records.
$$;

/*
  Note that the query below sets *every* entry_id with 'unique_exempt'='f'
  exactly once. For those which have multiple occurrances, it sets the second
  and later occurrances to 't'.

  That way, the same entry_id can't be added again using the regular procedure.
*/
update cr_report_line_links a
   set unique_exempt = (b.rn<>1)
from (select report_line_id, entry_id,
             row_number() over( partition by entry_id order by report_line_id ) as rn
        from cr_report_line_links) b
where a.entry_id = b.entry_id
      and a.report_line_id = b.report_line_id;

update cr_report_line_links rll
  set cleared = (select r.approved and rl.cleared
                    from cr_report r join cr_report_line rl on r.id = rl.report_id
                   where rl.id = rll.report_line_id);

create unique index idx_cr_report_line_links_unique
    on cr_report_line_links (entry_id)
 where not unique_exempt and cleared;

comment on index idx_cr_report_line_links_unique is
$$Ensures that no acc_trans line is cleared more than once, except when the
link is marked as 'unique_exempt'.
$$;
