# 0105 Role based access design for in-database stored files

Date: 2025-01-11

## Status

Draft

## Context

LedgerSMB has a facility for "attaching" files to various types of data.
Examples include transactions, e-mails and orders. The content of these files
is stored in a single table `file_content`. The content is then linked to the
various data types using `file_*_links` tables. Users may be assigned
roles to see specific parts of the system (while being excluded from access
to others), meaning that users may have access to *some* `file_*_links` tables
but not to others. Some records in `file_content` may be linked exclusively to
records in `file_*_links` tables to which the user has no access. In that case,
the user should not be able to retrieve the content of the stored files.
Similarly, should the user not be able to save files into `file_content` which
then becomes available to users who do not share access rights with the user
who inserted the data.

For the purpose of this discussion, lets assume a simple setup with 3 tables:

* `file_email_links` - used to attach files to e-mails
* `file_order_links` - used to attach files to orders
* `file_content` - used to store the content of the actual files

As described above, some users have access to `file_email_links` and others
have access to `file_order_links`. Role assignment provides users with read
or write access to the entire `file_*_links` tables.

### How to do role-based access on `file_content`?

Providing access to the entire `file_content` table isn't possible, because
that would give 'e-mail users' access to the order-linked files. The problem
then becomes how to set up access where some rows are accessible and others
are not. So far, we see the following options:

1. [Row-level
   security](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
   policies on the `file_content` table
2. Access granted on views providing restricted `file_content` access
3. Access granted on stored functions providing restricted `file_content` access


#### Ad 1. Row level security (RLS) on `file_content`

In this design, [*row security
policy*](https://www.postgresql.org/docs/current/sql-createpolicy.html)
(or group of policies) is set on the `file_content` table, restricting read
permission to rows in line with the roles assigned to the querying user. In
case of the example above, the security policy needs to allow users with
`email_read` access read rights:

  CREATE POLICY email_read ON file_content
    FOR SELECT
    TO lsmb_email_read
    USING (exists (select 1 from file_email_links fel where fel.content_id = id));

And with `order_read`:

  CREATE POLICY order_read ON file_content
    FOR SELECT
    TO lsmb_order_read
    USING (exists (select 1 from file_order_links fol where fol.content_id = id));


In this design, a policy needs to be set on `file_content` for each table which
refers to file content. In the actual schema this means 10 policies at the
moment of writing.

As demonstrated, RLS can address the concern of read access. For write access,
a `WITH CHECK` component can be used. For the problem at hand, that's not a
solution: with it, the user will be able to insert new file content. This is not
sufficient, because the `file_content` table is also about transparently
deduplicating file storage. A regular INSERT won't work to do the deduplication.

A stored function can be used to solve the deduplication: by creating the
`file__store()` function which runs with administrator rights (achieved by
SECURITY DEFINER), deduplicating on the actual file content, returning an
existing row that the current user does not have access to. However, a user
could insert a record into a `file_*_links` table in which (s)he has write
access with a guessed ID of a file. This would unlock the associated row
in the `file_content` table, allowing the user to read content of a file to
which he shouldn't based on his roles.

Other considerations:
* This design does not integrate with PGObject (LedgerSMB's database
  mapper), which depends on stored functions
* This design is the first to use row level policies; no Roles.sql facilities
  are in place for their creation

In summary: this design directly allows read access to the file content,
putting on the user to join with the metadata tables per attachment type,
making retrieval of the file content explicit, reducing the risk of
unintentional large data transfers. This pattern adds 1 additional schema
object.

#### Ad 2. Restricted views on `file_content`

In this design, a view will be created for each type of file attachment. In
case of the example, this means creation of 2 views:

* `file_email` - joining `file_email_links` and `file_content`
* `file_order` - joining `file_order_links` and `file_content`

Access to the `file_content` table will be locked down. The views will be
owned by a super user, allowing to query the locked down `file_content` table
and granted SELECT rights to the `lsmb_email_read` and `lsmb_order_read` groups
respectively.

In this design, users can query specialized views per attachment type. Assuming
code is specifically loading an order or an e-mail, this does seem to be very
restrictive. However, in the actual schema, this adds 10 *additional* schema
objects, one for each attachment type, just for reading the attachments.

Inserting new file content can be done transparently using an `INSTEAD DO`
trigger on the view where an `INSERT` is captured and split over the two
underlying tables by a trigger which runs with administrator privileges.
This will add another 10 additional schema objects. By going through the
triggers for write access, this design allows the `file_*_links` tables to
be locked down, preventing the attack vector identified in design (1).

Other considerations:
* This design does not integrate with PGObject (LedgerSMB's database
  mapper), which depends on stored functions
* This design uses database objects facilitated by Roles.sql without
  modification

In summary: this design funnels all access through a transparent view per
type of attachment. These views include retrieval of the file content if
not handled carefully, leading to potentially large data transfers. This
design adds 20 additional schema objects (but the user only uses 10; the
rest being triggers).

#### Ad 3. Stored functions restricting access on `file_content`

In this design, a stored procedure is created for retrieval of each type
of file attachment, similar to design (2). Additionally, for the insertion
of new attachments, 10 additional stored procedures will be created, adding
data to the `file_*_links` tables as well as the `file_content` table in a
single function call.

Access to these functions will be granted to the `email_read` and `order_read`
roles (for read access) respectively using the EXECUTE permission; the
functions run as SECURITY DEFINER, giving them access to the locked down
`file_content` table. This design - similar to design (2) - prevents the
leak identified under design (1).

Other considerations:
* This design integrates well with PGObject (LedgerSMB's database
  mapper), because it provides the required stored functions
* This design uses database objects facilitated by Roles.sql without
  modification

In summary: this design funnels all access through stored functions with
specific ones for read and write access for each type of attachment. It
adds 20 additional schema objects, all of which will need to be used by the
user.

### Related ADRs

* [0002 Ensure database consistency through
  procedural API](./0002-database-consistency-procedural-api.md)
* [0005 Business logic in database and UI
  in Perl](./0005-business-logic-in-database-and-UI-in-Perl.md)

## Decision

The decision balances between security, simplicity and consistency (with
the existing schema). The table below summarizes the designs.

| Design     | Security | Simplicity | Consistency | ADR 0002 | Score |
|:----------:|:--------:|:----------:|:-----------:|:--------:|:-----:|
| importance | 3        | 2          | 1           | 1        |       |
|:----------:|:--------:|:----------:|:-----------:|:--------:|:-----:|
| 1          | - [^1]   | ++         | -           | -        | -3    |
| 2          | ++[^2]   | -          | +  [^3]     | -        | 4     |
| 3          | ++[^2]   | --         | ++ [^4]     | +        | 5     |

Column scores:

* '--' = -2
* '-' = -1
* '+' = 1
* '++' = 2

[^1]: Security is not strict; by guessing the right UUID (*very* hard),
      data *can* be disclosed from the `file_content` table.
[^2]: Security is strict; no data can be accessed without the right roles
[^3]: Compatible with `Roles.sql`, but not with `PGObject`
[^4]: Compatible with both `Roles.sql` and `PGObject`


Simplicity is rated lower for design (3), because both add 20 schema objects,
but only 10 schema objects require interaction for design (2), while all 20
require interaction for design (3).

Looking at the scores in the table, Design 3 is the preferred design. Although
Design 1 is a lot simpler (adds only few schema objects), it's not rated high
enough on security to outperform the others.


## Consequences


## Annotations

