BEGIN;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema='public'
          AND table_name='user_preference'
          AND column_name='timesheetframe')
    THEN
        ALTER TABLE user_preference ADD COLUMN timesheetframe text DEFAULT 'Week' NOT NULL;
    ELSE
        ALTER TABLE user_preference ALTER COLUMN timesheetframe TYPE text;
        ALTER TABLE user_preference ALTER COLUMN timesheetframe SET DEFAULT 'Week';
        UPDATE user_preference SET timesheetframe = 'Week'
        WHERE timesheetframe IS NULL;
        ALTER TABLE user_preference ALTER COLUMN timesheetframe SET NOT NULL;
    END IF;
END $$;

COMMIT;
