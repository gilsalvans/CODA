--creates a timeline view for cases on a district level for austria to use as a WFS
create or replace view austria_gkz_timeline as
 SELECT distinct on ("Time", "GKZ")
  ca."Time",
  insertion_date,
    ca."GKZ",
    ca."AnzahlFaelleSum",
    ca."AnzahlTotSum",
    ca."AnzahlGeheiltSum",
    ca.diff
   FROM ( SELECT gkz."Time",
      insertion_date,
            gkz."GKZ",
            gkz."AnzahlFaelleSum",
            gkz."AnzahlTotSum",
            gkz."AnzahlGeheiltSum",
            gkz."AnzahlFaelleSum" - lag(gkz."AnzahlFaelleSum") OVER diff_window AS diff
           FROM ( SELECT
          to_date(covid19_austria."Time", 'dd.mm.YYYY'::text) AS "Time",
          insertion_date,
                    covid19_austria."GKZ",
                    sum(covid19_austria."AnzahlFaelleSum") AS "AnzahlFaelleSum",
                    sum(covid19_austria."AnzahlTotSum") AS "AnzahlTotSum",
                    sum(covid19_austria."AnzahlGeheiltSum") AS "AnzahlGeheiltSum"
                   FROM covid19_austria
                  GROUP BY covid19_austria."Time", covid19_austria.insertion_date, covid19_austria."GKZ"
                  ORDER BY (to_date(covid19_austria."Time", 'dd.mm.YYYY'::text)), "GKZ") gkz
          WINDOW diff_window AS (PARTITION BY gkz."GKZ" ORDER BY gkz."GKZ", gkz."Time")) ca
  WHERE ca.diff >= 0 OR ca.diff IS NULL
  order by "GKZ", "Time", insertion_date desc nulls last;