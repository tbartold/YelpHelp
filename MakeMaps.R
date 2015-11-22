source("Load.R")

# this adds matrix support
library(irlba)
library(ggmap)
library(maps)

if(file.exists("bus_cat.rda")) {
  load("bus_cat.rda")
  load("bus.rda")
  load("cat.rda")
} else {
  # this gives all categories for a business
  b_cat<-b_data[,c("business_id","categories")]
  # want all businesses in a category also
  business_ids<-b_data$business_id
  categories<-names(table(unlist(b_data$categories)))
  
  # create a sparse matrix of business x category
  bcm<- Matrix(0, nrow = length(business_ids), ncol = length(categories), sparse = TRUE)
  
  for(i in 1:nrow(b_cat)) {
    bus <- b_cat[[i,1]]
    cats<- b_cat[[i,2]]
    for (cat in cats) {
      k<-which(categories==cat)
      bcm[i,k]<-1
    }
  }
  
  nnzero(bcm)
  #[1] 176697
  
  bus<-business_ids
  cat<-categories
  save(bcm,file="bus_cat.rda")
  save(bus,file="bus.rda")
  save(cat,file="cat.rda")

  usr<-u_data$user_ids
  save(usr,file="userids.rda")
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

bigmap <- function() {
  # this will display all the businesses on a big map - the last bit adds the centers
  map('world', plot = TRUE, fill = FALSE, col = palette(),xlim = c(-130,10), ylim = c(25,60))
  title("Businesses")
  points(x=businesses$lon,y=businesses$lat,col='red',cex=0.75)
  points(x=cities[,2],y=cities[,3],col='black')
}


lowrescity <- function(city) {
  # zoom in on a center?
  map('world', plot = TRUE, fill = FALSE, col = palette(),xlim = cities[city,2]+c(-2,2), ylim = cities[city,3]+c(-2,2))
  title(cities[city,1])
  points(x=businesses$lon,y=businesses$lat,col='red',cex=0.75)
  points(x=cities[,2],y=cities[,3],col='black')
}

# this will grab all the city maps and hold them in a list
grabmaps <- function() {
  result<-list()
  for (i in 1:10) {
    city<-as.character(cities[[i,1]])
    print(city)
    result[[i]]<-get_map(location = city, source = 'stamen', maptype = 'toner')
  }
  return(result)
}

if (file.exists("maparray.rda")) {
  load("maparray.rda")
} else {
  maparray<-grabmaps()
  save(maparray,file="maparray.rda")
}

# this functions should display a map of the given city with business plotted by stars color
display<- function(cityname) {
  city<-which(cities[,1]==cityname)
  openmap<-maparray[[city]]
  # use all the business map data - some of it wil be out of bounds
  mapdata<-businesses
  g<-ggmap(openmap) +  
    geom_point(size=2, alpha = 1/2, aes(lon,lat, color=stars), data=mapdata)   +
    scale_colour_gradient(limits=c(0.5, 5.5), low="red",high="green")+
    ggtitle(cityname)
  print(g)
}

# we want to limit this to businesses in a specific category
dc<- function(cityname,category) {
  # city will be a name, we need to find the index here
  city<-which(cities==cityname)
  openmap<-maparray[[city]]  
  # businesses in the category are in the bcm matrix
  category_index<-which(cat==category)
  # this is a 0/1 vector
  business_indexes<-bcm[,category_index]
  # select out th businesses into the submap
  
  mapdata<-businesses[business_indexes==1,]
  g<-ggmap(openmap) +  
    geom_point(size=2, alpha = 1/2, aes(lon,lat, color=stars), data=mapdata)   +
    scale_colour_gradient(limits=c(0.5, 5.5), low="red",high="green")+
    ggtitle(paste(cityname,category))
  print(g)
}

# we also want to show user preference, rather than just business ratings
# this is a big thing, about 2 gig
if(!exists("res")) {
  load("/data/irlba_l_600.rda")
}

bigmap()

#users<-u_data[,c("user_id","name")]
svd<-res
predict<-function(user) {
  solution<-svd$u[user,] %*% Diagonal(x=svd$d) %*% t(svd$v)
  return(solution[1,])
}

# we want to limit this to businesses in a specific category
# rather than using the business rating, use ratings from a user
dcu<- function(cityname,category,user) {
  # city will be a name, we need to find the index here
  city<-which(cities==cityname)
  openmap<-maparray[[city]]  
  # businesses in the category are in the bcm matrix
  category_index<-which(cat==category)
  # this is a 0/1 vector
  business_indexes<-bcm[,category_index]
  # compute the user rating for the businesses
  ratings<-predict(user)
  businesses_mod<-businesses
  businesses_mod[,4]<-ratings
  # select out the businesses into the submap
  mapdata<-businesses[business_indexes==1,]
  g<-ggmap(openmap) +  
    geom_point(size=2, alpha = 1/2, aes(lon,lat, color=stars), data=mapdata)   +
    scale_colour_gradient(limits=c(0.5, 5.5), low="red",high="green")+
    ggtitle(paste(cityname,category))
  print(g)
}

datadir<-"/data/"
if(!exists("sparse_l")) {
  large<-read.csv(paste0(datadir,"s_x.csv"))
  colnames(large)<-c("user","item","rating")
  sparse_l<-sparseMatrix(large$user,large$item,x=large$rating)
  rm(large)
}


load("/data/irlba-10.rda")
svd<-res
summary(predict(1))
#Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
#-3.530e-03 -3.640e-07  4.500e-08  7.498e-06  1.775e-06  6.227e-03

load("/data/irlba-100.rda")
svd<-res
summary(predict(1))
#Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
-
summary(sparse_l[1,])



predict<-function(user) {
  solution<-svd$u[user,] %*% t(svd$v)
  return(solution[1,])
}


