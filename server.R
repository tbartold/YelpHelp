library(shiny)

require(maps)
require(ggmap)
require(Matrix)
require(data.table)

if (file.exists("maparray.rda")) {
  load("maparray.rda")
} else {
  # create all the rdas so we can load them
  source("MakeMaps.R")
  maparray<-grabmaps()
  save(maparray,file="maparray.rda")
}

datadir<-"data/"

#load the cities geo locations
load("cities.rda")

# all of these rdas would be created along with maparray in MakeMaps.R
# we'll use these same criteria repeatedly - we created them back in the builder
# just the business id, lon, lat and average stars
load("businesses.rda")
# business and category cross references
load("bus_cat.rda")
load("bus.rda")
load("cat.rda")
# just the userids from the users dataframe
load("userids.rda")

cityname<-c('Edinburgh', 'Karlsruhe', 'Montreal', 'Waterloo', 'Pittsburgh', 
            'Charlotte', 'Urbana-Champaign', 'Phoenix', 'Las Vegas', 'Madison\ WI')

shinyServer(
  function(input, output, session) {
    
    output$subtitle=renderText({ 
      if (input$Location == '') {
        "Data is available for all plotted locations"        
      } else if (input$Category == '') {
        paste("Review ratings are restricted to businesses in",input$Location)        
      } else if (input$User != '') {
        paste("Recomendations for user",input$User,"are displayed for",input$Category,"businesses in",input$Location)
      } else {
        paste("Review ratings are displayed for",input$Category,"businesses in",input$Location)        
      }
    })
    
    # we want to return the list of userids appropriate for the current
    # location/category selection
    
    output$userlist <- renderUI({
      fileglob<-paste0(datadir,"result_",input$Location,"_",gsub("/", "", input$Category),"_*.rda")
      if (length(Sys.glob(fileglob))>0){
        # found it, we can load it and use it (for some users)
        load(Sys.glob(fileglob))
        userlist<-c('',result$matrix@Dimnames[[1]])
      } else {
        userlist<-c('')
      }
      selectInput('User', 'Whom?', userlist, selected=0)
    })
    
    output$plotMap=renderPlot({
      
      recommendations<-FALSE
      
      # we may have nothing selected yet
      if (input$Location != '') {
        # if they've selected a city - we can change the map
        cityname<-input$Location
        # this gives the city's real index
        city<-which(cities$cityname==cityname)
        minlat<-cities[city,3]-1
        maxlat<-cities[city,3]+1
        minlon<-cities[city,2]-1
        maxlon<-cities[city,2]+1
        # use all the business map data - but restrict to nearby the city center
        criteria<-(businesses$lat>minlat)&(businesses$lat<maxlat)&(businesses$lon>minlon)&(businesses$lon<maxlon)
        
        if (input$Category != '') {
          # augment the criteria to restrict businesses further
          criteria<-criteria & (businesses$business_id %in% bus[cat==input$Category])
          
        }
      }
      
      if (input$Location == '') {
        
        # this will display all the businesses on a big map - the last bit adds the centers
        map('world', plot = TRUE, fill = FALSE, col = palette(),xlim = c(-130,10), ylim = c(25,60))
        title("Businesses")
        points(x=businesses$lon,y=businesses$lat,col='red',cex=0.75)
        points(x=cities[,2],y=cities[,3],col='black')
        
      } else {
        
        # if a category is chosen, we want to restrict the businesses to that category  
        # bcm is a sparse matrix of 61184 businesses x 783 categories
        # get the appropriate column and find all businesses_ids that match
        
        # recommendations are made based on reviews in a specific location/categorey
        # if a user is selected we want to use recommendations on the map and not just reviews
        # if there are no recomendations in a category we need to display that also
        # there will be no recomendations if the user has not reviewed anything in 
        # the location/category
        mapdata<-businesses[criteria,]
        
        # when we have recommendations instead, we'll load a different data set
        # recomendations exist in a file called "results_<loc>_<cat>_<x>_<y>.rda"
        #if a file exists, we load it now, on the fly
        fileglob<-paste0(datadir,"result_",cityname,"_",gsub("/", "", input$Category),"_*.rda")
        if (length(Sys.glob(fileglob))>0 && input$User!=''){
          # found it, we can load it and use it (for some users)
          load(Sys.glob(fileglob))
          # this loads a results object which contains the model
          # if the user exists in the model we put the id in the user list on the ui
          # once selected we can "calculate" ratings for that user
          splitIndex <- result$num_items * result$num_features
          finalIndex <- splitIndex + (result$num_users * result$num_features)
          X <- matrix(result$model$par[1:splitIndex], nrow = result$num_items, ncol = result$num_features)
          Theta <- matrix(result$model$par[(splitIndex + 1):finalIndex], nrow = result$num_users, ncol = result$num_features)
          dimnames(Theta)<-result$matrix@Dimnames[1]
          ratings<-Theta[input$User,] %*% t(X)
          mapdata$stars<-t(ratings)[,1]
        }
        
        # select only the mapdata we want to show
        openmap<-maparray[[city]]
        ggmap(openmap) +  
          geom_point(size=3, alpha = 1, aes(lon,lat, color=stars), data=mapdata)   +
          scale_colour_gradient(limits=c(0.5, 5.5), low="red",high="green")+
          ggtitle(cityname)
      }
      
    })
  }
)


