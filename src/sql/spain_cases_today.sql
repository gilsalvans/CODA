create or replace view spain_cases_today as
	select distinct on (spain_geoms.nuts_name)
	cs."Updated"::date,
	cs."Confirmed",
	cs."ConfirmedChange",
	cs."Deaths",
	cs."DeathsChange",
	cs."Recovered",
	cs."RecoveredChange",
	((cs."ConfirmedChange"::decimal / spain_geoms.population::decimal) * 100000) as change_per_100k,
	(cs."Confirmed" - cs."Recovered") as current_cases,
	spain_geoms.nuts_name,
	spain_geoms.geom,
	cs."AdminRegion1",
	case when current_date - "Updated"::date > 10 then 'outdated' 
		 when (cs."Confirmed" - cs."Recovered") is null then 'outdated'
		 else 'ok' end
	from
	covid19_spain as cs
	join spain_geoms on ST_Contains(geom, ST_Transform(ST_GeomFromText('POINT (' || cs."Longitude" || ' ' || cs."Latitude" || ')', 4326), 3857))
	where cs."AdminRegion1" != ''
	order by spain_geoms.nuts_name, cs."Updated"::date desc nulls last