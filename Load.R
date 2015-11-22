# note that this load the final form of data into the environment, while making sure we can load it quickly later

# install and require packages
install <- function(x) {
    if (x %in% installed.packages()[,"Package"] == FALSE) {
        install.packages(x,dep=TRUE)
    }
    if(!require(x,character.only = TRUE)) stop("Package not found")
}

install('jsonlite')
install('Matrix')

rm(install)

# file paths and settings

baseurl<-"https://d396qusza40orc.cloudfront.net/dsscapstone/dataset/"
file<-"yelp_dataset_challenge_academic_dataset.zip"
dir<-"yelp_dataset_challenge_academic_dataset"

b_file<-"yelp_academic_dataset_business.json"
c_file<-"yelp_academic_dataset_checkin.json"
r_file<-"yelp_academic_dataset_review.json"
t_file<-"yelp_academic_dataset_tip.json"
u_file<-"yelp_academic_dataset_user.json"

datadir<-"/data/"

srcfile<-paste0(datadir,file)
srcdir<-paste0(datadir,dir)

b_save<-paste0(datadir,"business.rda")
c_save<-paste0(datadir,"checkin.rda")
r_save<-paste0(datadir,"review.rda")
t_save<-paste0(datadir,"tip.rda")
u_save<-paste0(datadir,"user.rda")

# only download and unzip the file if we need to
if (!file.exists(srcfile)) download.file(paste0(baseurl,file), srcfile)
if (!file.exists(srcdir)) unzip(srcfile,exdir=datadir)

rm(baseurl,file,srcfile,datadir)

# there should be 5 json files in the directory

# we don't need to load the data if we already have it loaded
# read the save file if it exists
# create the save file is it does not exist
if (file.exists(b_save)) {
} else {
    b_data <- stream_in(file(paste0(srcdir,'/',b_file)))
    save(b_data,file=b_save)
    rm(b_data)
}

# we don't need to load the data if we already have it loaded
# read the save file if it exists
# create the save file is it does not exist
if (file.exists(c_save)) {
} else {
    c_data <- stream_in(file(paste0(srcdir,'/',c_file)))
    save(c_data,file=c_save)
    rm(c_data)
}

# we don't need to load the data if we already have it loaded
# read the save file if it exists
# create the save file is it does not exist
if (file.exists(r_save)) {
} else {
    r_data <- stream_in(file(paste0(srcdir,'/',r_file)))
    save(r_data,file=r_save)
    rm(r_data)
}

# read the save file if it exists
# create the save file is it does not exist
if (file.exists(t_save)) {
} else {
    t_data <- stream_in(file(paste0(srcdir,'/',t_file)))
    save(t_data,file=t_save)
    rm(t_data)
}

# we don't need to load the data if we already have it loaded
# read the save file if it exists
# create the save file is it does not exist
if (!file.exists(u_save)) {
    u_data <- stream_in(file(paste0(srcdir,'/',u_file)))
    save(u_data,file=u_save)
    rm(u_data)
}

rm(dir,srcdir)

# after doing everything above, we should clean up the environment

# we should only do the following in the other parts of the program
# we don't need to load the data if we already have it loaded
if (!exists("b_data")) {
#      load(b_save)
}
if (!exists("c_data")) {
#      load(c_save)
}
if (!exists("r_data")) {
#      load(r_save)
}
if (!exists("t_data")) {
#      load(t_save)
}
if (!exists("u_data")) {
#      load(u_save)
}

rm(b_file,b_save)

rm(c_file,c_save)

rm(r_file,r_save)

rm(t_file,t_save)

rm(u_file,u_save)

