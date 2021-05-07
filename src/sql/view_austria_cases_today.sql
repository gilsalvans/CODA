--creates a view for today's cases on a district level for austria to use as a WFS
create or replace view austria_cases_today as
	select
	ag.name,
	ag.geom,
	ca.*
	from
	(select distinct on (ca."GKZ")
	 ca."GKZ" as gkz,
	 ca."Time",
	 ca."AnzahlFaelle",
	 ca."AnzahlFaelle7Tage",
	 replace(ca."SiebenTageInzidenzFaelle", ',', '.')::numeric as "SiebenTageInzidenzFaelle",
	 ca."AnzahlTotSum",
	 ca."AnzahlGeheiltSum",
	 ca.insertion_date
	 from
	 covid19_austria as ca
	 order by ca."GKZ", to_date(ca."Time", 'dd.mm.YYYY') desc nulls last) as ca
	join
	austria_geoms as ag on ca.gkz = ag.id::integer