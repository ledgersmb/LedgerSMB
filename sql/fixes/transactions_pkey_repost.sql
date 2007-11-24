
CREATE RULE ap_track_d AS ON DELETE TO ap DO ALSO DELETE FROM transactions 
WHERE id = old.id AND table_name = 'ap';
CREATE RULE ar_track_d AS ON DELETE TO ar DO ALSO DELETE FROM transactions 
WHERE id = old.id AND table_name = 'ar';
CREATE RULE gl_track_d AS ON DELETE TO ap DO ALSO DELETE FROM transactions 
WHERE id = old.id AND table_name = 'gl';
