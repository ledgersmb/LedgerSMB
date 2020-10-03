

insert into sic (code, description)
select sic_code, sic_code from company
 where not exists (select 1 from sic where sic.code = company.sic_code);

alter table company
  add constraint company_sic_code_fkey
      foreign key (sic_code) references sic (code);
