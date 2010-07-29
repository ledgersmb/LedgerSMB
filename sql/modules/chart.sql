-- TODO:  Merge with account.sql -CT

CREATE TYPE trial_balance_line AS (
	chart_id int,
	accno text,
	description text,
	beginning_balance numeric,
	credits numeric,
	debits numeric,
	ending_balance numeric
);

CREATE OR REPLACE FUNCTION report_trial_balance
(in_datefrom date, in_dateto date, in_department_id int, in_project_id int, 
in_gifi bool)
RETURNS setof trial_balance_line
AS $$
DECLARE out_row trial_balance_line;
BEGIN
	IF in_department_id IS NULL THEN
		FOR out_row IN
			SELECT c.id, c.accno, c.description, 
				SUM(CASE WHEN ac.transdate < in_datefrom 
				              AND c.category IN ('I', 'L', 'Q')
				    THEN ac.amount
				    ELSE ac.amount * -1
				    END), 
			        SUM(CASE WHEN ac.transdate >= in_date_from 
				              AND ac.amount > 0 
			            THEN ac.amount
			            ELSE 0 END),
			        SUM(CASE WHEN ac.transdate >= in_date_from 
				              AND ac.amount < 0
			            THEN ac.amount
			            ELSE 0 END) * -1,
				SUM(CASE WHEN ac.transdate >= in_date_from
					AND c.charttype IN ('I')
				    THEN ac.amount
				    WHEN ac.transdate >= in_date_from
				              AND c.category IN ('I', 'L', 'Q')
				    THEN ac.amount
				    ELSE ac.amount * -1
				    END)
				FROM acc_trans ac
				JOIN (select id, approved FROM ap
					UNION ALL 
					select id, approved FROM gl
					UNION ALL
					select id, approved FROM ar) g
					ON (g.id = ac.trans_id)
				JOIN chart c ON (c.id = ac.chart_id)
				WHERE ac.transdate <= in_date_to
					AND ac.approved AND g.approved
					AND (in_project_id IS NULL 
						OR in_project_id = ac.project_id)
				GROUP BY c.id, c.accno, c.description
				ORDER BY c.accno
				
		LOOP
			RETURN NEXT out_row;
		END LOOP;
	ELSE 
		FOR out_row IN
			SELECT 1
		LOOP
			RETURN NEXT out_row;
		END LOOP;
	END IF;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION chart_list_all()
RETURNS SETOF chart AS
$$
DECLARE out_row chart%ROWTYPE;
BEGIN
	FOR out_row IN 
		SELECT * FROM chart ORDER BY accno
	LOOP
		RETURN next out_row;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION chart_get_ar_ap(in_account_class int)
RETURNS SETOF chart AS
$$
DECLARE out_row chart%ROWTYPE;
BEGIN
	IF in_account_class NOT IN (1, 2) THEN
		RAISE EXCEPTION 'Bad Account Type';
	END IF;
       FOR out_row IN
               SELECT * FROM chart 
               WHERE link = CASE WHEN in_account_class = 1 THEN 'AP'
                               WHEN in_account_class = 2 THEN 'AR'
                               END
               ORDER BY accno
       LOOP
               RETURN NEXT out_row;
       END LOOP;
END;
$$ LANGUAGE PLPGSQL;
COMMENT ON FUNCTION chart_get_ar_ap(in_account_class int) IS
$$ This function returns the cash account acording with in_account_class which must be 1 or 2 $$;

CREATE OR REPLACE FUNCTION chart_list_search(search text, link_desc text)
RETURNS SETOF account AS
$$
DECLARE out_row account%ROWTYPE;
BEGIN
	FOR out_row IN 
		SELECT * FROM account 
                 WHERE (accno ~* ('^'||search) 
                       OR description ~* ('^'||search))
                       AND (link_desc IS NULL 
                           or id in 
                          (select account_id from account_link 
                            where description = link_desc))
              ORDER BY accno
	LOOP
		RETURN next out_row;
	END LOOP;
END;$$
LANGUAGE 'plpgsql';
							

CREATE OR REPLACE FUNCTION chart_list_overpayment(in_account_class int)
RETURNS SETOF chart AS
$$
DECLARE resultrow record;
        link_string text;
BEGIN
        IF in_account_class = 1 THEN
           link_string := '%AP_overpayment%';
        ELSE 
           link_string := '%AR_overpayment%';
        END IF;

        FOR resultrow IN
          SELECT *  FROM chart
          WHERE link LIKE link_string
          ORDER BY accno
          LOOP
          return next resultrow;
        END LOOP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION chart_list_cash(in_account_class int)
returns setof chart
as $$
 DECLARE resultrow record;
         link_string text;
 BEGIN
         IF in_account_class = 1 THEN
            link_string := '%AP_paid%';
         ELSE 
            link_string := '%AR_paid%';
         END IF;
 
         FOR resultrow IN
           SELECT *  FROM chart
           WHERE link LIKE link_string
           ORDER BY accno
           LOOP
           return next resultrow;
         END LOOP;
 END;
$$ language plpgsql;
COMMENT ON FUNCTION chart_list_cash(in_account_class int) IS
$$ This function returns the overpayment accounts acording with in_account_class which must be 1 or 2 $$;

CREATE OR REPLACE FUNCTION chart_list_discount(in_account_class int)
RETURNS SETOF chart AS
$$
DECLARE resultrow record;
        link_string text;
BEGIN
        IF in_account_class = 1 THEN
           link_string := '%AP_discount%';
        ELSE
           link_string := '%AR_discount%';
        END IF;

        FOR resultrow IN
          SELECT *  FROM chart
          WHERE link LIKE link_string
          ORDER BY accno
          LOOP
          return next resultrow;
        END LOOP;
END;
$$ language plpgsql;

COMMENT ON FUNCTION chart_list_discount(in_account_class int) IS
$$ This function returns the discount accounts acording with in_account_class which must be 1 or 2 $$;
