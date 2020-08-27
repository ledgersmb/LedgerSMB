# Using one db would be quicker but the menu language would persist from
# previous pass and PageObject/App/Menu.pm would have to be able to handle
# non-english menus
@one-db @weasel
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
  When I select "<default>" from the drop down "<language>"
   And I click "<save>" to save the page
   And I select the "Preferences" tab
  Then I expect "English" to be selected for "Language"

# Non UTF8 accented characters are confirmed working
  @wip
  Examples:
    | selection              | translation            | language     | default         | save          |
    | American English       | American English       | Language     | English         | Save          |
    | Brazilian Portuguese   | português - Brasil     | Idioma       | inglês          | Salvar        |
    | British English        | British English        | Language     | English         | Save          |
    | Canadian French        | français canadien      | Langue       | anglais         | Enregistrer   |
    | Catalan                | català                 | Idioma       | anglès          | Guardar       |
    | Danish                 | dansk                  | Sprog        | engelsk         | Gem           |
    | Dutch                  | Nederlands             | Taal         | Engels          | Opslaan       |
    | Estonian               | eesti                  | Keel         | inglise         | Salvesta      |
    | Finnish                | suomi                  | Kieli        | englanti        | Tallenna      |
    | Flemish                | Nederlands - België    | Taal         | Engels          | Opslaan       |
    | French                 | français               | Langue       | anglais         | Enregistrer   |
    | French - Belgium       | français - Belgique    | Langue       | anglais         | Enregistrer   |
    | German                 | Deutsch                | Sprache      | Englisch        | Speichern     |
    | Hungarian              | magyar                 | Nyelv        | angol           | Mentés        |
    | Icelandic              | íslenska               | Túngumál     | enska           | Geyma         |
    | Indonesian             | Indonesia              | Bahasa       | Inggris         | Simpan        |
    | Italian                | italiano               | Lingua       | inglese         | Salva         |
    | Malay - Malaysia       | Melayu - Malaysia      | Bahasa       | Inggeris        | Simpan        |
    | Mexican Spanish        | español de México      | Lenguaje     | inglés          | Guardar       |
    | Norwegian Bokmål       | norsk bokmål           | Språk        | engelsk         | Lagre         |
    | Portuguese             | português              | Língua       | inglês          | Guardar       |
    | Spanish                | español                | Lenguaje     | inglés          | Guardar       |
    | Spanish - Argentina    | español - Argentina    | Idioma       | inglés          | Guardar       |
    | Spanish - Colombia     | español - Colombia     | Idioma       | inglés          | Guardar       |
    | Spanish - Ecuador      | español - Ecuador      | Lenguaje     | inglés          | Guardar       |
    | Spanish - Panama       | español - Panamá       | Idioma       | inglés          | Guardar       |
    | Spanish - Paraguay     | español - Paraguay     | Idioma       | inglés          | Guardar       |
    | Spanish - Venezuela    | español - Venezuela    | Idioma       | inglés          | Guardar       |
    | Swedish                | svenska                | Språk        | engelska        | Spara         |
    | Swiss High German      | Schweizer Hochdeutsch  | Sprache      | Englisch        | Speichern     |

# Failing for an unknown reason, yet
  Examples:
    | selection              | translation            | language     | default         | save          |
    | Canadian English       | Canadian English       | Language     | English         | Save          |

# prove has problems displaying UTF8, even though tests works
  @wip
  Examples:
    | selection              | translation            | language     | default         | save          |
    | Arabic - Egypt         | اللغة |  العربية - مصر |   الإنجليزية |                  تخزين         |
    | Bulgarian              | български              | Език         | английски       | Запази        |
    | Chinese - China        | 中文 - 中国             | 语言         | 英语             | 储存          |
    | Chinese - Taiwan       | 中文 - 台灣             | 語言         | 英文             | 儲存          |
    | Czech                  | čeština                | Jazyk        | angličtina      | Uložit        |
    | Greek                  | Ελληνικά               | Γλώσσα       | Αγγλικά         | Αποθήκευση    |
    | Lithuanian             | lietuvių               | Kalba        | anglų           | Išsaugoti     |
    | Polish                 | polski                 | Język        | angielski       | Zapisz        |
    | Russian                | русский                | Язык         | английский      | Сохранить     |
    | Turkish                | Türkçe                 | Dil          | İngilizce       | Kaydet        |
    | Ukrainian              | українська             | Мова         | англійська      | Зберегти      |
