##delete table if exists on the DB
#install.packages('RPostgres')
#devtools::install_github("yonghah/esri2sf")
#install.packages("gmailr")

#library to request data from ArcGIS Server
library("esri2sf")
#libraries to connect to PostgreSQL database and perform operations
require("RPostgreSQL")
require("DBI")
#library to send e-mails with googlemail
library('gmailr')

#creates driver-object for PostgreSQL dbms
drv <- dbDriver("PostgreSQL")

#configuration of the e-mail service
#gm_auth_configure(path = 'mail_credentials.json')
gm_auth_configure(path = '{"installed":{"client_id":"606596561749-7et37sri6m0iv9gr2l3lh9qsu5hfp5en.apps.googleusercontent.com","project_id":"coda-295416","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_secret":"8EiNbWxQJ3Emp1whszbx4tI4","redirect_uris":["urn:ietf:wg:oauth:2.0:oob","http://localhost"]}}')
sender <- "coda.sdi20@gmail.com"
recipients <- c("gil.salvans-torras@stud.sbg.ac.at","eike.blomeier@stud.sbg.ac.at")

#decides machine-depending wich database should be used
#sends e-mail in case none of the machines could be identified
if(Sys.info()[4] == 'DESKTOP-G2TVD6S') {
  #these DB credentials are for testing
  con<-dbConnect(drv,
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
} else {
  message_mail <- gm_mime() %>%
    gm_to(recipients) %>%
    gm_from(sender) %>%
    gm_subject("Database connection error") %>%
    gm_text_body("Couldn't connect to database")
  
  gm_send_message(message_mail)
}



#AUSTRIA DATA SCRAPING (regional scale)

#downloads the timeline-data for austria
print("Loading data for Austria...")
data_austria <- read.csv("https://covid19-dashboard.ages.at/data/CovidFaelle_Timeline_GKZ.csv", header=TRUE, sep=";")

#swaps fields AnzahlFaelleSum and AnzahlFaelle in case they are switched
if (FALSE %in% ((data_austria$AnzahlFaelleSum  - data_austria$AnzahlFaelle) >= 0)){
  afs <- data_austria$AnzahlFaelleSum
  af <- data_austria$AnzahlFaelle
  data_austria$AnzahlFaelleSum <- af
  data_austria$AnzahlFaelle <- afs
}

#swaps fields AnzahlTotTaeglich and AnzahlTotSum in case they are switched
if (FALSE %in% ((data_austria$AnzahlTotSum  - data_austria$AnzahlTotSum) >= 0)){
  ats <- data_austria$AnzahlTotSum
  att <- data_austria$AnzahlTotTaeglich
  data_austria$AnzahlTotSum <- att
  data_austria$AnzahlTotTaeglich <- ats
}

#swaps fields AnzahlGeheiltTaeglich and AnzahlGeheiltSum in case they are switched
if (FALSE %in% ((data_austria$AnzahlGeheiltSum - data_austria$AnzahlGeheiltTaeglich) >= 0)){
  print('swapping')
  ags <- data_austria$AnzahlGeheiltSum
  agt <- data_austria$AnzahlGeheiltTaeglich
  data_austria$AnzahlGeheiltSum <- agt
  data_austria$AnzahlGeheiltTaeglich <- ags
}

#get's the latest date from the timeline sheet
latest_timeline <- as.Date(data_austria$Time[length(data_austria$Time)], format="%d.%m.%Y")

#query to delete data from database covid19_austria
del_query_austria <- "delete from covid19_austria where "

#iterator to concatenate delete-query
it = 0

#concatenates delete-query to delete all of the data from the database which is in the current timeline as well
#data must be deleted because sometimes the data is changing after a couple of days
while (it < difftime(Sys.Date(), latest_timeline)) {
  del_query_austria <- paste0(del_query_austria, '"Time" != ' ,"'", format(Sys.Date() - it, '%d.%m.%Y'), " 00:00:00", "'")
  it <- it + 1
  if (it < difftime(Sys.Date(), latest_timeline)) {
    del_query_austria <- paste0(del_query_austria, " and ")
  }
}

#sends query to delete the doubled data
dbSendQuery(con, del_query_austria)

#downloads the covid19-data for today
data_austria_today <- read.csv("https://covid19-dashboard.ages.at/data/CovidFaelle_GKZ.csv", header=TRUE, sep=';')

#creates a vector with the current date and a midnight timestamp
a_time <- rep(paste(format(Sys.Date(), '%d.%m.%Y'), "00:00:00"), length(data_austria_today$Bezirk))
#calculates the 7 days incdence per district
inzidenz_7 <- 100000 / data_austria_today$AnzEinwohner * data_austria_today$AnzahlFaelle7Tage
data_austria_today <- cbind(a_time, data_austria_today)
data_austria_today <- cbind(inzidenz_7, data_austria_today)
#renames the column names, to match the names from the db
colnames(data_austria_today) <- c('SiebenTageInzidenzFaelle', 'Time', 'Bezirk', 'GKZ', 'AnzEinwohner', 'AnzahlFaelleSum', 'AnzahlTotSum', 'AnzahlFaelle7Tage')

#writes data to the covid19_austria db
print("Writing data for Austria into DB")
dbWriteTable(con, "covid19_austria", data_austria, row.names=FALSE, append=TRUE)
dbWriteTable(con, "covid19_austria", data_austria_today, row.names=FALSE, append=TRUE)

#----THIS CODE SEGMENT IS NOT RELEVANT FOR ASSIGNMENT 2 IN GIS APPLICATION DEVELOPMENT----



#GERMANY DATA SCRAPING
print("Loading data for Germany")
where_clause = paste0("Meldedatum=timestamp '", Sys.Date() - 1, "' AND NOT Bundesland='Berlin'")
where_berlin = paste0("Meldedatum=timestamp '", Sys.Date() - 1, "' AND Bundesland='Berlin'")
data_germany <- esri2df('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/Covid19_RKI_Sums/FeatureServer/0', where=where_clause)
data_berlin <- esri2df('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/Covid19_RKI_Sums/FeatureServer/0', where=where_berlin)

data_germany$Meldedatum <- rep(Sys.Date() - 1, length(data_germany$Landkreis))
data_berlin$Meldedatum <- rep(Sys.Date() - 1, length(data_berlin$Landkreis))

data_berlin_aggregated <- data.frame(sum(data_berlin$AnzahlFall), sum(data_berlin$AnzahlTodesfall), sum(data_berlin$SummeFall), sum(data_berlin$SummeTodesfall),
                                     c(-1), c(data_berlin$Datenstand[1]) , c(Sys.Date() - 1), c(data_berlin$Bundesland[1]), c(data_berlin$IdBundesland[1]),
                                     c(data_berlin$Bundesland[1]), c("11000"), sum(data_berlin$AnzahlGenesen), sum(data_berlin$SummeGenesen))
names(data_berlin_aggregated) <- names(data_berlin)

#add also the other two tables
print("Writing data for Germany into DB")
dbWriteTable(con, "covid19_germany", data_germany, row.names=FALSE, append=TRUE)
dbWriteTable(con, "covid19_germany", data_berlin_aggregated, row.names=FALSE, append=TRUE)

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

#SPAIN DATA SCRAPING
print("Loading data for Spain")
data_raw_spain <- read.csv("https://raw.githubusercontent.com/microsoft/Bing-COVID-19-Data/master/data/Bing-COVID19-Data.csv")
#filtering data only for Spain
data_spain <- data_raw_spain[(data_raw_spain$Country_Region == 'Spain'),]

print("Writing data for Spain into DB")
dbWriteTable(con, "covid19_spain", data_spain , row.names=FALSE, append=TRUE)

#----END OF IRRELEVANT CODE FOR ASSIGNMENT 2 IN GIS APPLICATION DEVELOPMENT----

#disconnect from the database
dbDisconnect(con)



#sends email to inform that the data was successfully scraped
message_mail <- gm_mime() %>%
  gm_to(recipients) %>%
  gm_from(sender) %>%
  gm_subject("Daily Data Upload") %>%
  gm_text_body(paste("Filled the database again -", format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))

gm_send_message(message_mail)
