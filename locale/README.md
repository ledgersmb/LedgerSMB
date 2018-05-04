Between LedgerSMB 1.1.1 and LedgerSMB 1.2, translations were changed to using a
standard naming scheme and formatting.  Upon upgrade, you may find that
LedgerSMB displays in a language different to which you previously configured, 
i.e. Swedish instead of Spanish, or more likely, English.  The table below
contains the mapping of old name to new name that is used in the user config
files.

be_fr	-> fr_BE
be_nl	-> nl_BE
bg_utf	-> bg
br	-> pt_BR
ca_en	-> en_CA
ca_fr	-> fr_CA
ch	-> de_CH
ch_utf	-> de_CH
cn_utf	-> zh_CN
co	-> es_CO
co_utf	-> es_CO
ct	-> ca
cz	-> cs
de	-> de
de_utf	-> de
dk	-> da
ec	-> es_EC
ee	-> ee
ee_utf	-> ee
eg_utf	-> ar_EG
en_GB	-> en_GB
es	-> es
es_utf	-> es
fi	-> fi
fi_utf	-> fi
fr	-> fr
gr	-> el
hu	-> hu
id	-> id
is	-> is
it	-> it
lt	-> lt
lv	-> lv
mx	-> es_MX
nb	-> nb
nl	-> nl
pa	-> es_PA
pl	-> pl
pt	-> pt
py	-> es_PY
ru	-> ru
ru_utf	-> ru
se	-> sv
sv	-> es_SV
tr	-> tr
tw_big5	-> zh_TW
tw_utf	-> zh_TW
ua	-> uk
ua_utf	-> uk
ve	-> es_VE


Examples of translation-coding
in source-file:
 $locale->text( 'Edit Preferences for [_1]', $form->{login} );

in locale/po/nl_BE:
 msgid "Edit Preferences for %1"
 msgstr "Instellingen aanpassen voor %1"
