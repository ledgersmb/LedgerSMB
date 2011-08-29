-- This is a fix for a known issue (SourceForge ID: 2761045) where reposting
-- invoices more than once causes a primary key issue on the transactions table.
--
-- For more information, see:
-- http://www.mail-archive.com/ledger-smb-devel@lists.sourceforge.net/msg01560.html
-- https://sourceforge.net/tracker/?func=detail&aid=2761045&group_id=175965&atid=875350

CREATE RULE ap_track_d AS ON DELETE TO ap DO ALSO DELETE FROM transactions 
WHERE id = old.id AND table_name = 'ap';
CREATE RULE ar_track_d AS ON DELETE TO ar DO ALSO DELETE FROM transactions 
WHERE id = old.id AND table_name = 'ar';
CREATE RULE gl_track_d AS ON DELETE TO ap DO ALSO DELETE FROM transactions 
WHERE id = old.id AND table_name = 'gl';
