
-- The template count condition below prevents this notification
-- being thrown on new databases. This change file *will* run on
-- a new database, but the 'template' table will be empty.

select pg_notify(
  'upgrade.' || current_database(),
  $json${"type":"feedback","content":"As of 1.8, the balance sheet and income statement templates used to generate downloaded documents, have been moved to the database. Please go to "System > Templates" and upload the templates provided in the templates/ directory. Until this action is completed, these reports are available only in the UI, but the download links will not work.$json$)
 where (select count(*) from template) > 0
   and (not exists (select 1
                      from template
                     where template_name = 'balance_sheet')
        or not exists (select 1
                         from template
                        where template_name = 'PNL'));
