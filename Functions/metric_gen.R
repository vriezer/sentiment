#' Generate performance statistics for models
#'
#' Generate performance statistics for models, based on their predictions and the true values
#'
#' @param x A data frame containing at least the columns "pred" and "tv"
#' @return x, with additional columns for performance metrics
#' @export
#' @examples
#' metric_gen(x)
#################################################################################################
############################# Performance metric generation #####################################
#################################################################################################

metric_gen <- function(x) {
  ### Fix for missing classes in multiclass classification
  ### Sorting u for easier interpretation of confusion matrix
  u <- as.character(sort(as.numeric(union(unlist(x$pred), unlist(x$tv)))))
  # Create a crosstable with predictions and true values
  class_table <- table(prediction = factor(unlist(x$pred), u), trueValues = factor(unlist(x$tv), u))

  # When only two classes, set positive class explicitly as the class with the highest value
  if (length(unique(u)) == 2) {
    conf_mat <- confusionMatrix(class_table, mode = "everything", positive = max(u))
    weighted_measures <- as.data.frame(conf_mat$byClass)
    macro_measures <- as.data.frame(conf_mat$byClass)
  } else {
    # Create a confusion matrix
    conf_mat <- confusionMatrix(class_table, mode = "everything")
    # Set "positive" value to NA, because not applicable
    conf_mat$positive <- NA
    # Compute weighted performance measures
    weighted_measures <- colSums(conf_mat$byClass * colSums(conf_mat$table))/sum(colSums(conf_mat$table))
    # Compute unweighted performance measures (divide by number of classes, each class equally important)
    macro_measures <- colSums(conf_mat$byClass)/nrow(conf_mat$byClass)
    # Replace NaN's by 0 when occurring
    weighted_measures[is.nan(weighted_measures)] <- 0
    macro_measures[is.nan(macro_measures)] <- 0
  }
  return(cbind(x,
               as.data.frame(t(conf_mat$overall)),
               'weighted' = t(as.data.frame(weighted_measures)),
               'macro' = t(as.data.frame(macro_measures)),
               pos_cat = conf_mat$positive,
               conf_mat = I(list(conf_mat))
              )
         )
}
