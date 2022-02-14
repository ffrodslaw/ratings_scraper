library(dplyr)
library(rvest)
library(data.table)

###########

setwd()   # set your working directory

###########

# country list

ratingpage <- "https://tradingeconomics.com/country-list/rating"
rating <- read_html(ratingpage)

chart <- rating %>%       
  rvest::html_nodes('body') %>%                             # search body of html
  xml2::xml_find_all("//table[contains(@class, 'table')]")  # get all table elements

countries_table <- html_table(chart)[[1]]

countries_df <- data.frame(countries_table)

####################

# download data for all countries

# list of countries from table above
countries_list <- countries_df[,1]

# loop
country_ratings <- list()
for(i in 1:length(countries_list)){
  countryname <- gsub(" ", "-", countries_list[i])       # replace spaces in country names with dashes
  
  ratingpage <- paste0("https://tradingeconomics.com/", countryname, "/rating")
  
  tryCatch({
    rating <- read_html(ratingpage)
    
    chart <- rating %>% 
      rvest::html_nodes('body') %>% 
      xml2::xml_find_all("//table[contains(@class, 'table')]")
    
    ratings_table <- html_table(chart)[[1]]
    
    country_ratings[[i]] <- data.frame(cbind(countryname, ratings_table))
    
    print(countryname)
  }, error = function(e){cat("ERROR with ", countries_list[i], ":",conditionMessage(e), "\n")}) # print error message if code fails
}

# unlist into one data frame
country_ratings_df <- rbindlist(country_ratings)

colnames(country_ratings_df) <- c("country", "agency", "rating", "outlook", "date")

country_ratings_df$date <- as.Date(country_ratings_df$date, "%B %d %Y")

country_ratings <- country_ratings_df

# save
save(country_ratings, file = "ratings.Rdata")
