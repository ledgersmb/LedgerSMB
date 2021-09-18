
-- set 'vclimit' (max-per-dropdown) setting if it's not set
-- the dropdown is a filtering select these days, so users really should
-- evaluate the setting again.

insert into defaults values ('vclimit','9999')
on conflict (setting_key) do nothing;
