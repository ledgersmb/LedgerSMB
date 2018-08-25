
CREATE TABLE currency (
  curr char(3) primary key,
  description text
);

COMMENT ON TABLE currency IS
$$This table holds the list of currencies available for posting in the system;
it mostly serves as the canonical definition of currency codes.$$;


CREATE TABLE exchangerate_type (
  id serial primary key,
  description text,
  builtin boolean
);

INSERT INTO exchangerate_type (id, description, builtin)
     VALUES (1, 'Default rate', 't');

SELECT setval('exchangerate_type_id_seq', 1, 't');

COMMENT ON TABLE exchangerate_type IS
$$This table defines various types of exchange rates which may be used for
different purposes (posting, valuation, translation, ...).$$;

COMMENT ON COLUMN exchangerate_type.builtin IS
$$This column is 't' (true) in case the record is a built-in value
(and thus can''t be deleted).$$;

CREATE TABLE exchangerate_default (
  rate_type int not null references exchangerate_type(id),
  curr char(3) not null references currency(curr),
  valid_from date not null,
  valid_to timestamp default 'infinity'::timestamp,
  rate numeric,
  PRIMARY KEY (rate_type, curr, valid_from)
);

COMMENT ON TABLE exchangerate_default IS
$$This table contains applicable rates for various rate types in the
indicated interval [valid_from, valid_to].

### NOTE: This table needs an INSERT trigger to update any 'valid_to'
'infinity' values to ensure non-overlapping records.
$$;

