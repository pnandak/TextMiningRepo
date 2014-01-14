

# need to provide workshop attendees zip file with directory structure;
# probably need to provide instructions about where to unzip;
# test that out on your computer!

# toy example of turning text into numbers
setwd("~/workshops/Text Mining/docs")
# save files name to vector
(files <- dir())

# create a vector to store content of files
allData <- rep(NA,length(files))

# a for loop that reads the lines of each file
for(i in 1:length(files)){
  allData[i] <- readLines(files[i])  
}
allData # vector; each element contains content of text files

# load tm, a text mining package for R
library(tm)
# first create a Corpus, basically a data base for text documents
doc.corpus <- Corpus(VectorSource(allData))
inspect(doc.corpus)
inspect(doc.corpus[3])
# next create a basic Term Document Matrix (rows=terms, columns=documents)
doc.tdm <- TermDocumentMatrix(doc.corpus)
inspect(doc.tdm) 
# notice...
# - all words reduced to lower-case
# - punctuation included
# - only words with 3 or more characters included (see wordLengths option in termFreq documentation)
# If we wanted to include words with two or more characters:
# doc.tdm <- TermDocumentMatrix(doc.corpus, control=list(wordLengths = c(2, Inf)))


# apply transformations to corpus
# make all lower-case in advance; helps with stop words
doc.corpus <- tm_map(doc.corpus, tolower) 
inspect(doc.corpus)
# remove lower-case stop words
# see stop words: stopwords("english")
doc.corpus <- tm_map(doc.corpus, removeWords, stopwords("english")) 
inspect(doc.corpus)
# remove punctuation
doc.corpus <- tm_map(doc.corpus, removePunctuation) 
inspect(doc.corpus)
# remove numbers
doc.corpus <- tm_map(doc.corpus, removeNumbers) 
inspect(doc.corpus)

# if you want to add stopwords:
# tm_map(doc.corpus, removeWords, c(stopwords("english"),"custom","words")) 

doc.tdm <- TermDocumentMatrix(doc.corpus)
inspect(doc.tdm)
# notice...
# - all words reduced to lower case
# - punctuation and numbers gone
# - stopwords gone
# - no distinction between Iron in "Iron Mainden" and the iron for pressing clothes
# - weighting is simple term frequency

# Important to know how Corpora and TDMs are created. They will often be huge and not
# easily checked by eye.



# Weight a term-document matrix by term frequency - inverse document frequency (TF-IDF)
# Idea: words with high term frequency should receive high weight unless they also have
# high document frequency

inspect(weightTfIdf(doc.tdm))



# Zipf's law: the frequency of any word is inversely proportional to its rank in the frequency table.
Zipf_plot(doc.tdm, type = "l")
# Heaps' law: the vocabulary size V grows polynomially with the text size T ( total number of terms in the texts)
Heaps_plot(doc.tdm, type = "l")


meta(doc.corpus[[1]], tag="Description")  <- "some text"
DublinCore(doc.corpus)

# text mining for sentiment
setwd("C:/Users/jcf2d/Documents/workshops/Text Mining")
load("K:/statlab/tweets/R code and files/data/sample.tweets.Rda")
tweets <- sample.tweets$tweets

# A list of positive and negative opinion words or sentiment words for English
# (around 6800 words). This list was compiled over many years starting from 
# Hu and Liu, KDD-2004.

# http://www.cs.uic.edu/~liub/FBS/opinion-lexicon-English.rar

poswords <- scan("workshops/Text Mining/opinion-lexicon-English/positive-words.txt",
                 what="character", comment.char=";")
negwords <- scan("workshops/Text Mining/opinion-lexicon-English/negative-words.txt",
                 what="character", comment.char=";")

# can add extra words if we need to
poswords <- c(poswords, "HoosForSullivan")

#' score.sentiment() implements a very simple algorithm to estimate
#' sentiment, assigning a integer score by subtracting the number 
#' of occurrences of negative words from that of positive words.
#' 
# https://raw.github.com/jeffreybreen/twitter-sentiment-analysis-tutorial-201107/08a269765a6b185d5f3dd522c876043ba9628715/R/sentiment.R

library(stringr) # needed for str_split

# function for calculating sentiment analysis
score.sentiment <- function(tweet){
  # remove punctuation
  tweet <- gsub("[[:punct:]]","",tweet)
  # remove control characters
  tweet <- gsub("[[:cntrl:]]","",tweet)
  # remove digits
  tweet <- gsub("[[:digit:]]","",tweet)
  # make lower case
  tweet <- tolower(tweet)
  # split tweet into words
  words <- unlist(str_split(tweet,"[[:space:]]"))
  # compare words to dictionaries of positive/negative terms
  pos.matches <- match(words, poswords)
  neg.matches <- match(words, negwords)
  # create a vector of T/F to see if any matches
  pos.matches <- !is.na(pos.matches)
  neg.matches <- !is.na(neg.matches)
  # create score
  return(sum(pos.matches) - sum(neg.matches))
}

sapply(tweets,score.sentiment)
sapply(tweets,score.sentiment, USE.NAMES=F) # just scores



# extracting knowledge from published literature --------------------------

# CLAY: For this one I think we just want to extract journal titles from the XML
# and skip the part where we create a list object from the XML;
# that takes too long.


# http://www.ncbi.nlm.nih.gov/pubmed
# search for asperger syndrome behavior
# http://www.ncbi.nlm.nih.gov/pubmed/?term=asperger+syndrome+behavior
# can save search results; use "send to...file"
# Abstract(text) = unstructured text

# pattern
# 1. journal info
# 2. title
# 3. authors
# 4. affiliation (sometimes missing)
# 5. abstract (sometimes missing)
# 6. PMID/end

# read text into one vector
pmData <- readLines("workshops/Text Mining/pubmed_result.txt")
pmData[1:25] # inspect

# using "send to...citation"; can only save up to 200
pmData2 <- readLines("workshops/Text Mining/citations.nbib")
pmData2[1:50] # inspect

# CSV does not have abstract

# XML has descriptive tags
# use "Send to...file, Format = XML"
# can view in text editor such as notepad++; has syntax highlighting
library(XML)
# short intro to XML package
# http://www.omegahat.org/RSXML/shortIntro.pdf
doc <- xmlInternalTreeParse("workshops/Text Mining/pubmed_result.xml")
# do this to get at the data:
top <- xmlRoot(doc)
# top is a list
# open XML file and compare
top[[1]] # first "record"
names(top[[1]])

top[[1]][[1]]
names(top[[1]][[1]])

# see first article title
top[[1]][[1]][[3]][[2]]
# can also do this:
top[[1]][[1]][["Article"]][["ArticleTitle"]]

# extract first article title
xmlSApply(top[[1]][[1]][[3]][[2]], xmlValue)

# get all article titles using xpathApply
articles <- xpathApply(top, "//ArticleTitle", xmlValue)


top[[1]][[1]][[3]]
top[[1]][[1]][["Article"]][["Abstract"]]


# see its name:
xmlName(top)
# how many sub-nodes (in this case, articles)
xmlSize(top)
length(names(top)) # same thing

# can do the same for the children
xmlName(top[[1]])
xmlSize(top[[1]])

xmlName(top[[1]][[1]])
xmlSize(top[[1]][[1]])
xmlAttrs(top[[1]][[1]]) # see attributes

# Applying an operation to children of a node is so common that we provide functions
# xmlApply
# () and
# xmlSApply
# () which are simple wrappers whose primary role is to fetch the list of children of the specified
# node.

xmlSApply(top[[1]], xmlName)
xmlSApply(top[[1]][[1]], xmlName)
# returns all values jammed together; probably not what we want in this case
xmlSApply(top[[1]][[1]], xmlValue) 

# extract just abstract text from first record
xmlSApply(top[[1]][[1]][["Article"]][["Abstract"]], xmlValue)



# extract all information from first record; again not what we would want
xmlSApply(top[[1]], xmlValue)

# extract just abstract text from first record
test <- xmlSApply(top[[1]][[1]][["Article"]][["Abstract"]], xmlValue)
test
# extraxt all records
test2 <- xmlSApply(top, function(x) xmlSApply(x, xmlValue))

# get all abstracts using xpathApply
abstract <- xpathApply(top, "//Abstract", xmlValue)
# get all journal titles using xpathApply; returns list
journal <- xpathApply(top, "//Title", xmlValue)
# get all journal titles using xpathSApply; returns vector
journal <- xpathSApply(top, "//Title", xmlValue)
summary(factor(journal))
table(factor(journal))
journalCounts <- data.frame(table(factor(journal)))
journalCounts[order(journalCounts$Freq, decreasing=T),][1:10,]


# notice the number of abstracts and journals differ

# another way that makes sense to me
# use list and extract items one by one
# first convert XML to list
pmData <- xmlToList(doc) # this can take a long time!!!
pmData[[1]] # first record
str(pmData[[1]]) # structure of first record

# journal title
# $MedlineCitation$Article$Journal$Title
# this extracts just the journal titles as a list
jtitle <- lapply(pmData, function(xl) xl$MedlineCitation$Article$Journal$Title)
class(jtitle)
# before we can unlist we need to replace any NULL values with NAs
jtitle <- lapply(jtitle, function(x)ifelse(is.null(x), NA, x))
# make into vector
jtitle <- unlist(jtitle)
jtitle[1:5] # look at first 5 titles
# get rid of the names
names(jtitle) <- NULL
jtitle[1:5] # look at first 5 titles

# article title
# $MedlineCitation$Article$ArticleTitle
atitle <- lapply(pmData, function(xl) xl$MedlineCitation$Article$ArticleTitle)
atitle <- lapply(atitle, function(x)ifelse(is.null(x), NA, x))
atitle <- unlist(atitle)
names(atitle) <- NULL

# year
# $MedlineCitation$Article$Journal$JournalIssue$PubDate$Year
year <- lapply(pmData, function(xl) xl$MedlineCitation$Article$Journal$JournalIssue$PubDate$Year)
year <- lapply(year, function(x)ifelse(is.null(x), NA, x))
year <- unlist(year)
names(year) <- NULL

# abstract
# $MedlineCitation$Article$Abstract$AbstractText$text (this doesn't work)
# $MedlineCitation$Article$Abstract$AbstractText (this does)
abstract <- lapply(pmData, function(xl) xl$MedlineCitation$Article$Abstract$AbstractText)
abstract <- lapply(abstract, function(x)ifelse(is.null(x), NA, x))
abstract <- unlist(abstract)
names(abstract) <- NULL


# $PubmedData$ArticleIdList$ArticleId$text
pmid <- lapply(pmData, function(xl) xl$PubmedData$ArticleIdList$ArticleId$text)
pmid <- lapply(pmid, function(x)ifelse(is.null(x), NA, x))
pmid <- unlist(pmid)
names(pmid) <- NULL


# make a data frame
allData <- data.frame(pmid, atitle, abstract)
allData$pmid <- as.character(allData$pmid)
allData$atitle <- as.character(allData$atitle)
allData$abstract <- as.character(allData$abstract)
str(allData)
# any missing abstracts?
which(is.na(allData$abstract)) # yes
# remove those records
allData <- allData[!is.na(allData$abstract),]

# barplot of articles by year
plot(allData$year)

# top 10 journals by number of articles
sort(table(allData$jtitle), decreasing=TRUE)[1:10]

# now ready to use tm package
library(tm)

# allCorpus <- Corpus(VectorSource(allData$abstract)) # this takes a few moments
allCorpus <- Corpus(VectorSource(allData$atitle))

allCorpus <- tm_map(allCorpus, tolower)
allCorpus <- tm_map(allCorpus, stripWhitespace)
allCorpus <- tm_map(allCorpus, stemDocument)
allCorpus <- tm_map(allCorpus, removeWords, stopwords('english'))

dtm <- DocumentTermMatrix(allCorpus, control = list(removePunctuation = TRUE,
                                                 removeNumbers = TRUE,
                                                 bounds = list(global = 
                                                                 c(floor(length(allCorpus)*0.01), 
                                                                   floor(length(allCorpus)*0.90)))))
dim(dtm)[2] # see number of words in DTM
# changing lower bound from 0.10 to 0.05 adds 200 words to DTM
# changing upper bound from 0.70 to 0.80 adds 1 word to DTM

# tdm <- TermDocumentMatrix(allCorpus, control = list(removePunctuation = TRUE,
#                                                     removeNumbers = TRUE,
#                                                     bounds = list(global = 
#                                                                     c(floor(length(allCorpus)*0.10), 
#                                                                       floor(length(allCorpus)*0.70)))))


# inspect the DTM
inspect(dtm[1:5,1:5])
dim(dtm)
nTerms(dtm)
nDocs(dtm)
colnames(dtm) # see terms

findAssocs(dtm,"bayesian",0.2)
library(proxy)
dissimilarity(dtm, method = "cosine")

Zipf_plot(dtm)
Heaps_plot(dtm)

dtm2 <- weightTfIdf(dtm, normalize = TRUE)
inspect(dtm2[1:5,1:5])
dim(dtm)
nTerms(dtm)
nDocs(dtm)
colnames(dtm) # see terms



# descriptive data
# top 10 most frequently occuring words
sort(apply(as.matrix(dtm),2,sum), decreasing=TRUE)[1:10]
# another way
slam::col_sums(dtm)
sort(slam::col_sums(dtm), decreasing = TRUE)[1:10]

pmData.sd <- scale(dtm)
pmData.sd2 <- scale(dtm2)

# gs <- sample(1:dim(pmData.sd)[1],50, replace=TRUE)
# pmData.sdx <- pmData.sd[gs,]

# data.dist <- dist(pmData.sd)
# data.distx <- dist(pmData.sdx)


# doing distance matrix by hand
# "dist function computes and returns the distance matrix computed by using the specified distance
# measure to compute the distances between the ROWS of a data matrix"
mat <- as.matrix(pmData.sd)
mat[1:5,1:5]
dist(mat[1:5,1:5])
mat[1:5,1:5][1,]
sqrt(t(mat[1:5,1:5][1,]-mat[1:5,1:5][2,])%*%(mat[1:5,1:5][1,]-mat[1:5,1:5][2,]))


# higherarchical clustering - do not need to specify number of groups
hc.out <- hclust(dist(pmData.sd))
hc.clusters <- cutree(hc.out,k=20) # k = # of groups; h = height of cut
plot(hc.out) # dendrogram
abline(h=25,lty=2) # add a line to show a cut point
table(hc.clusters)

# how are they similar within clusters?
allData[allData$hc.clusters==6,"atitle"]
allData[allData$hc.clusters==10,"atitle"]

# k-means clustering - have to specify number of groups
set.seed(9)
km.out <- kmeans(pmData.sd, 20, nstart=50)
km.clusters <- km.out$cluster  
table(km.clusters)
table(km.clusters, hc.clusters)

# how are they similar within clusters?
allData[allData$km.clusters==1,"atitle"]
allData[allData$km.clusters==10,"atitle"]
allData[allData$km.clusters==16,"atitle"]

# add class membership to data frame
allData[,4] <- hc.clusters
allData[,5] <- km.clusters
dtmClass <- cbind(as.matrix(dtm),hc.clusters)

# perform clustersing on the first few principal components
pr.out <- prcomp(pmData.sd, scale=F)
hc.out2 <- hclust(dist(pr.out$x[,1:5]))

plot(hc.out2)
hc.clusters2 <- cutree(hc.out2,5)
table(hc.clusters2)

# sort(apply(dtmClass[hc.clusters==1,-163],2,mean), decreasing=TRUE)[1:10]
# absort(apply(dtmClass[hc.clusters==2,-163],2,mean), decreasing=TRUE)[1:10]
# sort(apply(dtmClass[hc.clusters==3,-163],2,mean), decreasing=TRUE)[1:10]
# sort(apply(dtmClass[hc.clusters==4,-163],2,mean), decreasing=TRUE)[1:10]


library(SnowballC)
data("crude")
crude[[1]]
stemDocument(crude[[1]])
data("crude")
termFreq(crude[[14]])
strsplit_space_tokenizer <- function(x) unlist(strsplit(x, "[[:space:]]+"))
ctrl <- list(tokenize = strsplit_space_tokenizer,
             removePunctuation = list(preserve_intra_word_dashes = TRUE),
             stopwords = c("reuter", "that"),
             stemming = TRUE,
             wordLengths = c(4, Inf))
termFreq(crude[[14]], control = ctrl)



# this doesn't look good for a large number of records
plot(hclust(data.distx), labels=allData$pmid[gs], xlab="", sub="", ylab="")





xmlSApply(top[[1]], xmlName)
xmlSApply(top[[1]], xmlAttrs)

help(xmlToDataFrame)
xmlToDataFrame()





# web scraping ------------------------------------------------------------
setwd("workshops/Text Mining/")
# page 1 of reviews
test <- readLines("http://www.amazon.com/kindle-fire-hd-best-family-kids-tablet/product-reviews/B00CU0NSCU/ref=cm_cr_pr_btm_link_2?ie=UTF8&pageNumber=17")
# get indices of where these phrases occur and count how many; tells us how many reviews on page
length(grep("This review is from:", test))
grep("This review is from:", test)
grep( "Help other customers find the most helpful reviews", test)
# test[2105:2111]

# work to get stars
# get number of stars for each review
grep("margin-right:5px;\"><span class=\"swSprite s_star_", test)

rating <- test[grep("margin-right:5px;\"><span class=\"swSprite s_star_", test)]
substr(rating[1],70,70)
test[grep("margin-right:5px;\"><span class=\"swSprite s_star_", test)][1]

temp1 <- test[grep("margin-right:5px;\"><span class=\"swSprite s_star_", test)][1]
ratings <- substr(temp1,70,70)

# work to get reviews
# get just the first review
test[grep("This review is from:", test)[1]:
     grep( "Help other customers find the most helpful reviews", test)[1]]

# this returns a vector of length 7; the 4th element always contains the review

review <- test[grep("This review is from:", test)[1]:
                    grep( "Help other customers find the most helpful reviews", test)[1]]

# length(grep("This review is from:", getPage))
#####################################################
# script to scrape reviews of Kindle Fire from Amazon
#####################################################
# do not run during workshop; takes too long!
# create empty vector to store reviews; make it bigger than necessary
reviews <- rep(NA, 5000)
ratings <- rep(NA, 5000)
n <- 1
i <- 1
# Loop until length(grep("This review is from:", test)) == 0
repeat{
  getPage <- readLines(paste("http://www.amazon.com/kindle-fire-hd-best-family-kids-tablet/product-reviews/B00CU0NSCU/ref=cm_cr_pr_btm_link_2?ie=UTF8&pageNumber=",
                   i,sep=""))
  if(length(grep("This review is from:", getPage)) == 0) break else {
    for(j in 1:length(grep("This review is from:", getPage))){
      temp1 <- getPage[grep("margin-right:5px;\"><span class=\"swSprite s_star_", getPage)][j]
      ratings[n] <- substr(temp1,70,70)
      temp2 <- getPage[grep("This review is from:", getPage)[j]:
                       grep( "Help other customers find the most helpful reviews", getPage)[j]]
      reviews[n] <- temp2[4]
      n <- n + 1
    }
  i <- i + 1
  }
}

reviews <- reviews[!is.na(reviews)]
ratings <- ratings[!is.na(ratings)]
allReviews <- data.frame(review=reviews, rating=ratings, stringsAsFactors=FALSE) # I() = keep as character
save(allReviews, file="amzReviews.Rda")

# check results against Amazon
mean(as.numeric(allReviews$rating)) # avg customer review
table(allReviews$rating) # dist'n of ratings
# see how big the object is
print(object.size(allReviews),units="Mb")



load("amzReviews.Rda") # collected 14-Jan-2014

allReviews$review <- as.character(allReviews$review)
allReviews$review <- gsub("<[^>]*>", " ",allReviews$review) # remove HTML tags

# perhaps look at the language of bad reviews
# subset 1 and 2 star reviews
badReviews <- subset(allReviews, subset= ratings %in% c(1,2))
dim(badReviews)



###############################################################################
# original score.sentiment function

score.sentiment = function(sentences, pos.words, neg.words, .progress='none')
{
  require(plyr)
  require(stringr)
  
  # we got a vector of sentences. plyr will handle a list or a vector as an "l" for us
  # we want a simple array of scores back, so we use "l" + "a" + "ply" = laply:
  scores = laply(sentences, function(sentence, pos.words, neg.words) {
    
    # clean up sentences with R's regex-driven global substitute, gsub():
    sentence = gsub('[[:punct:]]', '', sentence) # Punctuation characters
    sentence = gsub('[[:cntrl:]]', '', sentence) # Control characters
    sentence = gsub('\\d+', '', sentence)
    # and convert to lower case:
    sentence = tolower(sentence)
    
    # split into words. str_split is in the stringr package
    word.list = str_split(sentence, '\\s+')
    # sometimes a list() is one level of hierarchy too much
    words = unlist(word.list)
    
    # compare our words to the dictionaries of positive & negative terms
    pos.matches = match(words, pos.words)
    neg.matches = match(words, neg.words)
    
    # match() returns the position of the matched term or NA
    # we just want a TRUE/FALSE:
    pos.matches = !is.na(pos.matches)
    neg.matches = !is.na(neg.matches)
    
    # and conveniently enough, TRUE/FALSE will be treated as 1/0 by sum():
    score = sum(pos.matches) - sum(neg.matches)
    
    return(score)
  }, pos.words, neg.words, .progress=.progress )
  
  scores.df = data.frame(score=scores, text=sentences)
  return(scores.df)
}



