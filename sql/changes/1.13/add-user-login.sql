
create table session_history (
  session_id         int primary key,
  users_id           int not null references users(id),
  created            timestamp without time zone not null default current_timestamp,
  last_used          timestamp without time zone,
  ended              timestamp without time zone,
  termination_reason text -- 'logout' / 'expired'
);

comment on table session_history is $$
  Records which sessions are created for which users at which time and
  when the session was terminated. Additionally, the meaning of the ending
  time of the session is recorded (expired / logged out).

  This table is for audit purposes.
  $$;

comment on column session_history.session_id is $$
  The ID of the session to which this history record belongs.

  Note that after the primary session is terminated / expired,
  there is no session record with this id.
  $$;

comment on column session_history.users_id is $$
  The user to which this session belongs/belonged.
  $$;

comment on column session_history.created is $$
  The timestamp in UTC of the point at which the session was created.
  $$;

comment on column session_history.last_used is $$
  The timestamp in UTC of the point at which the associated session was last used.
  $$;

comment on column session_history.ended is $$
  The timestamp in UTC of the point at which the session was removed.

  Note that removal may not coincide with last use when the session expired.
  $$;

comment on column session_history.termination_reason is $$
  The reason the session ended; this can either be 'expired' or 'logout'.

  The value 'expired' means that the session was not properly ended, but was
  removed after the configured validity period expired.

  The value 'logout' means that the session was removed after proper termination.
  $$;
