library(shiny)

# need to display information in the sidebar
# in particular where, what and who

# allow selection of different 'scales' to the maps
# the first map should be the world (static)
# any other location chosen will be a metro map
location<-c('', 'Edinburgh', 'Karlsruhe', 'Montreal', 'Waterloo', 'Pittsburgh', 
            'Charlotte', 'Urbana-Champaign', 'Phoenix', 'Las Vegas', 'Madison\ WI')

# the categories are used to restrict the number of businesses on a metro map
load("cat.rda")
cat<-c('',cat)

# the list of users is used to use recomendations rather than ratings
load("userids.rda")
maxuser<-length(user)

shinyUI(
  pageWithSidebar(
    headerPanel("Where would you like to go today?"),
    sidebarPanel(

      helpText("Choose a Location"),
      selectInput('Location', 'Where?', location, selected=location[0]),

      conditionalPanel(
        condition = "input.Location!=''",
        helpText("Choose a Category"),
        selectInput('Category', 'What?', cat, selected=cat[0])),
      
      conditionalPanel(
        condition = "input.Category!=''",
        helpText("Enter your numeric user id (use 0 if you don't have one)"),
        numericInput('User', 'Whom?', 0, min = 0, max = maxuser)),
      
      helpText("The datasource for this app is the Yelp Dataset Challenge")
    ),
    mainPanel(
      h1("Yelp Business Recomendations", align="center"),
      plotOutput('plotMap'),
      textOutput('subtitle')
    )
  )
)
