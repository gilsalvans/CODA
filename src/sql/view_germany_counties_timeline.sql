create or replace view germany_counties_timeline as
	select
	*
	from
	(select distinct on ("Landkreis", "Meldedatum")
	"Landkreis" as area,
	"SummeFall",
	"SummeTodesfall",
	"SummeGenesen",
	"Meldedatum"
	from
	covid19_germany as cg
	--order by "Meldedatum" desc
	order by area, "Meldedatum" desc nulls last, insertion_date::date desc nulls last) as c
	order by c."Meldedatum"