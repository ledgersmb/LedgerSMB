
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
$$;

update cr_report_line_links a
   set unique_exempt = true
 where exists (select 1 from cr_report_line_links i
                where a.entry_id = i.entry_id
                group by i.entry_id
                having count(*) > 1);

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
