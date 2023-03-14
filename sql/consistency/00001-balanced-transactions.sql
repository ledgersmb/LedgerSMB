--- yaml frontmatter
title: All transactions are balanced
---

select trans_id
  from acc_trans
 group by trans_id
  having abs(sum(amount_bc)) >= power(10, -1*coalesce((select value::numeric
                                                        from defaults
                                                       where setting_key = 'decimal_places'),
                                                       2))/2
