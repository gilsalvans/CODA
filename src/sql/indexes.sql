--creates indexes on the following tables
--AUSTRIA
create index covid19_austria_gkz_btree_index on covid19_austria using btree ("GKZ");
create index covid19_austria_time_btree_index on covid19_austria using btree ("Time");
create index covid19_austria_insertion_date_btree_index on covid19_austria using btree (insertion_date);

create index austria_geoms_id_btree_index on austria_geoms using btree (id);
create index austria_geoms_geom_gist_index on austria_geoms using gist (geom);

--GERMANY
create index covid19_germany_landkreis_btree_index on covid19_germany using btree ("Landkreis");
create index covid19_germany_meldedatum_btree_index on covid19_germany using btree ("Meldedatum");
create index covid19_germany_insertion_date_btree_index on covid19_germany using btree (insertion_date);
create index covid19_germany_bundesland_btree_index on covid19_germany using btree ("Bundesland");

create index inzidenzen_germany_county_btree_index on inzidenzen_germany using btree (county);
create index inzidenzen_germany_nuts_btree_index on inzidenzen_germany using btree ("NUTS");
create index inzidenzen_germany_last_update_bree_index on inzidenzen_germany using btree (last_update);
create index inzidenzen_germany_insertion_date_btree_index on inzidenzen_germany using btree (insertion_date);

create index germany_geoms_nuts_code_btree_index on germany_geoms using btree (nuts_code);
create index germany_geoms_geom_gist_index on germany_geoms using gist (geom);
--SPAIN
create index covid19_spain_adminregion1_btree_index on covid19_spain using btree ("AdminRegion1");
create index covid19_spain_updated_btree_index on covid19_spain using btree ("Updated");
create index covid19_spain_insertion_date_btree_index on covid19_spain using btree (insertion_date);

create index spain_geoms_geom_gist_index on spain_geoms using gist (geom);
--create index spain_center_gist_index on covid19_spain using gist (ST_GeomFromText('POINT (' || "Longitude" || ' ' || "Latitude" || ')', 4326), 3857)); --THIS IS NOT WORKING