library(data.table) # For matrix computations
library(caret) # For generating CV folds
library(tidyr) # For generating parameter grid
library(dplyr) # For data wrangling
library(future.apply) # For parallel processing
library(stringr) # For string manipulations

## Parameters for dictionary optimization
cores <- 4 # Number of threads used for optimization
plan(multiprocess, workers = cores) # Initiate multithreaded processing

seed <- 5489 # Seed for generating reproducible random samples
pos_cutoff <- seq(-.1, .1, .005) # Range of positive cutoff values to test (above which sentiment is positive)
neg_cutoff <- seq(-.1, .1, .005) # Range of negative cutoff values to test (below which sentiment is negative)
lex_cutoff <- seq(.15, .35, .05) # Lexicon cutoff for the absolute cosine value above which words should be included in the dictionary
final_grid <- crossing(grid = list(crossing(pos_cutoff, neg_cutoff)),lex_cutoff) # Generate grid of parameter combinations to test
k <- 2 # Number of cross-validation folds

## Measure for parameter optimization. Accuracy is used here because of the small sample size
## F1 can not be computed if not all classes are predicted, or predicted correctly
## weighted.F1 is used as optimization measure in the paper
## See colnames(final_params) for other possible optimization measures 
opt_measure <- "Accuracy"
val_data <- read.csv('Sources/val_data.csv') # Read data containing hand-coded classifications
ud_data <- readRDS('Data/ud_data.Rds') # Read UDPipe data
dict <- fread('Data/full-lexicon.csv') # Read dictionary
val_res <- 'Data/val_res.Rds' # Output file for validation results (including parameters)

## Functions used for validation
source('Functions/cv_generator.R') # Function for generating CV folds, can also generate nested CV folds (not used here)
source('Functions/optimizer.R') # Function for determining optimum dictionary parameters for a hand-coded dataset
source('Functions/sent_classifier.R') # Function to classify categorical sentiment at sentence level
source('Functions/validator.R') # Function to determine optimum dictionary parameters using CV folds
source('Functions/metric_gen.R') # Function to generate performance metrics and confusion matrices based on true and predicted values

## Generate cross-validation folds, using stratified random sampling based on val_data$sentiment
folds <- cv_generator(outer_k = k,inner_k = k, vec = val_data$sentiment, grid = final_grid, seed = seed)
outer_folds <- folds$outer_folds
inner_folds <- folds$inner_folds

## Use only one inner fold per outer fold, as nested CV is not required
grid <- folds$grid %>%
  filter(inner_fold == names(inner_folds)[[1]]) %>%
  select(-inner_fold)

## Compute optimal parameters for each fold
results <- bind_rows(future_lapply(1:nrow(grid),validator, grid, outer_folds, ud_data, val_data, opt_measure, seed, dict)) %>% 
  group_by(fold) %>% 
  slice(which.max((!!as.name(opt_measure)))) %>%
  ungroup() 

## Compute average performance over all folds
performance <- results %>% 
  summarise(
    tv = list(unlist(tv)),
    pred = list(unlist(pred))
  ) %>% # Create a single list of pred and true values, for all folds combined (this gives you a weighted mean performance estimate)
  metric_gen(.)

## Compute final parameters for optimal dictionary using the entire hand-coded dataset
final_params <- future_lapply(1:nrow(final_grid),validator, final_grid, outer_folds=NULL, ud_data, val_data, opt_measure, seed, dict) %>%
  bind_rows(.) %>%
  slice(which.max((!!as.name(opt_measure))))

## Save the final results
saveRDS(list(results = results,performance = performance,final_params = final_params), val_res)


