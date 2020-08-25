# Using one db would be quicker but the menu language would persist from
# previous pass and PageObject/App/Menu.pm would have to be able to handle
# non-english menus
@weasel
Feature: Check correct operation of Preferences screen

Background:
  Given a standard test company
    And a logged in admin

Scenario: I change user preferences to the <selection> language
  When I navigate the menu and select the item at "Preferences"
   And I select the "Preferences" tab
   And I select "<selection>" from the drop down "Language"
   And I save the page
   And I select the "Preferences" tab
  Then I expect "<translation>" to be selected for "<language>"

  Examples:
    | selection                  | translation                          | language         |
    | American English           | American English                     | Language         |
    | British English            | British English                      | Language         |
    | Canadian English           | Canadian English                     | Language         |
    | Danish                     | dansk                                | Sprog            |
    | Dutch                      | Nederlands                           | Taal             |
    | English                    | English                              | Language         |
    | Estonian                   | eesti                                | Keel             |
    | Finnish                    | suomi                                | Kieli            |
    | German                     | Deutsch                              | Sprache          |
    | Hungarian                  | magyar                               | Nyelv            |
    | Indonesian                 | Indonesia                            | Bahasa           |
    | Italian                    | italiano                             | Lingua           |
    | Malay - Malaysia           | Melayu - Malaysia                    | Bahasa           |
    | Swiss High German          | Schweizer Hochdeutsch                | Sprache          |

# prove has problems with UTF8
  @wip
  Examples:
    | selection                  | translation                          | language         |
    | Arabic - Egypt             | اللغة |                       العربية - مصر            |
    | Brazilian Portuguese       | português - Brasil                   | Idioma           |
    | Bulgarian                  | български                            | Език             |
    | Canadian French            | français canadien                    | Langue           |
    | Catalan                    | català                               | Idioma           |
    | Chinese - China            | 中文 - 中国                           | 语言             |
    | Chinese - Taiwan           | 中文 - 台灣                           | 語言             |
    | Czech                      | čeština                              | Jazyk            |
    | Flemish                    | Nederlands - België                  | Taal             |
    | French                     | français                             | Langue           |
    | French - Belgium           | français - Belgique                  | Langue           |
    | Greek                      | Ελληνικά                             | Γλώσσα           |
    | Icelandic                  | íslenska                             | Túngumál         |
    | Lithuanian                 | lietuvių                             | Kalba            |
    | Mexican Spanish            | español de México                    | Lenguaje         |
    | Norwegian Bokmål           | norsk bokmål                         | Språk            |
    | Polish                     | polski                               | Język            |
    | Portuguese                 | português                            | Língua           |
    | Russian                    | русский                              | Язык             |
    | Spanish                    | español                              | Lenguaje         |
    | Spanish - Argentina        | español - Argentina                  | Idioma           |
    | Spanish - Colombia         | español - Colombia                   | Idioma           |
    | Spanish - Ecuador          | español - Ecuador                    | Lenguaje         |
    | Spanish - Panama           | español - Panamá                     | Idioma           |
    | Spanish - Paraguay         | español - Panamá                     | Idioma           |
    | Spanish - Venezuela        | español - Venezuela                  | Idioma           |
    | Swedish                    | svenska                              | Språk            |
    | Turkish                    | Türkçe                               | Dil              |
    | Ukrainian                  | українська                           | Мова             |
