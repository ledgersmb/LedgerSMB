ALTER TABLE template
  ADD COLUMN last_modified TIMESTAMP WITH TIME ZONE
     NOT NULL DEFAULT now(); -- initializes existing rows with now()

