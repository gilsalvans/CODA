--creates a timeline view for cases in spain cumindad autonoma to use as a WFS
create or replace view spain_comunidad_autonoma_timeline as
	select distinct on (date, "AdminRegion1")
	cs."Updated"::date as date,
	cs.insertion_date,
	cs."Confirmed",
	cs."ConfirmedChange",
	cs."Deaths",
	cs."DeathsChange",
	cs."Recovered",
	cs."RecoveredChange",
	cs."AdminRegion1"
	from
	covid19_spain as cs
	where "AdminRegion1" != ''
	order by "AdminRegion1", date, insertion_date desc nulls last