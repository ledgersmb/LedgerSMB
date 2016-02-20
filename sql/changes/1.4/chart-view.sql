
CREATE OR REPLACE VIEW chart AS
SELECT ah.id, ah.accno, coalesce(ht.description, ah.description) as description,
       'H' as charttype, NULL as category, NULL as link,
       ah.parent_id as account_heading,
       null as gifi_accno, false as contra,
       false as tax
  from account_heading ah
  LEFT JOIN (SELECT ht.trans_id, ht.description FROM account_heading_translation ht
                                    INNER JOIN user_preference up ON
                                          up.language = ht.language_code
                                    INNER JOIN users ON up.id = users.id
                                    WHERE users.username = SESSION_USER) ht
         ON ah.id = ht.trans_id
UNION
select c.id, c.accno, coalesce(at.description, c.description),
       'A' as charttype, c.category, concat_colon(l.description) as link,
       heading, gifi_accno, contra,
       tax
  from account c
  left join account_link l
    ON (c.id = l.account_id)
  LEFT JOIN (SELECT at.trans_id, at.description FROM account_translation at
                                    INNER JOIN user_preference up ON
                                          up.language = at.language_code
                                    INNER JOIN users ON up.id = users.id
                                    WHERE users.username = SESSION_USER) at
         ON c.id = at.trans_id
group by c.id, c.accno, coalesce(at.description, c.description), c.category,
         c.heading, c.gifi_accno, c.contra, c.tax;

