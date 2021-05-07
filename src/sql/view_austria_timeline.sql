--creates a timeline view for cases in austria to use as a WFS
create or replace view austria_timeline as
 SELECT distinct on ("Time")
 	ca."Time",
 	ca.insertion_date,
    ca."Bezirk",
    ca.gkz,
    ca."AnzahlFaelleSum",
    ca."AnzahlTotSum",
    ca."AnzahlGeheiltSum",
    ca.diff
   FROM ( SELECT austria."Time",
		 	austria.insertion_date,
            austria."Bezirk",
            austria.gkz,
            austria."AnzahlFaelleSum",
            austria."AnzahlTotSum",
            austria."AnzahlGeheiltSum",
            austria."AnzahlFaelleSum" - lag(austria."AnzahlFaelleSum") OVER diff_window AS diff
           FROM ( SELECT to_date(covid19_austria."Time", 'dd.mm.YYYY'::text) AS "Time",
				 	insertion_date,
                    'Österreich'::text AS "Bezirk",
                    0 AS gkz,
                    sum(covid19_austria."AnzahlFaelleSum") AS "AnzahlFaelleSum",
                    sum(covid19_austria."AnzahlTotSum") AS "AnzahlTotSum",
                    sum(covid19_austria."AnzahlGeheiltSum") AS "AnzahlGeheiltSum"
                   FROM covid19_austria
                  GROUP BY covid19_austria."Time", covid19_austria.insertion_date
                  ORDER BY (to_date(covid19_austria."Time", 'dd.mm.YYYY'::text))) austria
          WINDOW diff_window AS (PARTITION BY austria.gkz ORDER BY austria."Time")) ca
  WHERE ca.diff >= 0 OR ca.diff IS NULL
  order by "Time" asc, insertion_date::date desc nulls last