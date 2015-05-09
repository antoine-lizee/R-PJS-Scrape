# getAndParse.R
# Main script to query the kayak page of interest, parse the results, and feed the database.
#
# Copyright Antoine Lizee 2015/05 antoine.lizee@gmail.com 

# Parameters --------------------------------------------------------------

doStore <- T
doQuery <- T

# File names
pageFile <- "test.html"
dbname <- "kayakResults.sqlite"

# URLs
baseURL <- "http://www.kayak.com/flights"
destinations <- "SFO-PAR"
goDates <-"2015-05-29-flexible"
returnDates <- "2015-06-24-flexible"

# Build URL
fullUrl <- paste(baseURL, destinations, goDates, returnDates, sep = "/")


# Initialization ----------------------------------------------------------
suppressMessages({
  library("XML")
  library("RSQLite")
  library("reshape2")
})

cat("# KAYAK scraping script run as", system("whoami", intern = T), "on", format(t0 <- Sys.time()) ,"...\n")

# Get in the correct directory when launched from 'Rscript'
cmdArgs <- commandArgs(trailingOnly = FALSE)
needle <- "--file="
match <- grep(needle, cmdArgs)
if (length(match) > 0) {
  setwd(dirname(normalizePath(sub(needle, "", cmdArgs[match]))))
}

# Launch the scraping -----------------------------------------------------

if (doQuery) {
  
  cat("## Querying webpage...\n")
  ti <- Sys.time()
  system(paste0('~/local_software/phantomjs/bin/phantomjs dumpHTML.js ', fullUrl))
  cat("...done. (in ", format(Sys.time() - ti),")\n", sep = "")
  
}

# Parse the page ----------------------------------------------------------

cat("## Parsing webpage...\n")
ti <- Sys.time()
# Get the price matrix
flexTable <- readHTMLTable(pageFile, stringsAsFactors = F)$flexmatrixcontent
flexResults <- sapply(flexTable[2:8, 2:8], function(v) as.numeric(gsub("$", "", v, fixed = T)))
dimnames(flexResults) <- list( flexTable[2:8,1], flexTable[1,2:8])

# Get the first displayed results
page <- htmlParse(pageFile)
xPath1 <- '//div[@class="resultsWrapperSection flightlist"]/*'
xPathPrice <- './/div[@class="pricerange "]'
xPathCompany <- './/div[@class="airlineName "]'
xPathCompany <- './/div[starts-with(@class, "airlineName")]'
xPathDurations <- './/div[@class="duration"]'
xPathDates <- './/div[@class="baggageFees hdr_message"]'
results <- xpathApply(page, xPath1, function(n) {
  priceNode <- getNodeSet(n, xPathPrice)
  if(length(priceNode) != 1) {
    return(NULL)
  }
  price <- as.numeric(gsub("\n|\\$", "", xmlValue(priceNode[[1]])))
  
  company <- gsub("\n", "", xmlValue(getNodeSet(n, xPathCompany)[[1]]))
  
  durationInfo <- xpathSApply(n, xPathDurations, function(cn) gsub("\n|\\$", "", xmlValue(cn)))
  durations <- as.numeric(as.difftime(durationInfo, format = "%Hh %Mm "))
  
  dateInfo <-  gsub("\n", "", xmlValue(getNodeSet(n, xPathDates)[[1]]))
  tripDuration <- as.numeric(gsub(".*Trip spans |days.*$", "", dateInfo))
  dates <- strsplit(dateInfo, split = " – ")[[1]]
  goDate <- dates[1]
  returnDate <- strsplit(dates[2], " [[:punct:]] ")[[1]][1]
  
  return(data.frame(price = price, company = company, 
                    d1 = durations[1], d2 = durations[2], 
                    trip_duration = tripDuration,
                    go_date = goDate, return_date = returnDate))
})

results <- do.call(rbind,results)
cat("...done. (in ", format(Sys.time() - ti),")\n", sep = "")


# Store Results -------------------------------------------------------------------

if (doStore) {
  
  cat("## Storing results...\n")
  
  addTimeStamp <- function(df) {
    data.frame(df, created_at = as.character(Sys.time()))
  }
  
  flexResultsTable <- melt(flexResults, value.name = "price", varnames = c("go_date", "return_date"))
  finalTables <- lapply(list(results, flexResultsTable), addTimeStamp)
  names(finalTables) <- c("results", "flexResults")#, "companyResults")
  
  tryCatch({
    con <- dbConnect(SQLite(), dbname = dbname)
    isWritten <- mapply(function(name, table) dbWriteTable(con, name, table, append = T), names(finalTables), finalTables)
    if (!all(isWritten)) {
      cat("## ERROR IN WRITING DATA ##")
      print(isWritten)
    }
  },
  finally = dbDisconnect(con))
  cat("...done. (in ", format(Sys.time() - ti),")\n", sep = "")
  
}

cat("## Completed script in ", format(Sys.time() - t0),", exiting now. Thank you!\n\n*******************\n\n\n", sep = "")

