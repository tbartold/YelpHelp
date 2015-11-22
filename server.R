library(shiny)

require(ggmap)
require(Matrix)
require(data.table)


if (file.exists("maparray.rda")) {
  load("maparray.rda")
} else {
  maparray<-grabmaps()
  save(maparray,file="maparray.rda")
}

if (file.exists("cities.rda")) {
  load("cities.rda")
} else {
  # now start doing map stuff
  # the city names were manually identified - we should do this automatically
  cityname<-c('Edinburgh', 'Karlsruhe', 'Montreal', 'Waterloo', 'Pittsburgh', 
              'Charlotte', 'Urbana-Champaign', 'Phoenix', 'Las Vegas', 'Madison\ WI')
  # this should allow us to get the coords of the city centers (so we can get the maps?)
  cities<-data.frame(cityname,geocode(cityname))
  rm(cityname)
  save(cities,file="cities.rda")
}

if (file.exists("businesses.rda")) {
  load("businesses.rda")
} else {
  # rebuild the tables for the apps
  businesses<-b_data[,c("business_id","longitude","latitude","stars")]
  names(businesses)<-c("business_id","lon","lat","stars")
  save(businesses, file="businesses.rda")
}

load("/data/sparse_l.rda")

load("bus_cat.rda")
load("bus.rda")
load("cat.rda")
load("userids.rda")

# set the key we need to join the tables
#map.dat <- data.table(map_data('world'))
#ggplot() + geom_polygon(aes(long,lat,group=group),fill="grey65", data=map.dat) + theme_bw() + theme(axis.text = element_blank(), axis.title=element_blank()) +coord_map("polyconic",xlim = c(-130,10), ylim = c(25,60)) 
# we'll use these same criteria repeatedly

cityname<-c('Edinburgh', 'Karlsruhe', 'Montreal', 'Waterloo', 'Pittsburgh', 
            'Charlotte', 'Urbana-Champaign', 'Phoenix', 'Las Vegas', 'Madison\ WI')
shinyServer(
  function(input, output, session) {
    
    output$subtitle=renderText({ 
      if (input$Location == '') {
        "Data is available for all plotted locations"        
      } else if (input$Category == '') {
        paste("Review ratings are restricted to businesses in",input$Location)        
      } else if (input$User == 0) {
        paste("Review ratings are available for",input$Category,"businesses in",input$Location)        
      #} else if (recommendations) {
      #  paste("Recomendations for user",input$User,"are displayed for",input$Category,"businesses in",input$Location)
      } else {
        paste("Insufficient data to recommend. Review ratings are displayed for",input$Category,"businesses in",input$Location)        
      }
    })
    
    output$plotMap=renderPlot({

      recommendations<-FALSE
      
      # we may have nothing selected yet
      if (input$Location != '') {
        # if they've selected a city - we can change the map
        cityname<-input$Location
        # this gives the city's real index
        city<-which(cities$cityname==cityname)
        openmap<-maparray[[city]]
        minlat<-cities[city,3]-1
        maxlat<-cities[city,3]+1
        minlon<-cities[city,2]-1
        maxlon<-cities[city,2]+1
        # use all the business map data - but restrict to nearby the city center
        criteria<-(businesses$lat>minlat)&(businesses$lat<maxlat)&(businesses$lon>minlon)&(businesses$lon<maxlon)
        
        if (input$Category != '') {
          # augment the criteria to restrict businesses further
          criteria<-criteria & (businesses$business_id %in% bus[cat==input$Category])
          
          # if a user is selected, we may be able to make recomendations
          if (input$User>0) {
            ### checking against the spare_l does not appear to work
            ### may need to create a npther table for this
            #if(sum(sparse_l[input$User,businesses[criteria,]])>0) {
            ## recommendations should be used  
            #recommendations<-TRUE
            #}
          } 
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
          fileglob<-paste0(datadir,"result_",cityname,"_",gsub("/", "", category),"_*.rda")
          if (length(Sys.glob(fileglob))>0){
            # found it, we can load it and use it (for some users)
            load(Sys.glob(fileglob))
            # this loads a results object which contains the model
            
          }
          
        # select only the mapdata we want to show
        ggmap(openmap) +  
          geom_point(size=3, alpha = 1, aes(lon,lat, color=stars), data=mapdata)   +
          scale_colour_gradient(limits=c(0.5, 5.5), low="red",high="green")+
          ggtitle(cityname)
      }

    })
  }
)
