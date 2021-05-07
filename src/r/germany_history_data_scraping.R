#library to request data from ArcGIS Server
library("esri2sf")
#libraries to connect to PostgreSQL database and perform operations
require("RPostgreSQL")
require("DBI")

#creates driver-object for PostgreSQL dbms
drv <- dbDriver("PostgreSQL")

#decides machine-depending wich database should be used
#sends e-mail in case none of the machines could be identified
if(Sys.info()[4] == 'DESKTOP-G2TVD6S') {
  #these DB credentials are for testing
  con<-dbConnect(RPostgres::Postgres(),
                 dbname="coda",
                 host="88.99.225.13",
                 port=5432,
                 user="eike",
                 password="eike")
} else if (Sys.info()[4] == 'CF000746') {
  con <- dbConnect(drv, 
                   dbname="covid_dashboard",
                   host="human.zgis.at",
                   port=5432,
                   user="covid_dashboard",
                   password="F7m}=O&]ka%a,NtUU$a>")
}

dbSendQuery(con, "delete from covid19_germany")

esri_request <- function(url, where='1=1', outFields=c('*'), max_tries=3){
  if(max_tries == 0){
    return(NULL)
  }
  left_tries <- max_tries - 1
  tryCatch({
    df <- esri2df(url, where)
    return(df)
  },
  warning = function(war){
    print('warning')
    return(esri_request(url, where, outFields, left_tries))
  },
  error = function(err){
    print('Error')
    return(esri_request(url, where, outFields, left_tries))
  })
}


#GERMANY DATA SCRAPING
before = 1
while (TRUE){
  where_clause = paste0("Meldedatum=timestamp '", Sys.Date() - before, "' AND NOT Bundesland='Berlin'")
  where_berlin = paste0("Meldedatum=timestamp '", Sys.Date() - before, "' AND Bundesland='Berlin'")
  print(paste('Querying data for', Sys.Date() - before))
  data_germany <- esri2df('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/Covid19_RKI_Sums/FeatureServer/0', where=where_clause)
  #data_germany <- esri_request('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/Covid19_RKI_Sums/FeatureServer/0', where=where_clause)
  data_berlin <- esri2df('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/Covid19_RKI_Sums/FeatureServer/0', where=where_berlin)
  #data_berlin <- esri_request('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/Covid19_RKI_Sums/FeatureServer/0', where=where_berlin)
  if (length(data_germany) > 0 && length(data_berlin) > 0){
    data_germany$Meldedatum <- rep(Sys.Date() - before, length(data_germany$Landkreis))
    data_berlin$Meldedatum <- rep(Sys.Date() - before, length(data_berlin$Landkreis))
    data_berlin_aggregated <- data.frame(sum(data_berlin$AnzahlFall), sum(data_berlin$AnzahlTodesfall), sum(data_berlin$SummeFall), sum(data_berlin$SummeTodesfall),
                                         c(-1), c(data_berlin$Datenstand[1]) , c(Sys.Date() - before), c(data_berlin$Bundesland[1]), c(data_berlin$IdBundesland[1]),
                                         c(data_berlin$Bundesland[1]), c("11000"), sum(data_berlin$AnzahlGenesen), sum(data_berlin$SummeGenesen))
    names(data_berlin_aggregated) <- names(data_berlin)
    print(paste0('Writing data into database (', Sys.Date() - before, ')'))
    dbWriteTable(con, "covid19_germany", data_germany, row.names=FALSE, append=TRUE)
    dbWriteTable(con, "covid19_germany", data_berlin_aggregated, row.names=FALSE, append=TRUE)
    before = before + 1
  } else {
    break
  }
}

print("Loading incidents for Germany")
germany_inzidenzen_fields = c('NUTS', 'EWZ', 'death_rate', 'cases', 'deaths', 'cases_per_100k', 'cases_per_population', 'county', 'last_update',
                              'cases7_per_100k', 'recovered', 'EWZ_BL', 'cases7_bl_per_100k')
where_inzidenzen = "NOT BL='Berlin'"
data_germany_inzidenzen <- esri2sf('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/RKI_Landkreisdaten/FeatureServer/0',
                                   outFields=germany_inzidenzen_fields, where=where_inzidenzen)
data_germany_inzidenzen$geoms <- NULL
where_inzidenzen_berlin = "BL='Berlin'"
data_berlin_inzidenzen <- esri2sf('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/RKI_Landkreisdaten/FeatureServer/0',
                                  outFields=germany_inzidenzen_fields, where=where_inzidenzen_berlin)
data_berlin_inzidenzen$geoms <- NULL
data_berlin_inzidenzen_aggregated <- data.frame("DE300", data_berlin_inzidenzen$EWZ_BL[1],
                                                sum(data_berlin_inzidenzen$deaths) / sum(data_berlin_inzidenzen$cases) * 100,
                                                sum(data_berlin_inzidenzen$cases), sum(data_berlin_inzidenzen$deaths),
                                                sum(data_berlin_inzidenzen$cases) / data_berlin_inzidenzen$EWZ_BL[1] * 100000,
                                                sum(data_berlin_inzidenzen$cases) / data_berlin_inzidenzen$EWZ_BL[1] * 100, "Berlin",
                                                data_berlin_inzidenzen$last_update[1], data_berlin_inzidenzen$cases7_bl_per_100k[1],
                                                sum(data_berlin_inzidenzen$recovered), data_berlin_inzidenzen$EWZ_BL[1],
                                                data_berlin_inzidenzen$cases7_bl_per_100k[1])
names(data_berlin_inzidenzen_aggregated) <- names(data_berlin_inzidenzen)

dbSendQuery(con, "delete from inzidenzen_germany")

dbWriteTable(con, "inzidenzen_germany", data_germany_inzidenzen, row.names=FALSE, append=TRUE)
dbWriteTable(con, "inzidenzen_germany", data_berlin_inzidenzen_aggregated, row.names=FALSE, append=TRUE)

#disconnect from the database
dbDisconnect(con)