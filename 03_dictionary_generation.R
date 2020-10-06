library(dplyr) # For data wrangling
library(stringr) # For dealing with strings
library(data.table) # For matrix computations
vectorfile <- 'Data/vectors.txt' # File containing the word embedding vectors
vocab <- 'Data/vocab.txt' # File containing model vocabulary
seed_dict <- 'Sources/uk_seed_dict.csv' # File containing seed dictionary
dictionary_file <- "Data/full-lexicon.csv" # File for dictionary output

## Minimum occurrence of token before being considered for the dictionary, default 20
## Used value is low because of small sample dataset
nfeat <- 2

## Load the word embedding vectors
vin <- fread(file = vectorfile, quote="") 
vin <- vin[-nrow(vin),] # Remove last row, containing the term <unk>
vecdim <- ncol(vin)-1 # Extract the number of vector dimensions

## Load the vocabulary
dd <- fread(vocab, quote = "") 
ndd <- nrow(dd) # get the total number of unique words

## Keep only words with (nfeat) or more occurrences
x <- merge(vin,dd,by='V1')
x <- x[x$V2.y>=nfeat,]

## Filter out non-words (words containing non-alphanumeric characters or numbers) 
## and words starting with a capital letter (names), a dash (-) or an underscore (_)
x <- x[!str_detect(x$V1,'[@#$%&()*+;<>=/.?!\'"0-9]|^[A-Z\\-_]')]

## Keep only adj, adv, nouns, verbs, and exclamations
x <- x[grepl('_NOUN|_ADJ|_ADV|_VERB|_INTJ',x$V1)==TRUE,]

## Create matrix from raw data, and 
y <- x[,2:(vecdim+1),with=FALSE] # Remove columns with feature labels and counts (V1 and V2.y)
y <- as.matrix(y)
dictionary <- x[,1,with=FALSE] # Keep dictionary words in separate variable
rm(x)
rm(vin)

## Load seed dictionary
sent <- read.csv(seed_dict)

## Merge lemmas and UPOS tags into single "words"
lexicon.pos <- str_c(unlist(sent$lemma)[which(unlist(sent$polarity) == 1)], 
                     unlist(sent$pos1)[which(unlist(sent$polarity) == 1)], 
                     sep = '_')
lexicon.neg <- str_c(unlist(sent$lemma)[which(unlist(sent$polarity) == -1)], 
                     unlist(sent$pos1)[which(unlist(sent$polarity) == -1)], 
                     sep = '_')

## Get the positions of seed words in the word embedding model
m <- length(lexicon.pos) # Get the length of the positive seed dictionary (negative should be the same)
pos.index <- vector(length=m) # Create empty vector for storing positions
neg.index <- vector(length=m)

## If the seed word does not exist in the corpus/word embedding model, 
## return the word instead of the position (this will cause errors later on!)
for (i in 1:m){
  print(i)
  if (length(which(dictionary$V1==lexicon.pos[i])) > 0) {
    pos.index[i] <- which(dictionary$V1==lexicon.pos[i])
  } else {
    pos.index[i] <- lexicon.pos[i]
  }
  if (length(which(dictionary$V1==lexicon.neg[i])) > 0) {
    neg.index[i] <- which(dictionary$V1==lexicon.neg[i])
  } else {
    neg.index[i] <- lexicon.neg[i]
  }
}

## Create matrices with the vectors of positive and negative seed words
pos.matrix <- y[pos.index,]
neg.matrix <- y[neg.index,]

cat("Pre-processing stage successful.","\n")
cat(format(Sys.time(), "%X"),"\n")

## Compute word sentiment values using cosine similarity
q <- nrow(y)
vecpos <- vector(length=m)
vecneg <- vector(length=m)
results <- vector(length=q)
sumvecpos <- ""
sumvecneg <- ""
cat("Computing the lexicons...","\n")
for (i in 1:q){
  for (j in 1:m){
    vecpos[j] <- sum(y[i,]*pos.matrix[j,])/sqrt(sum(y[i,]^2)*sum(pos.matrix[j,]^2))
    vecneg[j] <- sum(y[i,]*neg.matrix[j,])/sqrt(sum(y[i,]^2)*sum(neg.matrix[j,]^2))  
  }
  sumvecpos <- sum(vecpos)
  sumvecneg <- sum(vecneg)
  results[i] <- sumvecpos - sumvecneg
  
  if (i %% 1000 == 0) {
    prog <- round(i/q*100, digits = 2)    
    cat("Progress:",prog,"%.","\n")
    cat(format(Sys.time(), "%X"),"\n")
  } 
}
res <- cbind(dictionary,results)

## rescale between -1 and 1

## The original function, rescales by shifting the midpoint
## rescale <- function(x) {2/(max(x) - min(x))*(x - min(x)) - 1}

## New rescale function, dividing scores by the maximum absolute value 
## (preserving the difference between the most positive and most negative words)
rescale_new <- function(x) {x/max(abs(x))}
res$results <- rescale_new(res$results)

## Sort the dictionary and save it to a csv file
res <- res[order(-results),]
write.table(res,dictionary_file,sep=",",row.names=F,col.names=F)

cat("Process complete and successful.","\n")
cat(format(Sys.time(), "%X"),"\n")