

create table cr_report_line_links (
    report_line_id int references cr_report_line(id),
    entry_id int references acc_trans(entry_id),
    primary key (report_line_id, entry_id)
);


comment on table cr_report_line_links is
$$This table expresses the explicit relationship between the
lines on the reconciliation report and the lines in acc_trans which
constitute the ledger lines aggregated into the reconciliation line.$$;


with recon_items as (
      SELECT ac.chart_id, gl.ref as reference, ac.source as source,
             ac.voucher_id, array_agg(ac.entry_id) as entries, ac.transdate
        FROM acc_trans ac
        JOIN transactions t on (ac.trans_id = t.id)
        JOIN (select id, entity_credit_account::text as ref, curr,
                     transdate, 'ar' as table
                FROM ar where approved
                UNION
              select id, entity_credit_account::text, curr,
                     transdate, 'ap' as table
                FROM ap WHERE approved
                UNION
              select id, reference, '',
                     transdate, 'gl' as table
                FROM gl WHERE approved) gl
                ON (gl.table = t.table_name AND gl.id = t.id)
        WHERE  ac.approved IS TRUE
        GROUP BY ac.chart_id, gl.ref, ac.source, ac.transdate,
                 ac.memo, ac.voucher_id, gl.table
)
insert into cr_report_line_links (report_line_id, entry_id)
     select cl.id, unnest(ri.entries)
       from cr_report r
       join cr_report_line cl on r.id = cl.report_id
       join recon_items ri on (ri.voucher_id = cl.voucher_id
                               or cl.ledger_id = any(ri.entries))
                              and r.chart_id = ri.chart_id;
