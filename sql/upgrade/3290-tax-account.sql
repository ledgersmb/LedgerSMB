
ALTER TABLE account ADD tax bool not null default false;

UPDATE account
   SET tax = true
 WHERE id IN (SELECT account_id
              FROM account_link
              WHERE description LIKE '%_tax'
              UNION
              SELECT chart_id
              FROM tax);


CREATE OR REPLACE FUNCTION account_save
(in_id int, in_accno text, in_description text, in_category char(1),
in_gifi_accno text, in_heading int, in_contra bool, in_tax bool,
in_link text[])
RETURNS int AS $$
DECLARE
        t_heading_id int;
        t_link record;
        t_id int;
BEGIN
        -- check to ensure summary accounts are exclusive
        -- necessary for proper handling by legacy code
    FOR t_link IN SELECT description FROM account_link_description
    WHERE summary='t'
        LOOP
                IF t_link.description = ANY (in_link)
		   and array_upper(in_link, 1) > 1 THEN
                        RAISE EXCEPTION 'Invalid link settings:  Summary';
                END IF;
        END LOOP;
        -- heading settings
        IF in_heading IS NULL THEN
                SELECT id INTO t_heading_id FROM account_heading
                WHERE accno < in_accno order by accno desc limit 1;
        ELSE
                t_heading_id := in_heading;
        END IF;

    -- don't remove custom links.
        DELETE FROM account_link
        WHERE account_id = in_id
              and description in ( select description
                                    from  account_link_description
                                    where custom = 'f');

        UPDATE account
        SET accno = in_accno,
                description = in_description,
                category = in_category,
                gifi_accno = in_gifi_accno,
                heading = t_heading_id,
                contra = in_contra,
                tax = in_tax
        WHERE id = in_id;

        IF FOUND THEN
                t_id := in_id;
        ELSE
                INSERT INTO account (accno, description, category, gifi_accno,
                        heading, contra, tax)
                VALUES (in_accno, in_description, in_category, in_gifi_accno,
                        t_heading_id, in_contra, in_tax);

                t_id := currval('account_id_seq');
        END IF;

        FOR t_link IN
                select in_link[generate_series] AS val
                FROM generate_series(array_lower(in_link, 1),
                        array_upper(in_link, 1))
        LOOP
                INSERT INTO account_link (account_id, description)
                VALUES (t_id, t_link.val);
        END LOOP;


        RETURN t_id;
END;
$$ language plpgsql;


DROP VIEW chart CASCADE;

CREATE OR REPLACE RULE chart_i AS ON INSERT TO chart
DO INSTEAD
SELECT CASE WHEN new.charttype='H' THEN 
 account_heading_save(new.id, new.accno, new.description, NULL)
ELSE
 account_save(new.id, new.accno, new.description, new.category,
  new.gifi_accno, NULL,
  CASE WHEN new.contra IS NULL THEN FALSE ELSE new.contra END,
  CASE WHEN new.tax IS NULL THEN FALSE ELSE new.tax END,
  string_to_array(new.link, ':'))
END;

