#' Generate vectors of true and predicted values based on dictionary parameters
#'
#' Generate vectors of true and predicted values based on dictionary parameters
#'
#' @param row Row number of parameters to test from grid
#' @param grid Grid containing parameter combinations to test
#' @param df_train Data frame containing at least the columns sent (predicted sentiment) and sentiment (true sentiment)
#' @return A data frame with true and predicted values, and the parameters used to generate them
#' @export
#' @examples
#' optimizer(row, grid, df_train)
#################################################################################################
############################ Generate true and predicted values #################################
#################################################################################################

## Function to generate vectors of true and predicted values based on parameters
optimizer <- function(row, grid, df_train) {
  params <- grid[row,]
  pred <- case_when(df_train$sent > params$pos_cutoff ~ 1,
                    df_train$sent == 0 ~ 0,
                    df_train$sent >= params$neg_cutoff & df_train$sent <= params$pos_cutoff ~ 0,
                    TRUE ~ -1)
  return(data.frame(
    tv = I(list(df_train$sentiment)), # True values from test set
    pred = I(list(pred)), # Predictions of test set
    params, # Parameters used to generate classification model
    stringsAsFactors = F
  )
  )
}