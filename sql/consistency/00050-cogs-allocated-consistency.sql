--- yaml frontmatter
title: Number of allocated purchased and sold items in COGS calculation are equal
description: |
  When calculating Cost of Goods Sold (COGS), parts are tracked for having COGS
  applied (sold parts) or having been used (purchased parts). The number of parts
  which had COGS applied must be the same as the number of parts used in COGS
  calculations.
---


WITH allocated_balances AS (
   SELECT parts_id,
          -1*sum(case when qty<0 then allocated else 0 end) as allocated_purchased,
          sum(case when qty>0 then allocated else 0 end) as allocated_sold
     FROM invoice i
          JOIN transactions t
               ON i.trans_id = t.id
    WHERE t.approved
   GROUP BY parts_id
)
SELECT *
  FROM allocated_balances
 WHERE allocated_purchased <> allocated_sold
