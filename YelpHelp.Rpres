Yelp Help
========================================================
author: bartold
date: November 2015

Business Recommendations for Yelp Reviewers

Business Recommendations for Yelp Reviewers
========================================================

The Yelp Dataset Challenge (http://www.yelp.com/dataset_challenge) contains a massive amount of recommendations for local businesses.

The dataset contains recommendations for different types of businesses in different locations.

We'd like to give something back to all those who write the reviews.

There are over 1.5 million reviews from over 360 thousand users. When a user goes to Yelp they can see what others say, but everyone is different.

Wouldn't it be great if the the users reviews could be compared against others so that recommendations for places to go were more informed?

The Dataset is Huge and really Sparse
========================================================

It seems lie there's too much and too little information at the same time. 

Just looking at the business ratings, we already have a good place to start. If one user consistently rates businesses similarly to someone else then we should be able to weight revies from those users more heavily for each other thn someone's reviews who always disagree. This is the idea behind recommender systems.

Normally a user has to spend a lot of time and effort to find someone who has similar tatses, and then it might not help if they have been to all the same businesses. We need a way to summarize eveyone at once.


Recommendations and Recommenders
========================================================

Some of the most interesting recomendation ideas have come out of the NetFlix competitions. One of the shining examples is Matrix Factorization.

There are lots of ways to do matrix factorization, but we have a special case here. The data is very, very sparse, less than 1/10,000 ratings are filled in. The matrix is too big to handle in reasonable compute time.

So we've divided it up. Many of the recomendations are not related to each other anyway. A recomendation for a Dentist is unlikely to inform a recomendation for a Thai Restaurant. A recomendation In Phoenix is unlikely to inform one in Edinburg.

The recomendations are focused and relevant and we present them with high confidence.

A Shiny way to go!
========================================================

We've packaged this up into a Shiny App and present it for your perusal.

Head on over to the [Yelp Help App](http://bartold.shinyapps.io/YelpHelp/)

The first panel presents the world map with the locations that have review data. Selecting a location zooms into a map with all reviews in the area.

Selecting a business Category reduces the businesses on the map to just those in the Category.

Selecting a user number will give the recommendations for that user in that location for that category, but only if that user has specifically rated at least one such business. Th more businesses a user rates, the more useful the App will become.

The complete code for this presentation, and the app itself, is at [GitHub](http://github.com/tbartold/YelpHelp)
