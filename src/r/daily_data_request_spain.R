##delete table if exists on the DB
#install.packages('RPostgres')
#devtools::install_github("yonghah/esri2sf")
#install.packages("gmailr")

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

#SPAIN DATA SCRAPING
print("Loading data for Spain")
tryCatch({data_raw_spain <- read.csv("https://media.githubusercontent.com/media/microsoft/Bing-COVID-19-Data/master/data/Bing-COVID19-Data.csv")
          #filtering data only for Spain
          data_spain <- data_raw_spain[(data_raw_spain$Country_Region == 'Spain'),]
          data_spain <- cbind(Sys.Date(), data_spain)
          names(data_spain)[1] <- 'insertion_date'},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning retrieving spanish data", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error retrieving spanish data", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
           no_error <- FALSE
         })

#Writes data into table covid19_spain
print("Writing data for Spain into DB")
dbBegin(con)
tryCatch({dbWriteTable(con, "covid19_spain", data_spain , row.names=FALSE, append=TRUE)},
         warning = function(war){
           print('warning')
           send_mail(recipients, sender, "Warning filling the spanish database", paste(war, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
         },
         error = function(err){
           send_mail(recipients, sender, "Error filling the spanish database", paste(err, '\n', format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
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
  send_mail(recipients, sender, "Daily Data Upload Spain", paste("Filled the spanish database again -", format(Sys.Date(), '%d.%m.%Y'), Sys.info()[4]))
}