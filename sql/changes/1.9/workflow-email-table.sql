
create table email (
   workflow_id int primary key references workflow(workflow_id),
   "from" text,
   "to" text,
   "cc" text,
   "bcc" text,
   "notify" boolean default false,
   subject text,
   body text,
   sent_date date
   );

insert into file_class values (8, 'e-mail');

CREATE TABLE file_email (
       check (file_class=8),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) references email(workflow_id) on delete cascade
) inherits (file_base);
