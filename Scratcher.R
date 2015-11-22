# this reduces the data into the appropriate sparse matrix sets and load them
# the ones we have right now are large (all data), medium, small, and phoenix

# install and require packages
install <- function(x) {
  if (x %in% installed.packages()[,"Package"] == FALSE) {
    install.packages(x,dep=TRUE)
  }
  if(!require(x,character.only = TRUE)) stop("Package not found")
}

install('Matrix')

rm(install)

# we assume the following datasets have been saved in the Load.R script
datadir<-"/data/"
b_save<-paste0(datadir,"business.rda")
r_save<-paste0(datadir,"review.rda")
u_save<-paste0(datadir,"user.rda")

if (!file.exists(r_save)) {
  source("Load.R")
}
if (!file.exists(u_save)) {
  source("Load.R")
}
if (!file.exists(b_save)) {
  source("Load.R")
}

################################################################################
# this is the raw data and xtracted data - creates the 'x' extra lrge version
################################################################################
if (!file.exists(paste0(datadir,"r_x.csv"))) {
  # the r_data review.rda is loaded but unmodified from the json
  load(r_save)
  # the reviews object is the xtracted form sent to the r_x.csv file
  reviews<-r_data[,c("user_id","business_id","stars")]
  rm(r_data)
  colnames(reviews)<-c("user","item","rating")
  write.csv(reviews,file=(paste0(datadir,"r_x.csv")))
  rm(reviews)
  unlink("u_x.csv")
  unlink("b_x.csv")
  unlink("s_x.csv")
}

# u_x.csv is a single column extracted from the user data
if (!file.exists(paste0(datadir,"u_x.csv"))) {
  load(u_save)
  user<-u_data[,c("user_id")]
  rm(u_data)
  write.csv(user,file=(paste0(datadir,"u_x.csv")))
  rm(user)
}

# b_x.csv is a single column extracted from the business data
if (!file.exists(paste0(datadir,"b_x.csv"))) {
  load(b_save)
  business<-b_data[,c("business_id")]
  rm(b_data)
  write.csv(business,file=(paste0(datadir,"b_x.csv")))
  rm(business)
}

# we have to convert user_id and business_id to integer before continuing and 
# read from b_x.csv, u_x.csv and r_x.csv and store in s_x.csv
if (!file.exists(paste0(datadir,"s_x.csv"))) {
  # note that there are about 48000 duplicate reviews, we just use the first review, we probably should use the last
  system(paste("perl matrox.pl",datadir))
}

################################################################################
# this is a smallest reduced data set, 
# but we need to reindex the user_id and business_id for a smaller matrix
# we want only about 1000 rows and 1000 columns, but we also want it sparse
################################################################################
if (!file.exists(paste0(datadir,"r_s.csv"))) {
  load(r_save)
  reviews<-r_data[,c("user_id","business_id","stars")]
  rm(r_data)
  reduced<-reviews
  rm(reviews)
  t<-table(reduced$user_id)
  reduced<-reduced[t[reduced$user_id]>20,]
  reduced<-reduced[t[reduced$user_id]<25,]
  rm(t)
  t<-table(reduced$business_id)
  reduced<-reduced[t[reduced$business_id]>15,]
  reduced<-reduced[t[reduced$business_id]<50,]
  rm(t)
  length(unique(reduced$user_id))
  length(unique(reduced$business_id))
  colnames(reduced)<-c("user","item","rating")
  
  write.csv(reduced,file=(paste0(datadir,"r_s.csv")))
  rm(reduced)
}

if (!file.exists(paste0(datadir,"s_s.csv"))) {
  # reads r_s.csv and produces u_s.csv, b_s.csv and s_s.csv
  system(paste("perl reduced.pl",datadir))
}


################################################################################
# let's also do a midsized file (large is too big for optim)
################################################################################
if (!file.exists(paste0(datadir,"r_m.csv"))) {
  load(r_save)
  reviews<-r_data[,c("user_id","business_id","stars")]
  rm(r_data)
  reduced<-reviews
  rm(reviews)
  t<-table(reduced$user_id)
  reduced<-reduced[t[reduced$user_id]>20,]
  rm(t)
  t<-table(reduced$business_id)
  reduced<-reduced[t[reduced$business_id]>10,]
  rm(t)
  length(unique(reduced$user_id))
  length(unique(reduced$business_id))
  colnames(reduced)<-c("user","item","rating")
  
  write.csv(reduced,file=(paste0(datadir,"r_m.csv")))
  rm(reduced)
  unlink(paste0(datadir,"s_m.csv"))
}

if (!file.exists(paste0(datadir,"s_m.csv"))) {
  # reads r_s.csv and produces u_s.csv, b_s.csv and s_s.csv
  system(paste("perl reduced.pl",datadir,"m"))
  rm(sparse_m)
}

################################################################################
# I also want a phoenix only file - see if that's tractable
################################################################################
if (!file.exists(paste0(datadir,"r_p.csv"))) {
  load(r_save)
  reviews<-r_data[,c("user_id","business_id","stars")]
  rm(r_data)
  reduced<-reviews
  rm(reviews)
  
  load(b_save)
  bus<-b_data[,c("business_id","longitude","latitude")]
  rm(b_data)

  # identify only businesses in phoenix?
  bus_ids<-bus[bus$longitude > -113 & bus$longitude < -110,1]
  # remove businesses not in phoenix
  phoenix<-reduced[reduced$business_id %in% bus_ids,]

  # do we need to remove users with no reviews? probably not
  t<-table(phoenix$user_id)
  phoenix<-phoenix[t[phoenix$user_id]>0,]
  rm(t)
  
  length(unique(phoenix$user_id))
  length(unique(phoenix$business_id))
  colnames(phoenix)<-c("user","item","rating")
  
  # save the file, and discard the downstream version
  write.csv(phoenix,file=(paste0(datadir,"r_p.csv")))
  rm(phoenix)
  unlink(paste0(datadir,"s_p.csv"))
}

if (!file.exists(paste0(datadir,"s_p.csv"))) {
  # reads r_?.csv and produces u_?.csv, b_?.csv and s_?.csv
  system(paste("perl reduced.pl",datadir,"p"))
  rm(sparse_p)
}

rm(r_save,u_save,b_save)

################################################################################
# now we're ready to read in just the sparse matrices we've created above
# read in reduced csv and create a spare ratings matrix
# save the sparse matrices so we can load them quicker
################################################################################

if (!file.exists(paste0(datadir,"sparse_l.rda"))) {
  if(!exists("sparse_l")) {
    matrix<-read.csv(paste0(datadir,"s_x.csv"))
    sparse_l<-sparseMatrix(matrix$user,matrix$item,x=matrix$rating)
    rm(matrix)
  }
  head(summary(sparse_l),1)
  save(sparse_l,file=paste0(datadir,"sparse_l.rda"))
  rm(sparse_l)
}
# 366715 x 61184 sparse Matrix of class "dgCMatrix", with 1521160 entries 

if (!file.exists(paste0(datadir,"sparse_m.rda"))) {
  if(!exists("sparse_m")) {
    matrix<-read.csv(paste0(datadir,"s_m.csv"))
    sparse_m<-sparseMatrix(matrix$user,matrix$item,x=matrix$rating)
    rm(matrix)
  }
  head(summary(sparse_m),1)
  save(sparse_m,file=paste0(datadir,"sparse_m.rda"))
  rm(sparse_m)
}
# 10715 x 12315 rating matrix of class ‘realRatingMatrix’ with 435583 ratings.

if (!file.exists(paste0(datadir,"sparse_s.rda"))) {
  if(!exists("sparse_s") ) {
    matrix<-read.csv(paste0(datadir,"s_s.csv"))
    sparse_s<-sparseMatrix(matrix$user,matrix$item,x=matrix$rating)
    rm(matrix)
  }
  head(summary(sparse_s),1)
  save(sparse_s,file=paste0(datadir,"sparse_s.rda"))
  rm(sparse_s)
}
# 1788 x 287 rating matrix of class ‘realRatingMatrix’ with 6686 ratings.

if (!file.exists(paste0(datadir,"sparse_p.rda"))) {
  if(!exists("sparse_p")) {
    matrix<-read.csv(paste0(datadir,"s_p.csv"))
    sparse_p<-sparseMatrix(matrix$user,matrix$item,x=matrix$rating)
    rm(matrix)
  }
  head(summary(sparse_p),1)
  save(sparse_p,file=paste0(datadir,"sparse_p.rda"))
  rm(sparse_p)
}
# 128330 x 25225 sparse Matrix of class "dgCMatrix", with 569847 entries 

rm(datadir)

