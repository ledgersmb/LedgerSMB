--- yaml frontmatter
title: Users exist as postgresql roles
description: |
  Users must map to PostgreSQL roles for authentication and authorization purposes
---

SELECT *
  FROM users u
 WHERE NOT EXISTS (SELECT 1
                     FROM pg_roles
                    WHERE rolname = u.username)
