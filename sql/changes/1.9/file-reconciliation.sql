
insert into file_class values (9, 'reconciliation');

CREATE TABLE file_reconciliation (
       check (file_class=9),
       unique(id),
       primary key (ref_key, file_name, file_class),
       foreign key (ref_key) references cr_report(id) on delete cascade
) inherits (file_base);
