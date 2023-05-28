
-- if both keys exist, remove the one with the typo
DELETE FROM defaults
 WHERE setting_key = 'template_immages'
   AND EXISTS (select from defaults
                where setting_key = 'template_images');

UPDATE defaults
   SET setting_key = 'template_images'
 WHERE setting_key = 'template_immages';

