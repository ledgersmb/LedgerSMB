
CREATE TABLE workflow (
  workflow_id       int not null,
  type              varchar(50) not null,
  state             varchar(30) not null,
  last_update       timestamp without time zone default current_timestamp,
  primary key ( workflow_id )
);

CREATE SEQUENCE workflow_seq;

CREATE TABLE workflow_history (
  workflow_hist_id  int not null,
  workflow_id       int not null,
  action            varchar(25) not null,
  description       varchar(255) null,
  state             varchar(30) not null,
  workflow_user     varchar(50) null,
  history_date      timestamp without time zone default current_timestamp,
  primary key( workflow_hist_id ),
  foreign key( workflow_id ) references workflow( workflow_id )
);

CREATE SEQUENCE workflow_history_seq;
