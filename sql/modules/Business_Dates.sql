
-- Copyright (C) 2012, the LedgerSMB Core Team.  This file may be re-used under
-- the GNU GPL version 2 or at your option any future version.  Please see the
-- accompanying LICENSE file for details.

begin;

--
-- Content
--
--  * Business day conventions
--  * Day count conventions
--  * Recurrence patterns
--


--
-- Business day conventions
--
--



create or replace
function lsmb__is_workday(in_date date, in_calendar integer)
returns boolean
language sql
as $$
   select extract(isodow from $1) <= 5;
$$;


create table holidays (
  calendar integer,
  holidate date,
  primary key (calendar, holidate)
);


create or replace
function lsmb__is_holiday(in_date date, in_calendar integer)
returns boolean
language plpgsql
as $$
begin
  if exists(select *
              from holidays
             where holidate = in_date
               and calendar = in_calendar) then
    return true;
  else
    return false;
  end if;
end;
$$;

create or replace
function lsmb__next_business_day(in_date date, in_calendar integer,
                                 in_direction integer)
returns date
language plpgsql
as $$
declare
  t_date date;
begin
  t_date := in_date;
  loop
    exit when lsmb__is_workday(t_date, in_calendar)
          and (not lsmb__is_holiday(t_date, in_calendar));

    t_date := t_date + in_direction;
  end loop;
  return t_date;
end;
$$;

create or replace
function lsmb__next_business_day_modified(in_date date, in_calendar integer,
                                          in_direction integer)
returns date
language plpgsql
as $$
declare
  t_date date;
begin
  t_date := lsmb__next_business_day(in_date, in_calendar, in_direction);

  if extract(month from in_date) != extract(month from t_date) then
    t_date := lsmb__next_business_day(in_date, in_calendar, -1 * in_direction);
  end if;

  return t_date;
end;
$$;


create or replace
function lsmb__closest_business_day(in_date date, in_calendar integer,
                                    in_type integer)
returns date
language plpgsql
as $$
declare
  t_date date;
begin
  if in_type = 1 then -- no adjustment
    t_date := in_date;
  elseif in_type = 2 then -- following
    t_date := lsmb__next_business_day(in_date, in_calendar, 1);
  elseif in_type = 3 then -- modified following
    t_date := lsmb__next_business_day_modified(in_date, in_calendar, 1);
  elseif in_type = 4 then -- previous
    t_date := lsmb__next_businss_day(in_date, in_calendar, -1);
  elseif in_type = 5 then -- modified previous
    t_date := lsmb__next_business_day_modified(in_date, in_calendar, -1);
  else
    raise exception 'Unknown business day convention (%)', in_type;
  end if;

  return t_date;
end;
$$;

--
--    Day count conventions
--
--

-- Calculations implemented as described
--    on http://en.wikipedia.org/wiki/Day_count_convention
--  Algorithms written to allow multi-year time spans


-- Definitions
--
--  Start date: start of the day-counting period (exclusive)
--      Presumably, this is the last invoicing date
--  End date: end date of the day-counting period (inclusive)
--  Coupon date: coupon or invoice date
--  Maturity date: end date of the contract

create or replace
function lsmb__daycount_30e_360(in_start_date, in_end_date)
returns number
language plpgsql
as $$
declare
  d1, d2 integer;
  m1, m2 integer;
  y1, y2 integer;
begin
   y1 := extract(YEAR  from in_start_date);
   m1 := extract(MONTH from in_start_date);
   d1 := extract(DAY   from in_start_date);

   y2 := extract(YEAR from in_end_date);
   m2 := extract(YEAR from in_end_date);
   d2 := extract(YEAR from in_end_date);

   if d1 = 31 then
     d1 := 30;
   end if

   if d2 = 31 then
     d2 := 30;
   end if

   return ((y2 - y1) * 360 + (m2 - m1) * 30 + (d2 - d1)) / 360
$$;

create or replace
function lsmb__daycount_30e_360_isda(in_start date, in_end date,
                                     in_maturity date)
returns number
language plpgsql
as $$
declare
  d1, d2 integer;
  m1, m2 integer;
  y1, y2 integer;
  t_date date;
begin
   y1 := extract(YEAR  from in_start_date);
   m1 := extract(MONTH from in_start_date);
   d1 := extract(DAY   from in_start_date);

   y2 := extract(YEAR from in_end_date);
   m2 := extract(YEAR from in_end_date);
   d2 := extract(YEAR from in_end_date);

   if extract(MONTH from in_start) <> extract(MONTH from (in_start+1)) then
     d1 := 30;
   end if

   if in_end <> in_maturity
      AND extract(MONTH from in_end) <> extract(MONTH from (in_end+1)) then
     d2 := 30;
   end if

   return ((y2 - y1) * 360 + (m2 - m1) * 30 + (d2 - d1)) / 360
$$;


create or replace
function lsmb__daycount_act_act_isda(in_start date, in_end date)
returns number
language plpgsql
as $$
declare
  t_start date;
  t_end date;
  t_factor number;
  t_denom integer;
begin
  t_start := in_start;
  t_end := min(in_end, (extract(YEAR from t_start) || '-12-31')::date);

  loop
    if is_leapyear(t_end) then
      t_denom := 366;
    else
      t_denom := 365;
    end if;

    t_factor := t_factor + (t_end - t_start) / t_denom;
    t_start := t_end;
    t_end := min(in_end, t_end + '1 year'::interval);

    exit when t_start = in_end;
  end loop;

  return t_factor;
end;
$$;

create or replace
function lsmb__daycount_act_365fixed(in_start date, in_end date)
returns number
language sql
as $$
  select (in_end - in_start) / 365;
$$;

create or replace
function lsmb__daycount_act_360(in_start date, in_end date)
returns number
language sql
as $$
  select (in_end - in_start) / 360;
$$;

create or replace
function lsmb__daycount_act_364(in_start date, in_end date)
returns number
language sql
as $$
  select (in_end - in_start) / 364;
$$;


-- can't implement Actual/Actual (icma), because it requires
-- knowing the couponing dates up to and including the first couponing
-- date beyond in_end, as well as the couponing frequency


create or replace
function lsmb__daycount_factor(in_name text, in_start date, in_end date,
                               in_maturity date)
returns number
language plpgsql
as $$
begin
  if in_name = '30e/360' then
    return lsmb__daycount_30e_360(in_start, in_end);
  elseif in_name = '30e/360 (isda)' then
    return lsmb__daycount_30e_360_isda(in_start, in_end, in_maturity);
  elseif in_name = 'act/act (isda)' then
    return lsmb__daycount_act_act_isda(in_start, in_end);
  elseif in_name = 'act/365 fixed' then
    return lsmb__daycount_act_365(in_start, in_end);
  elseif in_name = 'act/360' then
    return lsmb__daycount_act_360(in_start, in_end);
  elseif in_name = 'act/364' then
    return lsmb__daycount_act_364(in_start, in_end);
  else
    raise exception 'Unknown day count convention (%)', in_name;
  end if
end;
$$;

comment on function lsmb__daycount_factor(in_name text, in_start date,
                                          in_end date, in_maturity date) IS
$$This function returns the factor designating the weight of the days
between in_start (exclusive) and in_end (inclusive) using the day weighting
procedure indicated by in_name. A full year may end up with a weight
higher than 1 in all cases marked with '[*]' below.

The argument in_name can be any of these values:

 * '30e/360'
 * '30e/360 (isda)'
 * 'act/act (isda)'
(* 'act/act (icma)' not implemented through this interface)
 * 'act/365 fixed' [*]
 * 'act/360'       [*]
 * 'act/364'       [*]

The in_maturity argument designates the end of the contract period
and is used in case of '30e/360 (isda)' only.
$$;


--
--    Recurrence patterns
--
--


create or replace
function lsmb__next_interval_date(in_start_date date, in_repeat integer,
                                  in_interval interval, in_eom boolean)
returns date
language plpgsql
as $$
declare
  t_end_date date;
begin
  select in_start_date + in_repeat * in_interval into t_end_date;

  if in_eom then
    select date_trunc('month', t_end_date)
           + '1 month'::interval - '1 day'::interval
      into t_end_date;
  end if

  return t_end_date;
end;
$$;

update defaults set value = 'yes' where setting_key = 'module_load_ok';



commit;
