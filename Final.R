# we need to start with something, so load in the sparse matrices (if they don't exist)

source("Scratcher.R")

datadir<-"/data/"

# probably shouldn't load things we don't need back there... so make sure we clean them up
# we want to build a RSVD based recommender - we need a gradient and a cost

# Helper functions - params is all of the values in X and Theta
# so it will have num_items * num_features + num_users * num_features entries
# Y and R are bother num_users x num_items sparse matrices
# Y_Dash is a computed difference (cost)

unroll_Vecs <- function (params, Y, R, num_users, num_items, num_features) {
  splitIndex <- num_items * num_features
  finalIndex <- splitIndex + (num_users * num_features)
  
  X <- matrix(params[1:splitIndex], nrow = num_items, ncol = num_features)
  Theta <- matrix(params[(splitIndex + 1):finalIndex], nrow = num_users, ncol = num_features)
  Y_dash <- (((X %*% t(Theta)) - Y) * R)
  
  return(list(X = X, Theta = Theta, Y_dash = Y_dash))
}

J_cost <-  function(params, Y, R, num_users, num_items, num_features, lambda) {
  
  unrolled <- unroll_Vecs(params, Y, R, num_users, num_items, num_features)
  X <- unrolled$X
  Theta <- unrolled$Theta
  Y_dash <- unrolled$Y_dash
  
  J <-  .5 * sum(   Y_dash ^2)  + lambda/2 * sum(Theta^2) + lambda/2 * sum(X^2)
  
  return (J)
}

grr <- function(params, Y, R, num_users, num_items, num_features, lambda) {
  
  unrolled <- unroll_Vecs(params, Y, R, num_users, num_items, num_features)
  X <- unrolled$X
  Theta <- unrolled$Theta
  Y_dash <- unrolled$Y_dash
  
  X_grad     <- (   Y_dash  %*% Theta) + lambda * X
  Theta_grad <- ( t(Y_dash) %*% X)     + lambda * Theta
  
  grad = c(X_grad, Theta_grad)
  return(grad)
}

# we're going to feed into it a sparse matrix, but we also need a weight matrix
# so that we weight rated entries only in the cost

optimize<-function(matrix,num_features,maxit) {
  #  Y <- t(matrix)
  # need to use a real matrix here - a sparse matrix fails with BFGS
  # Y is our target matrix X and Theta are decompositions
  # we want to decompose to num_features<-10
  # lambda is the regularization and suggested is 1.5
  Y <- t(as.matrix(as(matrix, "matrix")))
  R <- 1 * (Y != 0)
  num_users <- ncol(Y) 
  num_items <- nrow(Y) 
  lambda <- 1.5
  res<-list()
  res$Y <- Y
  res$R <- R
  res$num_users <- num_users
  res$num_items <- num_items
  res$num_features <- num_features
  res$maxit <- maxit
  res$matrix <- matrix
  
  # initial guess for the decomposed matrix is random
  model<-optim(par = runif(num_items * num_features + num_users * num_features), 
               method = "L-BFGS-B",
               fn = J_cost, gr = grr,
               Y=Y, R=R,
               num_users=num_users, num_items=num_items, num_features=num_features,
               lambda=lambda, control=list(maxit=maxit, trace=1))
  res$model<- model
  
  return(res)
}

# simple function to compare predictions to real ratings for a user
comparevals <- function(res) {
  model<-res$model
  # Y final might give us better answers
  unrolled <- unroll_Vecs(model$par, res$Y, res$R, res$num_users, res$num_items, res$num_features)
  X_final     <- unrolled$X
  theta_final <- unrolled$Theta
  
  # our true Y_final should be massages to have vales from 1 to 5 (or 0 to 6?)
  Y_final <- round(X_final %*% t(theta_final) )
  
  #Y[,1] gives a set of 4 ratings.
  #Y_final[,1]*R[,1] gives mostly 2s
  
  # the summary tells us most of his ratings are now under 2
  #summary(Y_final[,1])
  #Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
  #-0.0035  1.3140  1.7400  1.7240  2.1220  3.1790 
  #summary(Y[,1])
  
  # this one appears much better - more reviews helps a lot - with rounding all of these values are correct
  print(Y[R[,71]==1,71])
  #[1] 4 1 3 4 1 2 5 5 5 2
  print(Y_final[R[,71]==1,71])
  #[1] 3.809621 1.180757 2.994951 3.934912 1.320803 2.070552 4.672574 4.717019 4.599806 2.072026
  
  # so well want to look at a small region where there are lots of reviews to prove it out
  
  # we need a small region because of the compute time.
  
  # we can take the error to be something simple like the sum of errors in the reviews
  # less the value of the reviews - note that if we are offf by at most one, then sq err == abs err
  squarederrors<-((Y-Y_final)*R)^2
  sum(squarederrors)
  errors<-abs((Y-Y_final)*R)
  sum(errors)
  # [1] 456
  #total reviews
  sum(R)
  # [1] 6686
  # mean square error 
  print("mean squared error for all known ratings")
  print(mse<-sum(((Y-Y_final)*R)^2)/sum(R))
  # [1] 0.06820221
  
}


# if we have a result to begin with, we should save it before we blow it away
# this is to save the result
stashresult<-function() {
  if (exists("result")) {
    num_features <- result$num_features
    maxit<-result$maxit
    matrixid<-result$matrixid

    # can't have slashes in file names    
    filename<-paste0(datadir,"result_",gsub("/", "", matrixid),"_",num_features,"_",maxit,".rda")
    
    if (!file.exists(filename)) {
      save(result,file=filename)
    }
    rm(result)
  }
}

saveresult<-function(result) {
  num_features <- result$num_features
  maxit<-result$maxit
  matrixid<-result$matrixid
  # if it converged, we don't need to record maxit - use zero instead
  if (result$model$convergence==0) {
    maxit<-0
  }
  # can't have slashes in file names    
  filename<-paste0(datadir,"result_",gsub("/", "", matrixid),"_",num_features,"_",maxit,".rda")
  if (!file.exists(filename)) {
    save(result,file=filename)
  }
  rm(result)
}


# this will either load the result or create it
loadresult<-function (location,category,num_features,maxit) {
  matrixid <- paste0(location,'_',category)
  # if the result is already in memory, do nothing
  if (exists("result") && result$matrixid == matrixid && result$num_features == num_features && result$maxit == maxit) {
    return(result)
  }
  
  # if the result exists on disk, load it
  # can't have slashes in file names    
  filename<-paste0(datadir,"result_",gsub("/", "", matrixid),"_",num_features,"_",maxit,".rda")
  # this is to load the result (if we don't have it and a file exists)
  if (file.exists(filename)) {
    load(filename)
    return(result)
  }
  
  # if we don't have the result, create it and then save it to disk
  # if we don't have the matrix to create it with, load that first
  if(!exists(matrixid)) {
    # create the matrix
    print("you need to create the matrix before you get results for it")
    return()
  }
  matrix<-eval(parse(text=matrixid))
  
  print(system.time(
    result<-optimize(matrix,num_features,maxit)
  ))
  save(result,file=filename)
  return(result)
}



# this is to create the result (if it does not exist)
# 10 features 100 iterations


# the result is a set of composite matrices - we can use them to make predictions
#iter  850 value 5451.932083
#final  value 5451.931944 
#converged
#user  system elapsed 
#45.412  12.399  57.776 

###result<-loadresult("sparse_s",25,1000)

# the dataset is too large to process in a reasonable time, so we need to break it down
# we will only make recommendations within a particular ocation, and particular category
# so segmenting the data long these lines makes sense.


# the result from optimize does not contain an id
train<-function(reduced) {
  num_features<-min(dim(reduced))-1
  maxit<-1000
  print(paste(num_features,"features"))
  result<-optimize(reduced,num_features,maxit)
  return(result)
}

# sparse matrix does not work
# we may need the full matrix
if (!exists("reviews")) {
  load(paste0('/data/',"review.rda"))
  reviews<-r_data[,c("user_id","business_id","stars")]
}

sparseMatrixWithNames<-function(triplet) {
  # the triplet form is assumed to have names for the rows and columns
  rownames<-unique(triplet[,1])
  colnames<-unique(triplet[,2])
  nrows<-length(rownames)
  ncols<-length(colnames)
  sparse<-Matrix(data=0,nrow=length(rownames), ncol=length(colnames), sparse=TRUE, dimnames=list(rownames,colnames))
  for(i in 1:nrow(triplet)) {
    sparse[triplet[i,1],triplet[i,2]] <- triplet[i,3]
  }
  return(sparse)
}

doallthetraining<-function() {
  load("cat.rda")
  load("bus.rda")
  load("businesses.rda")
  load("cities.rda")
  
  # we'll start with getting restaurant reviews for all 10 locations
  for (category in cat) {
    
    citynames<-c('Edinburgh', 'Karlsruhe', 'Montreal', 'Waterloo', 'Pittsburgh', 
                 'Charlotte', 'Urbana-Champaign', 'Phoenix', 'Las Vegas', 'Madison\ WI')
    
    
    for (cityname in citynames) {
      
      print(paste("starting to train",cityname,category))

      # skip it if we have a file already
      fileglob<-paste0(datadir,"result_",cityname,"_",category,"_*.rda")
      if (length(Sys.glob(fileglob))>0){
        print("already done, skipped")
        next
      }
      
      
      # identify all businesses in a location in a category  
      # this gives the city's real index
      city<-which(cities$cityname==cityname)
      minlat<-cities[city,3]-1
      maxlat<-cities[city,3]+1
      minlon<-cities[city,2]-1
      maxlon<-cities[city,2]+1
      # use all the business map data - but restrict to nearby the city center
      criteria<-(businesses$lat>minlat)&(businesses$lat<maxlat)&(businesses$lon>minlon)&(businesses$lon<maxlon)
      criteria<-criteria & (businesses$business_id %in% bus[cat==category])
      
      # using the full sparse matrix, select out only those businesses in the criteria
      reduced<-reviews[reviews$business_id %in% bus[criteria],]
      # then select out those users with at least one review
      # this is also a sparse matrix, and we need to train it
      # this is specific to a cityname and category
      # the number of features might actually match the number of businesses
      print(paste(nrow(reduced),"reviews"))
      
      if (nrow(reduced)>1) {
        #no point in trying for less than 2 reviews
        # befpre converting to sparse, need to convert ids to indexes
        sparsed<-sparseMatrixWithNames(reduced)
        
        result<-train(sparsed)
        result$matrixid<-paste0(cityname,"_",category)
        saveresult(result)
      }
    }    
  }
  
}
