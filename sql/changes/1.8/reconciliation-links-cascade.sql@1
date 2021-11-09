

alter table cr_report_line_links
   drop constraint cr_report_line_links_report_line_id_fkey,
   add CONSTRAINT cr_report_line_links_report_line_id_fkey
        FOREIGN KEY (report_line_id)
           REFERENCES public.cr_report_line (id) MATCH SIMPLE
           ON UPDATE NO ACTION
           ON DELETE CASCADE;

