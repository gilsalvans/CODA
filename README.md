## CODA : SDI Project
### Open GI Services for Covid-19 Dashboards 
Final project from the courses IP SDI: Services Implementations & IP: Application Development. <br>
#### Students:
* Eike Sebastian Blomeier
* Gil Salvans Torras

### Project Abstract
This project consists of the development of a Spatial Data Infrastructure (SDI) with a thematical focus on the Covid19 pandemic in three countries: Austria, Germany and Spain.
In agreement with this, the infrastructure is continuously running and its data is updated in a daily basis automatically so the user can get a general understanding of the status of the 
pandemic in each of the aforementioned countries with the latest data through an interactive web application with different dashboards. To achieve this, this SDI can be divided
in three stages. The first one, which regards to the daily data collection and setting it up into a geospatial database. Secondly, connecting the database to a GI Server in order
to publish all the data as standard OGC services. Finally, a retrieval of the different services is carried out by the different dashboards of the web application.

### Goals:
#### Main Goals:
* Retrieve Covid-19 infection numbers and store them into a spatial database.
* Use the stored data to generate an interactive dashboard which displays the current
Covid-19 infection numbers for different regions and showing different graphical data
representations.
* Make all the data (published services) displayed by the dashboard publicly available to be
accessed by an HTTP request from any user.
* Use Geo Server technologies to carry out a map representation of the data and use it
subsequently in the dashboard.
#### Sub Goals:
* Develop the entire project by merely using open source technologies.
* Provide additional sources of information to the dashboard in an interactive way (e.g.
Telegram Bots / Worldwide restrictions per country).

### SDI Architecture Overview 
![Alt text](/diagrams/architectural_diagram.jpg?raw=true)

### Web Application Link
[Visit the CODA web application!](http://human.zgis.at/coda)