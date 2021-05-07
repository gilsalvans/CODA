create or replace view germany_timeline as
	select
	*
	from
	(select distinct on (insertion_date::date, "Meldedatum")
	--insertion_date,
	'Deutschland' as "area",
	sum("SummeFall") as "SummeFall",
	sum("SummeTodesfall") as "SummeTodesfall",
	sum("SummeGenesen") as "SummeGenesen",
	"Meldedatum"
	from
	covid19_germany as cg
	group by insertion_date, "Meldedatum"
	order by "Meldedatum" desc nulls last, insertion_date::date desc nulls last) as c
	order by c."Meldedatum"