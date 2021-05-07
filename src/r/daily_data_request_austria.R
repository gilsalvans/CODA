##delete table if exists on the DB
#install.packages('RPostgres')
#devtools::install_github("yonghah/esri2sf")
#install.packages("gmailr")

#library to request data from ArcGIS Server
#library("esri2sf")
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



#AUSTRIA DATA SCRAPING (regional scale)

#downloads the timeline-data for austria
print("Loading data for Austria...")
tryCatch({data_austria <- read.csv("https://covid19-dashboard.ages.at/data/CovidFaelle_Timeline_GKZ.csv", header=TRUE, sep=";")
          data_austria <- cbind(Sys.Date(), data_austria)
          names(data_austria)[1] <- 'insertion_date'

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
          latest_timeline <- as.Date(data_austria$Time[length(data_austria$Time)], format="%d.%m.%Y")},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning retrieving timeline data for austria", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error retrieving timeline data for austria", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           dbRollback(con)
           no_error <- FALSE
         })

#query to delete data from database covid19_austria
#del_query_austria <- "delete from covid19_austria where "

#iterator to concatenate delete-query
#it = 0

#concatenates delete-query to delete all of the data from the database which is in the current timeline as well
#data must be deleted because sometimes the data is changing after a couple of days
#while (it < difftime(Sys.Date(), latest_timeline)) {
  #del_query_austria <- paste0(del_query_austria, '"Time" != ' ,"'", format(Sys.Date() - it, '%d.%m.%Y'), " 00:00:00", "'")
  #it <- it + 1
  #if (it < difftime(Sys.Date(), latest_timeline)) {
    #del_query_austria <- paste0(del_query_austria, " and ")
  #}
#}

#sends query to delete the doubled data
#b <- dbBegin(con)
#dbSendQuery(con, del_query_austria)

#downloads the covid19-data for today
tryCatch({data_austria_today <- read.csv("https://covid19-dashboard.ages.at/data/CovidFaelle_GKZ.csv", header=TRUE, sep=';')
          #creates a vector with the current date and a midnight timestamp
          a_time <- rep(paste(format(Sys.Date(), '%d.%m.%Y'), "00:00:00"), length(data_austria_today$Bezirk))
          #calculates the 7 days incdence per district
          inzidenz_7 <- 100000 / data_austria_today$AnzEinwohner * data_austria_today$AnzahlFaelle7Tage
          data_austria_today <- cbind(a_time, data_austria_today)
          data_austria_today <- cbind(inzidenz_7, data_austria_today)
          data_austria_today <- cbind(Sys.Date(), data_austria_today)
          #renames the column names, to match the names from the db
          colnames(data_austria_today) <- c('insertion_date' ,'SiebenTageInzidenzFaelle', 'Time', 'Bezirk', 'GKZ', 'AnzEinwohner', 'AnzahlFaelleSum', 'AnzahlTotSum', 'AnzahlFaelle7Tage')},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning retrieving daily data for austria", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error retrieving daily data for austria", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           dbRollback(con)
           no_error <- FALSE
         },
         finally = {
           print('finally')
           dbCommit(con)
         })

#writes timeline-data to the covid19_austria db
print("Writing data for Austria into DB")
dbBegin(con)
tryCatch({dbWriteTable(con, "covid19_austria", data_austria, row.names=FALSE, append=TRUE)},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning filling the austrian database", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error filling the austrian database", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           dbRollback(con)
           no_error <- FALSE
         },
         finally = {
           #print(err)
           print('finally')
           dbCommit(con)
         })

#writes today's data to the covid19_austria db
dbBegin(con)
tryCatch({dbWriteTable(con, "covid19_austria", data_austria_today, row.names=FALSE, append=TRUE)},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning filling the austrian database", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error filling the austrian database", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           dbRollback(con)
           no_error <- FALSE
         },
         finally = {
           print('finally')
           dbCommit(con)
         })

#disconnect from the database
dbDisconnect(con)

#sends email to inform that the data was successfully scraped
if(no_error){
  send_mail(recipients, sender, "Daily Data Upload Austria", paste("Filled the austrian database again -", format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
}
