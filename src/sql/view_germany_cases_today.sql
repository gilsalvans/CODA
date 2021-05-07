create or replace view germany_cases_today as
	select
	--cg.insertion_date,
	--ig.insertion_date,
	cg."Meldedatum",
	cg."AnzahlFall",
	cg."AnzahlTodesfall",
	cg."SummeFall",
	cg."Bundesland",
	cg."Landkreis",
	cg."AnzahlGenesen",
	cg."SummeGenesen",
	ig."NUTS",
	ig."EWZ",
	ig.death_rate,
	ig.cases_per_100k,
	ig.cases_per_population,
	ig.cases7_per_100k,
	ig."EWZ_BL",
	ig.cases7_bl_per_100k,
	gg.geom
	from
	(select distinct on (cg."Landkreis")
	*
	from
	covid19_germany as cg
	order by cg."Landkreis", cg."Meldedatum" desc nulls last, cg.insertion_date::date desc nulls last) as cg
	inner join
	(select distinct on (ig."NUTS")
	*
	from
	inzidenzen_germany as ig
	order by ig."NUTS", to_date(ig.last_update, 'dd.mm.YYYY') desc nulls last, ig.insertion_date::date desc nulls last) as ig
	on cg."Landkreis" = ig.county
	inner join
	germany_geoms as gg
	on ig."NUTS" = gg.nuts_code