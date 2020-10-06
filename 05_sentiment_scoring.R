library(dplyr) # For data wrangling
library(stringr) # For string manipulations
library(data.table) # For matrix computations
source('Functions/sent_classifier.R') # Function to classify categorical sentiment at sentence level

## Parameters for dictionary application
ud_data <- readRDS('Data/ud_data.Rds') # Read UDPipe data of unclassified articles
val_res <- readRDS('Data/val_res.Rds') # Read validation results for dictionary parameters
pos_cutoff <- val_res$final_params$pos_cutoff
neg_cutoff <- val_res$final_params$neg_cutoff
dict <- fread('Data/full-lexicon.csv') # Read dictionary from file

## Create dictionary with the validated lexicon cutoff
sent_dict <- dict %>%
  rename(lem_u = V1,
         prox = V2) %>%
  .[abs(.$prox) >= val_res$final_params$lex_cutoff,]

## Generate raw sentiment scores and sentiment word counts
df <- as.data.table(sent_classifier(ud_data, sent_dict))

## Create categorical scores
df <- df[,.(
  (.SD),
  sent = sent_sum/words # Generate weighted sentiment scores
)][,.(
  (.SD),
  # Create binary sentiment scores based on validated positive
  # and negative cutoff points
  sent_binary = case_when(
    sent > pos_cutoff ~ 1,
    sent == 0 ~ 0,
    sent >= neg_cutoff & sent <= pos_cutoff ~ 0,
    TRUE ~ -1
  )
)][,.(
  (.SD),
  # Create a "weighted" sentiment score per sentence 
  # i.e. categorical score * words in sentence
  sent_binary_weighted = sent_binary*words
)]

## Optional: Create document-level categorical sentiment scores
text_sent <- df[,
                .(text.sent = sum(sent_binary_weighted)/sum(words),
                  text.sent_words = sum(sent_words),
                  text.words = sum(words),
                  text.sentences = .N
                ), by = list(doc_id)]
