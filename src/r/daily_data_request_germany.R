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

#variable to store if any error was thrown
no_error <- TRUE

#function to send mail
send_mail <- function(recipients, sender, subject, text, auth_configure=FALSE){
  if(auth_configure != FALSE){
    gm_auth_configure(path = auth_configure)
  }
  message_mail <- gm_mime() %>%
    gm_to(recipients) %>%
    gm_from(sender) %>%
    gm_subject(subject) %>%
    gm_text_body(text)
  
  gm_send_message(message_mail)
}


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
  send_mail(recipients, sender, "Database connection error", "Couldn't connect to database")
  no_error <- FALSE
}

#GERMANY DATA SCRAPING
tryCatch({print("Loading data for Germany")
          #where query to request data for yesterday for all counties which aren't located in Berlin
          where_clause = paste0("Meldedatum=timestamp '", Sys.Date() - 1, "' AND NOT Bundesland='Berlin'")
          #where query to request data for yesterday for all counties which are part of Berlin
          where_berlin = paste0("Meldedatum=timestamp '", Sys.Date() - 1, "' AND Bundesland='Berlin'")
          #requesting data
          data_germany <- esri2df('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/Covid19_RKI_Sums/FeatureServer/0', where=where_clause)
          data_berlin <- esri2df('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/Covid19_RKI_Sums/FeatureServer/0', where=where_berlin)
          
          data_germany$Meldedatum <- rep(Sys.Date() - 1, length(data_germany$Landkreis))
          data_germany <- cbind(Sys.Date(), data_germany)
          names(data_germany)[1] <- 'insertion_date'
          
          data_berlin$Meldedatum <- rep(Sys.Date() - 1, length(data_berlin$Landkreis))
          
          #aggregating berlins counties 
          data_berlin_aggregated <- data.frame(sum(data_berlin$AnzahlFall), sum(data_berlin$AnzahlTodesfall), sum(data_berlin$SummeFall), sum(data_berlin$SummeTodesfall),
                                               c(-1), c(data_berlin$Datenstand[1]) , c(Sys.Date() - 1), c(data_berlin$Bundesland[1]), c(data_berlin$IdBundesland[1]),
                                               c(data_berlin$Bundesland[1]), c("11000"), sum(data_berlin$AnzahlGenesen), sum(data_berlin$SummeGenesen))
          names(data_berlin_aggregated) <- names(data_berlin)
          data_berlin_aggregated <- cbind(Sys.Date(), data_berlin_aggregated)
          names(data_berlin_aggregated)[1] <- 'insertion_date'
          },
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning scraping german data", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Warning scraping german data", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           no_error <- FALSE
         })

#Writing yesterdays data into covid19_germany table (except berlin)
print("Writing data for Germany into DB")
dbBegin(con)
tryCatch({dbWriteTable(con, "covid19_germany", data_germany, row.names=FALSE, append=TRUE)},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning filling the german database", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error filling the german database", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           dbRollback(con)
           no_error <- FALSE
         },
         finally = {
           #print(err)
           print('finally')
           dbCommit(con)
         })

#Wrtiting yesterdays data for Berlin into covid19_germany table 
dbBegin(con)
tryCatch({dbWriteTable(con, "covid19_germany", data_berlin_aggregated, row.names=FALSE, append=TRUE)},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning filling the german database", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error filling the german database", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           dbRollback(con)
           no_error <- FALSE
         },
         finally = {
           #print(err)
           print('finally')
           dbCommit(con)
         })

#Loading the incident numbers for Germany
print("Loading incidents for Germany")
tryCatch(
        #setting up the fields to request
        {germany_inzidenzen_fields = c('NUTS', 'EWZ', 'death_rate', 'cases', 'deaths', 'cases_per_100k', 'cases_per_population', 'county', 'last_update',
                              'cases7_per_100k', 'recovered', 'EWZ_BL', 'cases7_bl_per_100k')
         #setting up where clause for germany, expect Berlin
         where_inzidenzen = "NOT BL='Berlin'"
         #requesting the data
         data_germany_inzidenzen <- esri2sf('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/RKI_Landkreisdaten/FeatureServer/0',
                                   outFields=germany_inzidenzen_fields, where=where_inzidenzen)
         data_germany_inzidenzen <- cbind(Sys.Date(), data_germany_inzidenzen)
         names(data_germany_inzidenzen)[1] <- 'insertion_date'
         #removing the geometry column
         data_germany_inzidenzen$geoms <- NULL
    
         #setting up where clause for Berlin
         where_inzidenzen_berlin = "BL='Berlin'"
         #requesting the data for Berlin
         data_berlin_inzidenzen <- esri2sf('https://services7.arcgis.com/mOBPykOjAyBO2ZKk/ArcGIS/rest/services/RKI_Landkreisdaten/FeatureServer/0',
                                  outFields=germany_inzidenzen_fields, where=where_inzidenzen_berlin)
         #removing the geometry column
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
         #aggregating the data for Berlin
         data_berlin_inzidenzen_aggregated <- cbind(Sys.Date(), data_berlin_inzidenzen_aggregated)
         names(data_berlin_inzidenzen_aggregated)[1] <- 'insertion_date'
         },
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning scraping german data", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Warning scraping german data", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           no_error <- FALSE
         })

#dbSendQuery(con, "delete from inzidenzen_germany")
#writing incidence data into table inzidenzen_germany (except Berlin)
dbBegin(con)
tryCatch({dbWriteTable(con, "inzidenzen_germany", data_germany_inzidenzen, row.names=FALSE, append=TRUE)},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning filling the german inzidenzen database", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error filling the german inzidenzen database", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           dbRollback(con)
           no_error <- FALSE
         },
         finally = {
           #print(err)
           print('finally')
           dbCommit(con)
         })

#writing berlins incidence data into table inzidenzen_germany
dbBegin(con)
tryCatch({dbWriteTable(con, "inzidenzen_germany", data_berlin_inzidenzen_aggregated, row.names=FALSE, append=TRUE)},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning filling the german inzidenzen database", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error filling the german inzidenzen database", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           dbRollback(con)
           no_error <- FALSE
         },
         finally = {
           #print(err)
           print('finally')
           dbCommit(con)
         })

#disconnect from the database
dbDisconnect(con)

#sends email to inform that the data was successfully scraped
if(no_error){
  send_mail(recipients, sender, "Daily Data Upload Germany", paste("Filled the german database again -", format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
}