
ALTER TABLE public.note 
    ADD CHECK (false) NO INHERIT NOT VALID;

ALTER TABLE public.file_base 
    ADD CHECK (false) NO INHERIT NOT VALID;

ALTER TABLE public.file_secondary_attachment 
    ADD CHECK (false) NO INHERIT NOT VALID;

