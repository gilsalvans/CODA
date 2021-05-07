--creates a timeline view for cases in spain to use as a WFS
create or replace view spain_timeline as
	select distinct on (date)
	cs."Updated"::date as date,
	cs.insertion_date,
	cs."Confirmed",
	cs."ConfirmedChange",
	cs."Deaths",
	cs."DeathsChange",
	cs."Recovered",
	cs."RecoveredChange",
	'Spain' as "AdminRegion1"
	from
	covid19_spain as cs
	where "AdminRegion1" = ''
	order by date asc, insertion_date desc nulls last