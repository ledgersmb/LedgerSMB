
alter table payment add column reversing int;

comment on column payment.reversing is
$$Indicates which payment.id the current record is reversing
(or null if the current record isn''t a reversal)$$;

-- sparse uniqueness constraint with (fast) hash lookup
alter table payment
     add constraint double_reverse
           exclude (reversing with =)
                   where (reversing is not null);

