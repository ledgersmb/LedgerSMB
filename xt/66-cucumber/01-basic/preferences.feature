# Using one db would be quicker but the menu language would persist from
# previous pass and PageObject/App/Menu.pm would have to be able to handle
# non-english menus
@one-db @weasel
Feature: Check correct operation of Preferences screen

Background:
  Given a standard test company
    And these preferences for the admin:
      | setting  | value |
      | language | en    |
    And a logged in admin

Scenario: I change user preferences to the <selection> language
  When I navigate the menu and select the item at "Preferences"
   And I select the "Preferences" tab
   And I select "<selection>" from the drop down "Language"
   And I save the page
   And I select the "<preferences>" tab
  Then I expect "<translation>" to be selected for "<language>"

  Examples:
  Non UTF8 accented characters are confirmed working
    | selection            | translation           | language | preferences  |
    | American English     | American English      | Language | Preferences  |
    | Brazilian Portuguese | português - Brasil    | Idioma   | Preferências |

  @extended
  Examples:
  Non UTF8 accented characters are confirmed working
    | selection            | translation           | language | preferences   |
    | British English      | British English       | Language | Preferences   |
    | Canadian English     | Canadian English      | Language | Preferences   |
    | Canadian French      | français canadien     | Langue   | Préférences   |
    | Catalan              | català                | Idioma   | Preferències  |
    | Danish               | dansk                 | Sprog    | Præferencer   |
    | Dutch                | Nederlands            | Taal     | Instellingen  |
    | Estonian             | eesti                 | Keel     | Eelistused    |
    | Finnish              | suomi                 | Kieli    | Asetukset     |
    | Flemish              | Vlaams                | Taal     | Instellingen  |
    | French               | français              | Langue   | Préférences   |
    | French - Belgium     | français - Belgique   | Langue   | Préférences   |
    | German               | Deutsch               | Sprache  | Benutzereinstellungen |
    | Hungarian            | magyar                | Nyelv    | Beállítások   |
    | Icelandic            | íslenska              | Túngumál | Uppsetningar  |
    | Indonesian           | Indonesia             | Bahasa   | Preferences   |
    | Italian              | italiano              | Lingua   | Preferenze    |
    | Malay - Malaysia     | Melayu - Malaysia     | Bahasa   | Keutamaan     |
    | Mexican Spanish      | español de México     | Lenguaje | Preferencias  |
    | Norwegian Bokmål     | norsk bokmål          | Språk    | Innstillinger |
    | Portuguese           | português             | Língua   | Preferências  |
    | Spanish              | español               | Lenguaje | Preferencias  |
    | Spanish - Argentina  | español - Argentina   | Idioma   | Preferencias  |
    | Spanish - Colombia   | español - Colombia    | Idioma   | Preferencias  |
    | Spanish - Ecuador    | español - Ecuador     | Lenguaje | Preferencias  |
    | Spanish - Panama     | español - Panamá      | Idioma   | Preferencias  |
    | Spanish - Paraguay   | español - Paraguay    | Idioma   | Preferencias  |
    | Spanish - Venezuela  | español - Venezuela   | Idioma   | Preferencias  |
    | Swedish              | svenska               | Språk    | Inställningar |
    | Swiss High German    | Schweizer Hochdeutsch | Sprache  | Benutzereinstellungen |

  @wip
  Examples:
  prove has problems displaying UTF8, even though tests works
    | selection        | translation | language      | preferences |
    | Arabic - Egypt   |العربية - مصر |        اللغة | Preferences |
    | Bulgarian        | български   | Език          | Свойства    |
    | Chinese - China  | 中文 - 中国 | 语言          | 个人设定    |
    | Chinese - Taiwan | 中文 - 台灣 | 語言          | 個人設定    |
    | Czech            | čeština     | Jazyk         | Nastavení   |
    | Greek            | Ελληνικά    | Γλώσσα        | Επιλογές    |
    | Lithuanian       | lietuvių    | Kalba         | Nuostatos   |
    | Polish           | polski      | Język         | Preferencje |
    | Russian          | русский     | Язык          | Настройки   |
    | Turkish          | Türkçe      | Dil           | Tercihler   |
    | Ukrainian        | українська  | Мова          | Параметри   |

