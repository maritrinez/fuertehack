# DATA IMPORT

# Set the working directory (where the files are being to be loaded from and where they are going to be saved)

getwd()
setwd("~/Dropbox/IntroduccionR")


# Download the home page http://contributors.rubyonrails.org/ and save it as *.txt
url <- "http://contributors.rubyonrails.org/"
download.file(url, destfile = "Data/contributors00.txt")

# Load the contributors00.txt file into R
contributors <- readLines("Data/contributors00.txt")
contributors[60:70]  # Have a look at some lines



# Once we have the homepage saved and loaded into R, we need to extract a vector with the URLs for every contributor page.
# We will find the URLs in the homepage code by using regular expressions.

contributorsLines <- grep("highlight", contributors, fixed = TRUE, value = TRUE)  # Extract the lines where the contributors' names are, formatted to create the URL to their pages.

r <- gregexpr("/contributors/(.*)/commits", contributorsLines)  # Get two indices: where the match starts and the match's length.
contributorsURL <- regmatches(contributorsLines, r)  # Get the registered matches.
contributorsURL <- paste("http://contributors.rubyonrails.org", contributorsURL, sep="")  # Paste the registered matches to the main URL.

head(contributorsURL)  # We have now the URLs vector, containing every URL for each contributor page.





# Now, download every contributor page as *.txt, load into R and get the data we want (contributor name, rank, date, message)

# This may take a looong time, so you'd better download the resultant *.csv

urlCsv <- "https://github.com/beamartinez/fuertehack/blob/master/Data/contributorsdf.csv"
download.file(urlCsv, destfile = "contributorsdf.csv", method = "curl")  # method must be set to 'curl' as it is a secure URL (https)
contributorsdf <- read.csv("contributorsdf.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)


# Uncomment the code below to run the whole process (just remember it takes a time; it depends on your internet connection, but it took me more than half an hour)

# contributorsdf <- data.frame()  # Create an empty data.frame where store the data as it is being extracting from the contributors' pages.

# for (i in (1:length(contributorsURL))){  # For every contributors' page

## Download it		
# url2 <- contributorsURL[i]
# download.file(url2, destfile = paste("Data/contributor",i,".txt", sep = ""))
# contributor <- readLines(paste("Data/contributor",i,".txt", sep = ""))  

## Generate a vector with the commits dates.
# date <- grep("commit-date", contributor, fixed = TRUE, value=TRUE)
# r <- gregexpr("[0-9]{4}-[0-9]{2}-[0-9]{2}", date)
# date <- unlist(regmatches(date,r))

## Another one with the commit messages.
# message <- grep("commit-message", contributor, fixed = TRUE, value = TRUE)
# r <- regexec(">(.*)<", message)
# message <- regmatches(message, r)
# message <- sapply(message, function(x) x[2])

## Extract the contributors' names and ranks.
# r <- regexec("Rails Contributors - #(.*?) (.*) -", contributor)
# m <- unlist(regmatches(contributor, r))
# rank <- m[2]  
# name <- m[3]

## Join the four vectors (date, message, name and rank) in a data.frame
# tableContributor <- as.data.frame(cbind(date, message))
# tableContributor$name <- name
# tableContributor$rank <- rank

## Store this data in the empty data.frame created before the for loop.
# contributorsdf <- rbind(tableContributor, contributorsdf)
#}


# The data.frame with the data we wanted is ready.
head(contributorsdf)

# Now you can save it (new data have been generated in R !)
write.csv(contributorsdf, file = "Data/contributorsdf.csv", row.names = FALSE)

# And load the file again to use it as input data.
contributorsdf <- read.csv("Data/contributorsdf.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)



# DATA TREATMENT

# Have a look at the data and get information about the object.
str(contributorsdf)
summary(contributorsdf)


# Change an object class
contributorsdf$date <- as.Date(contributorsdf$date, "%Y-%m-%d")
summary(contributorsdf)


# Remove one register
contributorsdf <- contributorsdf[which(contributorsdf$date != "1970-01-01"), ]  # The date was wrong, so we remove the whole observation.
nrow(contributorsdf)

# Add some information from other data.frame.
# E.g.: Assign a country to each contributor (not the real one this time).

# Download the countries list (with their codes) and load it into R.
urlCountries <- "https://dl.dropboxusercontent.com/s/c8nlins4davcnz8/ISOcountries.csv?token_hash=AAGb1r0-10fvR-q_eLY6-f5XtshKkYR0jXXFDHQ1mdOY3A&dl=1"
download.file(urlCountries, destfile = "Data/ISOcountries.csv", method = "curl")
ISOcountries <- read.csv("Data/ISOcountries.csv")
head(ISOcountries)

# Generate a vector which will have the same length that the number of contributors 
codes <- sample(ISOcountries$codes, length(unique(contributorsdf$name)), replace = TRUE)  

# Get a vector containing the contributors names without repetitions
uniqueContributors <- unique(as.character(contributorsdf$name)) 

# Join both vectors into a data.frame and merge to ISOcountries to add the countries' names.
countries <- data.frame(uniqueContributors, codes)
countries <- merge(countries, ISOcountries, by = "codes")  
head(countries)

# Merge the 'countries' data.frame with the contributorsdf 
contributorsdf <- merge(contributorsdf, countries, by.x = "name", by.y = "uniqueContributors")
str(contributorsdf) # Two new variables have been added to the data.frame, 'codes' and 'countries'

# Split the 'date' variable in other two: 'year' and 'month'
dates <- strsplit(as.character(contributorsdf$date), "-")
contributorsdf$year <- sapply(dates, function(x) x[1])
contributorsdf$month <- sapply(dates, function(x) x[2])
rm(dates)

# Subset the top 10 contributors
freqCommits <- data.frame(table(contributorsdf$name))	# Get the frequency table of commits per contributor.
names(freqCommits)  # The given names are not very intuitive.
names(freqCommits) <- c("name", "Freq")  # Change the columns names.

freqCommits <- freqCommits[order(-freqCommits$Freq), ]  # Sort the values in decreasing order.
head(freqCommits)  # Have a look at the firsts rows 

top10 <- as.character(freqCommits$name[1:10])  # Get a vector with the top 10 contributors names (from a factor, that is why 'as.character' should be used).

top10contributors <- contributorsdf[contributorsdf$name %in% top10, ]  # Subset the observations related to the top 10 contributors from the main data.frame.

unique(top10contributors$name)
identical(sort(unique(top10contributors$name)), sort(top10))

rm(freqCommits, top10)  # Remove the unnecessary objects.




# DATA ANALYSIS

# Get frequency tables

# number of commits per year
table(contributorsdf$year)
mean(table(contributorsdf$year)) # mean of commits per year for the period 2004-2013


# number of commits per month and year
freqYM <- table(contributorsdf$year, contributorsdf$month)
freqYM

margin.table(freqYM, 1)  # 'year' frequencies (summed over 'month') 
margin.table(freqYM, 2)  # 'month' frequencies (summed over 'year')

prop.table(freqYM)  # Cell percentages
prop.table(freqYM, 1)  # Row percentages 
prop.table(freqYM, 2)  # Column percentages

colMeans(freqYM)  # Monthly means
rowMeans(freqYM)  # Yearly means

# Commits by contributor per year (only for the top ten contributors) 
freqYC <- table(top10contributors$year, top10contributors$name)  
colMeans(freqYC)  # Mean of commits per year by contributor

# Cross tables

xtabs(~name+year, data=top10contributors)  # Commits by contributor per year 
xtabs(~name+month+year, data=top10contributors)  # Commits by contributor per year and month
ftable(xtabs(~name+month+year, data=top10contributors))  # flat table: easy to read table

# Correlation
nContributors <- tapply(contributorsdf$name, contributorsdf$year, function(X) length(unique(X)))  # Get the number of unique contributors per year
nCommits <- tapply(contributorsdf$name, contributorsdf$year, function(X) length(X))  # Get the number of commits per year
e <- data.frame(cbind(nCommits, nContributors))
e
cor(e$nContributors, e$nCommits)



# GRAPHICS


# Plot every commit
plot(contributorsdf$date, factor(contributorsdf$name))


# Plot every commit formating the plot
plot(contributorsdf$date, factor(contributorsdf$name), 
	 main = "Total Commits", 
	 xlab = "Date", 
	 ylab = "contributors",
	 col = rgb(0,100,0,40,maxColorValue=255),
	 pch = 18
)
# See ?par 



#Library ggplot2 for nicer graphics (based on layers)
library(ggplot2)

# Plot the top ten contributors' commits
p <- ggplot(top10contributors, aes(date, name))
p + geom_point()
p + geom_point(alpha = 0.2, size = 3, aes(colour = factor(name)), show_guide = FALSE) 

# Plot commits per month 
# Bargraph
m <- ggplot(contributorsdf, aes(month))
m + geom_bar(fill = "darkblue")

# Stacked bars
m <- ggplot(contributorsdf, aes(month, fill=year)) 
m + geom_bar() + coord_flip()

# Plot them in a grid
m <- ggplot(contributorsdf, aes(month)) +  geom_bar(aes(fill=year))
m + facet_grid(year ~ .)+ theme(legend.position = "none")

# Lines plot
m <- ggplot(contributorsdf, aes(month, colour = year, group = year))
m+geom_freqpoly()

# Plot the number of commits ~ number of contributors and its regression line
p <- ggplot(e, aes(nContributors, nCommits))
p + geom_smooth(method='lm', colour = "#CC79A7", se = FALSE) + 
	geom_point(alpha = 0.8, size = 5, colour = "#009E73") +
	xlab("Number of contributors") +  # Set x-axis label
	ylab("Number of commits") +   
	annotate("text", label = "Correlation = 0.88", x = 700, y = 150, colour = "#CC79A7") +  # Prints the correlation index
	theme(axis.title = element_text(size = rel(1.4), colour = "#006348"),  # Change the appearance
		  axis.title.x = element_text(vjust = 0.1),
		  axis.title.y = element_text(vjust = 0.25),
		  axis.text = element_text(size = rel(1.2)),
		  panel.background = element_rect(fill = "#F5F6CE")
	)



# Plot a map

# Download the necessary libraries
if (!"sp" %in% installed.packages()) install.packages("sp")
if (!"maptools" %in% installed.packages()) install.packages("maptools")

# Load them into R
library(sp)
library(maptools)


data(wrld_simpl)  # Get a World map where to plot the variable (number of commits by country this time)
commitsMap <- wrld_simpl
class(commitsMap)

# Get the frequency table for the countries
countriesFreq <- as.data.frame(table(contributorsdf$codes))
head(countriesFreq)


# Merge the countries frequency table with the commitsMap@data, the 'data.frame' inside the SpatialPolygonsDataFrame
commitsMap@data <- merge(commitsMap@data, countriesFreq, by.x = "ISO2", by.y = "Var1", all.x=T)

head(commitsMap@data)  # A new variable has been added

# Set a bunch of colors. (So many by default in the "RColorBrewer" library)
colors <- c("#1D3140", "#1C3D4D","#194A58","#125862","#09666A","#047370","#0B8174","#1C8F76","#309D77","#46AA75","#5DB872","#76C46E","#91D069","#AEDB64","#CDE660","#EDEF5D")  # Copy pasted from http://tristen.ca/hcl-picker/

# Plot the SpatialPolygonsDataFrame
spplot(commitsMap, "Freq", col.regions = rev(colors), 
	   par.settings = list(
	   	panel.background = list(col="#CEE3F6"), 
	   	add.line = list(col = "#F5F6CE", lwd = .2)))



# Save any plot as *.png
png(file = "Images/commits_map.png", height = 480, width = (480*2))
spplot(commitsMap, "Freq", col.regions = rev(colors), 
	   par.settings = list(
	   	panel.background = list(col="#CEE3F6"), 
	   	add.line = list(col = "#F5F6CE", lwd = .2)))
dev.off()



# Plot Fuertehack contributors

people <- c("Fernando Guillén", "Juanjo Bazán", "Fernando Blat","Paco Guzman","Christos Zisopoulos","Alberto Perdomo")

peopleData <- contributorsdf[contributorsdf$name %in% people, ]

p <- ggplot(peopleData, aes(date, name))
p + geom_point(alpha = 0.8, size = 4, aes(colour = factor(name)), show_guide = FALSE) 
