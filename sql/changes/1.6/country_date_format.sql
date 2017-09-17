ALTER TABLE country
  ADD date_format TEXT;

INSERT INTO country(short_name,name) VALUES ('BL','St. Barthelemy');
INSERT INTO country(short_name,name) VALUES ('BQ','Caribbean Netherlands');
INSERT INTO country(short_name,name) VALUES ('CW','Curacao');
INSERT INTO country(short_name,name) VALUES ('DG','Diego Garcia');
INSERT INTO country(short_name,name) VALUES ('EA','Ceuta & Melilla');
INSERT INTO country(short_name,name) VALUES ('GG','Guernsey');
INSERT INTO country(short_name,name) VALUES ('IC','Canary Islands');
INSERT INTO country(short_name,name) VALUES ('ME','Montenegro');
INSERT INTO country(short_name,name) VALUES ('MF','St. Martin');
INSERT INTO country(short_name,name) VALUES ('SS','South Sudan');
INSERT INTO country(short_name,name) VALUES ('SX','Sint Maarten');
INSERT INTO country(short_name,name) VALUES ('TL','Timor-Leste');
INSERT INTO country(short_name,name) VALUES ('XK','Kosovo');

--UPDATE country SET date_format = '' WHERE short_name = 'AC'; -- Ascension Island
--UPDATE country SET date_format = '' WHERE short_name = 'AD'; -- Andorra
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'AE'; -- United Arab Emirates
--UPDATE country SET date_format = '' WHERE short_name = 'AF'; -- Afghanistan
--UPDATE country SET date_format = '' WHERE short_name = 'AG'; -- Antigua and Barbuda
--UPDATE country SET date_format = '' WHERE short_name = 'AI'; -- Anguilla
UPDATE country SET date_format = 'yyyy-MM-dd' WHERE short_name = 'AL'; -- Albania
--UPDATE country SET date_format = '' WHERE short_name = 'AM'; -- Armenia
--UPDATE country SET date_format = '' WHERE short_name = 'AN'; -- Netherlands Antilles
--UPDATE country SET date_format = '' WHERE short_name = 'AO'; -- Angola
--UPDATE country SET date_format = '' WHERE short_name = 'AQ'; -- Antarctica
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'AR'; -- Argentina
--UPDATE country SET date_format = '' WHERE short_name = 'AS'; -- American Samoa
UPDATE country SET date_format = 'dd.MM.yyyy' WHERE short_name = 'AT'; -- Austria
UPDATE country SET date_format = 'd/MM/yyyy' WHERE short_name = 'AU'; -- Australia
--UPDATE country SET date_format = '' WHERE short_name = 'AW'; -- Aruba
--UPDATE country SET date_format = '' WHERE short_name = 'AX'; -- Aland Islands
--UPDATE country SET date_format = '' WHERE short_name = 'AZ'; -- Azerbaijan
UPDATE country SET date_format = 'yyyy-MM-dd' WHERE short_name = 'BA'; -- Bosnia and Herzegovina
--UPDATE country SET date_format = '' WHERE short_name = 'BB'; -- Barbados
--UPDATE country SET date_format = '' WHERE short_name = 'BD'; -- Bangladesh
UPDATE country SET date_format = 'd/MM/yyyy' WHERE short_name = 'BE'; -- Belgium
--UPDATE country SET date_format = '' WHERE short_name = 'BF'; -- Burkina Faso
UPDATE country SET date_format = 'yyyy-M-d' WHERE short_name = 'BG'; -- Bulgaria
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'BH'; -- Bahrain
--UPDATE country SET date_format = '' WHERE short_name = 'BI'; -- Burundi
--UPDATE country SET date_format = '' WHERE short_name = 'BJ'; -- Benin
--UPDATE country SET date_format = '' WHERE short_name = 'BL'; -- St. Barthelemy
--UPDATE country SET date_format = '' WHERE short_name = 'BM'; -- Bermuda
--UPDATE country SET date_format = '' WHERE short_name = 'BN'; -- Brunei Darussalam
UPDATE country SET date_format = 'dd-MM-yyyy' WHERE short_name = 'BO'; -- Bolivia
--UPDATE country SET date_format = '' WHERE short_name = 'BQ'; -- Caribbean Netherlands
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'BR'; -- Brazil
--UPDATE country SET date_format = '' WHERE short_name = 'BS'; -- Bahamas
--UPDATE country SET date_format = '' WHERE short_name = 'BT'; -- Bhutan
--UPDATE country SET date_format = '' WHERE short_name = 'BV'; -- Bouvet Island
--UPDATE country SET date_format = '' WHERE short_name = 'BW'; -- Botswana
UPDATE country SET date_format = 'd.M.yyyy' WHERE short_name = 'BY'; -- Belarus
--UPDATE country SET date_format = '' WHERE short_name = 'BZ'; -- Belize
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'CA'; -- Canada
UPDATE country SET date_format = 'yyyy-MM-dd' WHERE short_name = 'CA'; -- Canada
--UPDATE country SET date_format = '' WHERE short_name = 'CC'; -- Cocos (Keeling) Islands
--UPDATE country SET date_format = '' WHERE short_name = 'CD'; -- Congo, Democratic Republic
--UPDATE country SET date_format = '' WHERE short_name = 'CF'; -- Central African Republic
--UPDATE country SET date_format = '' WHERE short_name = 'CG'; -- Congo
UPDATE country SET date_format = 'dd.MM.yyyy' WHERE short_name = 'CH'; -- Switzerland
--UPDATE country SET date_format = '' WHERE short_name = 'CI'; -- Cote D''Ivoire (Ivory Coast)
--UPDATE country SET date_format = '' WHERE short_name = 'CK'; -- Cook Islands
UPDATE country SET date_format = 'dd-MM-yyyy' WHERE short_name = 'CL'; -- Chile
--UPDATE country SET date_format = '' WHERE short_name = 'CM'; -- Cameroon
UPDATE country SET date_format = 'yyyy-M-d' WHERE short_name = 'CN'; -- China
UPDATE country SET date_format = 'd/MM/yyyy' WHERE short_name = 'CO'; -- Colombia
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'CR'; -- Costa Rica
UPDATE country SET date_format = 'd.M.yyyy.' WHERE short_name = 'CS'; -- Serbia and Montenegro
--UPDATE country SET date_format = '' WHERE short_name = 'CU'; -- Cuba
--UPDATE country SET date_format = '' WHERE short_name = 'CV'; -- Cape Verde
--UPDATE country SET date_format = '' WHERE short_name = 'CW'; -- Curacao
--UPDATE country SET date_format = '' WHERE short_name = 'CX'; -- Christmas Island
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'CY'; -- Cyprus
UPDATE country SET date_format = 'd.M.yyyy' WHERE short_name = 'CZ'; -- Czech Republic
UPDATE country SET date_format = 'dd.MM.yyyy' WHERE short_name = 'DE'; -- Germany
--UPDATE country SET date_format = '' WHERE short_name = 'DG'; -- Diego Garcia
--UPDATE country SET date_format = '' WHERE short_name = 'DJ'; -- Djibouti
UPDATE country SET date_format = 'dd-MM-yyyy' WHERE short_name = 'DK'; -- Denmark
--UPDATE country SET date_format = '' WHERE short_name = 'DM'; -- Dominica
UPDATE country SET date_format = 'MM/dd/yyyy' WHERE short_name = 'DO'; -- Dominican Republic
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'DZ'; -- Algeria
--UPDATE country SET date_format = '' WHERE short_name = 'EA'; -- Ceuta & Melilla
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'EC'; -- Ecuador
UPDATE country SET date_format = 'd.MM.yyyy' WHERE short_name = 'EE'; -- Estonia
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'EG'; -- Egypt
--UPDATE country SET date_format = '' WHERE short_name = 'EH'; -- Western Sahara
--UPDATE country SET date_format = '' WHERE short_name = 'ER'; -- Eritrea
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'ES'; -- Spain
--UPDATE country SET date_format = '' WHERE short_name = 'ET'; -- Ethiopia
UPDATE country SET date_format = 'd.M.yyyy' WHERE short_name = 'FI'; -- Finland
--UPDATE country SET date_format = '' WHERE short_name = 'FJ'; -- Fiji
--UPDATE country SET date_format = '' WHERE short_name = 'FK'; -- Falkland Islands (Malvinas)
--UPDATE country SET date_format = '' WHERE short_name = 'FM'; -- Micronesia
--UPDATE country SET date_format = '' WHERE short_name = 'FO'; -- Faroe Islands
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'FR'; -- France
--UPDATE country SET date_format = '' WHERE short_name = 'FX'; -- France, Metropolitan
--UPDATE country SET date_format = '' WHERE short_name = 'GA'; -- Gabon
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'GB'; -- United Kingdom
--UPDATE country SET date_format = '' WHERE short_name = 'GD'; -- Grenada
--UPDATE country SET date_format = '' WHERE short_name = 'GE'; -- Georgia
--UPDATE country SET date_format = '' WHERE short_name = 'GF'; -- French Guiana
--UPDATE country SET date_format = '' WHERE short_name = 'GG'; -- Guernsey
--UPDATE country SET date_format = '' WHERE short_name = 'GH'; -- Ghana
--UPDATE country SET date_format = '' WHERE short_name = 'GI'; -- Gibraltar
--UPDATE country SET date_format = '' WHERE short_name = 'GL'; -- Greenland
--UPDATE country SET date_format = '' WHERE short_name = 'GM'; -- Gambia
--UPDATE country SET date_format = '' WHERE short_name = 'GN'; -- Guinea
--UPDATE country SET date_format = '' WHERE short_name = 'GP'; -- Guadeloupe
--UPDATE country SET date_format = '' WHERE short_name = 'GQ'; -- Equatorial Guinea
UPDATE country SET date_format = 'd/M/yyyy' WHERE short_name = 'GR'; -- Greece
--UPDATE country SET date_format = '' WHERE short_name = 'GS'; -- S. Georgia and S. Sandwich Isls.
UPDATE country SET date_format = 'd/MM/yyyy' WHERE short_name = 'GT'; -- Guatemala
--UPDATE country SET date_format = '' WHERE short_name = 'GU'; -- Guam
--UPDATE country SET date_format = '' WHERE short_name = 'GW'; -- Guinea-Bissau
--UPDATE country SET date_format = '' WHERE short_name = 'GY'; -- Guyana
UPDATE country SET date_format = 'yyyy?M?d?' WHERE short_name = 'HK'; -- Hong Kong
--UPDATE country SET date_format = '' WHERE short_name = 'HM'; -- Heard and McDonald Islands
UPDATE country SET date_format = 'MM-dd-yyyy' WHERE short_name = 'HN'; -- Honduras
UPDATE country SET date_format = 'dd.MM.yyyy.' WHERE short_name = 'HR'; -- Croatia
--UPDATE country SET date_format = '' WHERE short_name = 'HT'; -- Haiti
UPDATE country SET date_format = 'yyyy.MM.dd.' WHERE short_name = 'HU'; -- Hungary
--UPDATE country SET date_format = '' WHERE short_name = 'IC'; -- Canary Islands
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'ID'; -- Indonesia
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'IE'; -- Ireland
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'IL'; -- Israel
--UPDATE country SET date_format = '' WHERE short_name = 'IM'; -- Isle of Man
UPDATE country SET date_format = 'd/M/yyyy' WHERE short_name = 'IN'; -- India
--UPDATE country SET date_format = '' WHERE short_name = 'IO'; -- British Indian Ocean Territory
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'IQ'; -- Iraq
--UPDATE country SET date_format = '' WHERE short_name = 'IR'; -- Iran
UPDATE country SET date_format = 'd.M.yyyy' WHERE short_name = 'IS'; -- Iceland
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'IT'; -- Italy
--UPDATE country SET date_format = '' WHERE short_name = 'JE'; -- Jersey
--UPDATE country SET date_format = '' WHERE short_name = 'JM'; -- Jamaica
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'JO'; -- Jordan
UPDATE country SET date_format = 'yyyy/MM/dd' WHERE short_name = 'JP'; -- Japan
--UPDATE country SET date_format = '' WHERE short_name = 'KE'; -- Kenya
--UPDATE country SET date_format = '' WHERE short_name = 'KG'; -- Kyrgyzstan
--UPDATE country SET date_format = '' WHERE short_name = 'KH'; -- Cambodia
--UPDATE country SET date_format = '' WHERE short_name = 'KI'; -- Kiribati
--UPDATE country SET date_format = '' WHERE short_name = 'KM'; -- Comoros
--UPDATE country SET date_format = '' WHERE short_name = 'KN'; -- Saint Kitts and Nevis
--UPDATE country SET date_format = '' WHERE short_name = 'KP'; -- Korea (North)
UPDATE country SET date_format = 'yyyy. M. d' WHERE short_name = 'KR'; -- South Korea
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'KW'; -- Kuwait
--UPDATE country SET date_format = '' WHERE short_name = 'KY'; -- Cayman Islands
--UPDATE country SET date_format = '' WHERE short_name = 'KZ'; -- Kazakhstan
--UPDATE country SET date_format = '' WHERE short_name = 'LA'; -- Laos
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'LB'; -- Lebanon
--UPDATE country SET date_format = '' WHERE short_name = 'LC'; -- Saint Lucia
--UPDATE country SET date_format = '' WHERE short_name = 'LI'; -- Liechtenstein
--UPDATE country SET date_format = '' WHERE short_name = 'LK'; -- Sri Lanka
--UPDATE country SET date_format = '' WHERE short_name = 'LR'; -- Liberia
--UPDATE country SET date_format = '' WHERE short_name = 'LS'; -- Lesotho
UPDATE country SET date_format = 'yyyy.M.d' WHERE short_name = 'LT'; -- Lithuania
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'LU'; -- Luxembourg
UPDATE country SET date_format = 'yyyy.d.M' WHERE short_name = 'LV'; -- Latvia
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'LY'; -- Libya
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'MA'; -- Morocco
--UPDATE country SET date_format = '' WHERE short_name = 'MC'; -- Monaco
--UPDATE country SET date_format = '' WHERE short_name = 'MD'; -- Moldova
UPDATE country SET date_format = 'd.M.yyyy.' WHERE short_name = 'ME'; -- Montenegro
--UPDATE country SET date_format = '' WHERE short_name = 'MF'; -- St. Martin
--UPDATE country SET date_format = '' WHERE short_name = 'MG'; -- Madagascar
--UPDATE country SET date_format = '' WHERE short_name = 'MH'; -- Marshall Islands
UPDATE country SET date_format = 'd.M.yyyy' WHERE short_name = 'MK'; -- Macedonia
--UPDATE country SET date_format = '' WHERE short_name = 'ML'; -- Mali
--UPDATE country SET date_format = '' WHERE short_name = 'MM'; -- Myanmar
--UPDATE country SET date_format = '' WHERE short_name = 'MN'; -- Mongolia
--UPDATE country SET date_format = '' WHERE short_name = 'MO'; -- Macau
--UPDATE country SET date_format = '' WHERE short_name = 'MP'; -- Northern Mariana Islands
--UPDATE country SET date_format = '' WHERE short_name = 'MQ'; -- Martinique
--UPDATE country SET date_format = '' WHERE short_name = 'MR'; -- Mauritania
--UPDATE country SET date_format = '' WHERE short_name = 'MS'; -- Montserrat
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'MT'; -- Malta
--UPDATE country SET date_format = '' WHERE short_name = 'MU'; -- Mauritius
--UPDATE country SET date_format = '' WHERE short_name = 'MV'; -- Maldives
--UPDATE country SET date_format = '' WHERE short_name = 'MW'; -- Malawi
UPDATE country SET date_format = 'd/MM/yyyy' WHERE short_name = 'MX'; -- Mexico
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'MY'; -- Malaysia
--UPDATE country SET date_format = '' WHERE short_name = 'MZ'; -- Mozambique
--UPDATE country SET date_format = '' WHERE short_name = 'NA'; -- Namibia
--UPDATE country SET date_format = '' WHERE short_name = 'NC'; -- New Caledonia
--UPDATE country SET date_format = '' WHERE short_name = 'NE'; -- Niger
--UPDATE country SET date_format = '' WHERE short_name = 'NF'; -- Norfolk Island
--UPDATE country SET date_format = '' WHERE short_name = 'NG'; -- Nigeria
UPDATE country SET date_format = 'MM-dd-yyyy' WHERE short_name = 'NI'; -- Nicaragua
UPDATE country SET date_format = 'd-M-yyyy' WHERE short_name = 'NL'; -- Netherlands
UPDATE country SET date_format = 'dd.MM.yyyy' WHERE short_name = 'NO'; -- Norway
--UPDATE country SET date_format = '' WHERE short_name = 'NP'; -- Nepal
--UPDATE country SET date_format = '' WHERE short_name = 'NR'; -- Nauru
--UPDATE country SET date_format = '' WHERE short_name = 'NT'; -- Neutral Zone
--UPDATE country SET date_format = '' WHERE short_name = 'NU'; -- Niue
UPDATE country SET date_format = 'd/MM/yyyy' WHERE short_name = 'NZ'; -- New Zealand
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'OM'; -- Oman
UPDATE country SET date_format = 'MM/dd/yyyy' WHERE short_name = 'PA'; -- Panama
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'PE'; -- Peru
--UPDATE country SET date_format = '' WHERE short_name = 'PF'; -- French Polynesia
--UPDATE country SET date_format = '' WHERE short_name = 'PG'; -- Papua New Guinea
UPDATE country SET date_format = 'M/d/yyyy' WHERE short_name = 'PH'; -- Philippines
--UPDATE country SET date_format = '' WHERE short_name = 'PK'; -- Pakistan
UPDATE country SET date_format = 'dd.MM.yyyy' WHERE short_name = 'PL'; -- Poland
--UPDATE country SET date_format = '' WHERE short_name = 'PM'; -- St. Pierre and Miquelon
--UPDATE country SET date_format = '' WHERE short_name = 'PN'; -- Pitcairn
UPDATE country SET date_format = 'MM-dd-yyyy' WHERE short_name = 'PR'; -- Puerto Rico
--UPDATE country SET date_format = '' WHERE short_name = 'PS'; -- Palestinian Territory, Occupied
UPDATE country SET date_format = 'dd-MM-yyyy' WHERE short_name = 'PT'; -- Portugal
--UPDATE country SET date_format = '' WHERE short_name = 'PW'; -- Palau
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'PY'; -- Paraguay
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'QA'; -- Qatar
--UPDATE country SET date_format = '' WHERE short_name = 'RE'; -- Reunion
UPDATE country SET date_format = 'dd.MM.yyyy' WHERE short_name = 'RO'; -- Romania
UPDATE country SET date_format = 'd.M.yyyy.' WHERE short_name = 'RS'; -- Serbia
UPDATE country SET date_format = 'dd.MM.yyyy' WHERE short_name = 'RU'; -- Russia
--UPDATE country SET date_format = '' WHERE short_name = 'RW'; -- Rwanda
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'SA'; -- Saudi Arabia
--UPDATE country SET date_format = '' WHERE short_name = 'SB'; -- Solomon Islands
--UPDATE country SET date_format = '' WHERE short_name = 'SC'; -- Seychelles
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'SD'; -- Sudan
UPDATE country SET date_format = 'yyyy-MM-dd' WHERE short_name = 'SE'; -- Sweden
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'SG'; -- Singapore
--UPDATE country SET date_format = '' WHERE short_name = 'SH'; -- St. Helena
UPDATE country SET date_format = 'd.M.yyyy' WHERE short_name = 'SI'; -- Slovenia
--UPDATE country SET date_format = '' WHERE short_name = 'SJ'; -- Svalbard & Jan Mayen Islands
UPDATE country SET date_format = 'd.M.yyyy' WHERE short_name = 'SK'; -- Slovakia
--UPDATE country SET date_format = '' WHERE short_name = 'SL'; -- Sierra Leone
--UPDATE country SET date_format = '' WHERE short_name = 'SM'; -- San Marino
--UPDATE country SET date_format = '' WHERE short_name = 'SN'; -- Senegal
--UPDATE country SET date_format = '' WHERE short_name = 'SO'; -- Somalia
--UPDATE country SET date_format = '' WHERE short_name = 'SR'; -- Suriname
--UPDATE country SET date_format = '' WHERE short_name = 'SS'; -- South Sudan
--UPDATE country SET date_format = '' WHERE short_name = 'ST'; -- Sao Tome and Principe
--UPDATE country SET date_format = '' WHERE short_name = 'SU'; -- USSR (former)
UPDATE country SET date_format = 'MM-dd-yyyy' WHERE short_name = 'SV'; -- El Salvador
--UPDATE country SET date_format = '' WHERE short_name = 'SX'; -- Sint Maarten
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'SY'; -- Syria
--UPDATE country SET date_format = '' WHERE short_name = 'SZ'; -- Swaziland
--UPDATE country SET date_format = '' WHERE short_name = 'TC'; -- Turks and Caicos Islands
--UPDATE country SET date_format = '' WHERE short_name = 'TD'; -- Chad
--UPDATE country SET date_format = '' WHERE short_name = 'TF'; -- French Southern Territories
--UPDATE country SET date_format = '' WHERE short_name = 'TG'; -- Togo
UPDATE country SET date_format = 'd/M/yyyy' WHERE short_name = 'TH'; -- Thailand
--UPDATE country SET date_format = '' WHERE short_name = 'TJ'; -- Tajikistan
--UPDATE country SET date_format = '' WHERE short_name = 'TK'; -- Tokelau
--UPDATE country SET date_format = '' WHERE short_name = 'TL'; -- Timor-Leste
--UPDATE country SET date_format = '' WHERE short_name = 'TM'; -- Turkmenistan
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'TN'; -- Tunisia
--UPDATE country SET date_format = '' WHERE short_name = 'TO'; -- Tonga
--UPDATE country SET date_format = '' WHERE short_name = 'TP'; -- East Timor
UPDATE country SET date_format = 'dd.MM.yyyy' WHERE short_name = 'TR'; -- Turkey
--UPDATE country SET date_format = '' WHERE short_name = 'TT'; -- Trinidad and Tobago
--UPDATE country SET date_format = '' WHERE short_name = 'TV'; -- Tuvalu
UPDATE country SET date_format = 'yyyy/M/d' WHERE short_name = 'TW'; -- Taiwan
--UPDATE country SET date_format = '' WHERE short_name = 'TZ'; -- Tanzania
UPDATE country SET date_format = 'dd.MM.yyyy' WHERE short_name = 'UA'; -- Ukraine
--UPDATE country SET date_format = '' WHERE short_name = 'UG'; -- Uganda
--UPDATE country SET date_format = '' WHERE short_name = 'UK'; -- United Kingdom
--UPDATE country SET date_format = '' WHERE short_name = 'UM'; -- US Minor Outlying Islands
UPDATE country SET date_format = 'M/d/yyyy' WHERE short_name = 'US'; -- United States
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'UY'; -- Uruguay
--UPDATE country SET date_format = '' WHERE short_name = 'UZ'; -- Uzbekistan
--UPDATE country SET date_format = '' WHERE short_name = 'VA'; -- Vatican City State (Holy See)
--UPDATE country SET date_format = '' WHERE short_name = 'VC'; -- Saint Vincent & the Grenadines
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'VE'; -- Venezuela
--UPDATE country SET date_format = '' WHERE short_name = 'VG'; -- British Virgin Islands
--UPDATE country SET date_format = '' WHERE short_name = 'VI'; -- Virgin Islands (U.S.)
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'VN'; -- Vietnam
--UPDATE country SET date_format = '' WHERE short_name = 'VU'; -- Vanuatu
--UPDATE country SET date_format = '' WHERE short_name = 'WF'; -- Wallis and Futuna Islands
--UPDATE country SET date_format = '' WHERE short_name = 'WS'; -- Samoa
--UPDATE country SET date_format = '' WHERE short_name = 'XK'; -- Kosovo
UPDATE country SET date_format = 'dd/MM/yyyy' WHERE short_name = 'YE'; -- Yemen
--UPDATE country SET date_format = '' WHERE short_name = 'YT'; -- Mayotte
--UPDATE country SET date_format = '' WHERE short_name = 'YU'; -- Yugoslavia (former)
UPDATE country SET date_format = 'yyyy/MM/dd' WHERE short_name = 'ZA'; -- South Africa
--UPDATE country SET date_format = '' WHERE short_name = 'ZM'; -- Zambia
--UPDATE country SET date_format = '' WHERE short_name = 'ZR'; -- Zaire
--UPDATE country SET date_format = '' WHERE short_name = 'ZW'; -- Zimbabwe
