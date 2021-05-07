create or replace view telegram_austria as
select
ca."Time",
ag.name,
ca."SiebenTageInzidenzFaelle",
ca."AnzahlFaelleSum",
ca."AnzahlTotSum"
from
(select distinct on ("GKZ")
*
from
covid19_austria as ca
order by "GKZ", to_date("Time", 'dd.mm.YYYY') desc, insertion_date desc) as ca
join
austria_geoms as ag
on
ca."GKZ" = ag.id::integer
order by
ag.name