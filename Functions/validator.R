#' Meta-function to determine optimal dictionary parameters
#'
#' Meta-function to determine optimal dictionary parameters
#'
#' @param row Row of parameter grid to validate
#' @param grid Grid containing parameter combinations
#' @param outer_folds List of vectors containing the row numbers of the different folds
#' @param ud_data A data frame containing UDPipe output
#' @param val_data A data frame containing validation data, with the columns doc_id, sentence_id and sentiment
#' @param opt_measure String indicating the measure to use when determining the optimal dictionary parameters
#' @param seed Integer used as seed for random number generation
#' @param dict A sentiment dictionary containing the columns lemma, upos and prox
#' @return A data frame with sentiment scores per sentence, and document level (sentiment) word and sentence counts
#' @export
#' @examples
#' validator(row, grid, outer_folds, ud_data, val_data, opt_measure, seed, dict)
#################################################################################################
########################## Validate sentiment dictionary parameters #############################
#################################################################################################


validator <- function(row, grid, outer_folds, ud_data, val_data, opt_measure, seed, dict) {
  final <- F
  params <- grid[row,]
  name <- as.character(params$lex_cutoff)
  ### Load sentiment dictionary from files
  ### Seed words are already included (and weighted) in dictionary
  sent_dict <- dict %>%
    rename(lem_u = V1,
           prox = V2) %>%
    .[abs(.$prox) >= params$lex_cutoff,]
  
  df <- sent_classifier(ud_data, sent_dict, val_data)
  
  
  df <- mutate(df, sentiment = as.numeric(sentiment),
               sent = sent_sum/words)
  
  # Validate performance of parameters
  if ("outer_fold" %in% colnames(params)) {
    df_train <- df[-outer_folds[[params$outer_fold]],]
    df_test <- df[outer_folds[[params$outer_fold]],]
  } else { # Determine optimum parameters based on whole dataset
    final <- T
    df_train <- df
  }
  res <- lapply(1:nrow(params$grid[[1]]),optimizer, grid = params$grid[[1]], df_train) %>%
    lapply(., metric_gen) %>% # Generate performance metrics for each row in outer_grid
    bind_rows(.) %>%
    # Get for each outer_fold the row with the highest value of opt_measure
    slice(which.max((!!as.name(opt_measure)))) 
  
  # If final parameters, add lex_cutoff parameter to returned data, and return
  if (final) {
    res$lex_cutoff <- params$lex_cutoff
    return(res)
  } else {
    # Select only the columns outer_fold, and the columns that are in the original parameter grid 
    res <- select(res,colnames(params$grid[[1]]))
  }
  
  # Apply the optimum parameters obtained in res to the test dataset to get the performance estimation
  final_res <- lapply(1:nrow(res),optimizer, grid = res, df_test) %>%
    future_lapply(., metric_gen) %>% # Generate performance metrics for each row in outer_grid
    bind_rows(.) %>%
    mutate(
      lex_cutoff = params$lex_cutoff,
      fold = params$outer_fold
    )
  
  return(final_res)
}