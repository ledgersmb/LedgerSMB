

ALTER TABLE IF EXISTS ONLY public.note
    ADD CHECK (false) NO INHERIT;

ALTER TABLE IF EXISTS ONLY public.file_base
    ADD CHECK (false) NO INHERIT;

ALTER TABLE IF EXISTS ONLY public.file_secondary_attachment
    ADD CHECK (false) NO INHERIT;
