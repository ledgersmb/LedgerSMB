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

# Non UTF8 accented characters are confirmed working
  @wip
  Examples:
    | selection                  | translation                          | language         |
    | American English           | American English                     | Language         |
    | Brazilian Portuguese       | português - Brasil                   | Idioma           |
    | British English            | British English                      | Language         |
    | Canadian French            | français canadien                    | Langue           |
    | Catalan                    | català                               | Idioma           |
    | Danish                     | dansk                                | Sprog            |
    | Dutch                      | Nederlands                           | Taal             |
    | English                    | English                              | Language         |
    | Estonian                   | eesti                                | Keel             |
    | Finnish                    | suomi                                | Kieli            |
    | Flemish                    | Nederlands - België                  | Taal             |
    | French                     | français                             | Langue           |
    | French - Belgium           | français - Belgique                  | Langue           |
    | German                     | Deutsch                              | Sprache          |
    | Hungarian                  | magyar                               | Nyelv            |
    | Icelandic                  | íslenska                             | Túngumál         |
    | Indonesian                 | Indonesia                            | Bahasa           |
    | Italian                    | italiano                             | Lingua           |
    | Malay - Malaysia           | Melayu - Malaysia                    | Bahasa           |
    | Mexican Spanish            | español de México                    | Lenguaje         |
    | Norwegian Bokmål           | norsk bokmål                         | Språk            |
    | Portuguese                 | português                            | Língua           |
    | Spanish                    | español                              | Lenguaje         |
    | Spanish - Argentina        | español - Argentina                  | Idioma           |
    | Spanish - Colombia         | español - Colombia                   | Idioma           |
    | Spanish - Ecuador          | español - Ecuador                    | Lenguaje         |
    | Spanish - Panama           | español - Panamá                     | Idioma           |
    | Spanish - Paraguay         | español - Paraguay                   | Idioma           |
    | Spanish - Venezuela        | español - Venezuela                  | Idioma           |
    | Swedish                    | svenska                              | Språk            |
    | Swiss High German          | Schweizer Hochdeutsch                | Sprache          |
    | Turkish                    | Türkçe                               | Dil              |

# Failing for an unknown reason
  Examples:
    | selection                  | translation                          | language         |
    | Canadian English           | Canadian English                     | Language         |

# prove has problems displaying UTF8, even though tests works
  @wip
  Examples:
    | selection                  | translation                          | language         |
    | Arabic - Egypt             | اللغة |                       العربية - مصر            |
    | Bulgarian                  | български                            | Език             |
    | Chinese - China            | 中文 - 中国                           | 语言             |
    | Chinese - Taiwan           | 中文 - 台灣                           | 語言             |
    | Czech                      | čeština                              | Jazyk            |
    | Greek                      | Ελληνικά                             | Γλώσσα           |
    | Lithuanian                 | lietuvių                             | Kalba            |
    | Polish                     | polski                               | Język            |
    | Russian                    | русский                              | Язык             |
    | Ukrainian                  | українська                           | Мова             |
