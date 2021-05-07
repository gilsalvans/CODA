create or replace view germany_states_timeline as
	select
	*
	from
	(select distinct on ("Bundesland", "Meldedatum")
	"Bundesland" as area,
	sum("SummeFall") as "SummeFall",
	sum("SummeTodesfall") as "SummeTodesfall",
	sum("SummeGenesen") as "SummeGenesen",
	"Meldedatum"
	from
	covid19_germany as cg
	group by "Bundesland", "Meldedatum", insertion_date
	--order by "Meldedatum" desc
	order by area, "Meldedatum" desc nulls last, insertion_date::date desc nulls last) as c
	order by c."Meldedatum"