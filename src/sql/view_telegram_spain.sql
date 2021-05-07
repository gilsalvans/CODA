create or replace view telegram_spain as
select distinct on ("AdminRegion1")
"Updated",
"Confirmed",
"Deaths",
"AdminRegion1"
from
covid19_spain
order by
"AdminRegion1", to_date("Updated", 'mm/dd/YYYY') desc nulls last, to_date(insertion_date, 'YYYY-mm-dd') desc nulls last