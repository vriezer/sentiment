#' Generate CV folds for nested cross-validation
#'
#' Creates a grid of models to be estimated for each outer fold, inner fold and parameter combination
#'
#' @param outer_k Number of outer CV (performance estimation) folds. If outer_k < 1 holdout sampling is used, with outer_k being the amount of test data
#' @param inner_k Number of inner CV (parameter optimization) folds
#' @param vec Vector containing the true values of the classification
#' @param grid Parameter grid for optimization
#' @param seed integer used as seed for random number generation
#' @return A nested set of lists with row numbers
#' @export
#' @examples
#' cv_generator(outer_k, inner_k, vec, grid, seed)
#################################################################################################
#################################### Generate CV folds ##########################################
#################################################################################################
cv_generator <- function(outer_k, inner_k, vec, grid, seed) {
  ### Generate inner folds for nested cv
  inner_loop <- function(i, folds, vec, inner_k, grid, seed) {
    # RNG needs to be set explicitly for each fold
    set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
    inner_folds <- createFolds(as.factor(vec[-folds[[i]]]), k= inner_k)
    grid <- crossing(grid, inner_fold = names(inner_folds), outer_fold = names(folds)[i])
    return(list(grid = grid, inner_folds = inner_folds, outer_fold = names(folds)[i]))
  }

  ### Generate outer folds for nested cv
  generate_folds <- function(outer_k, inner_k, vec, grid, seed){
    set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion")
    if (is.null(outer_k)) { # If no outer_k, use all data to generate inner_k folds for parameter optimization
      inner_folds <- createFolds(as.factor(vec), k= inner_k)
      grid <- crossing(grid, inner_fold = names(inner_folds))
      return(list(grid = grid,
                  inner_folds = inner_folds))
    } else if (outer_k < 1) { # Create holdout validation for model performance estimation, with test set equal to outer_k
      folds <- createDataPartition(as.factor(vec), p=outer_k)
    } else { # Do full nested CV
      folds <- createFolds(as.factor(vec), k= outer_k)
    }
    # Generate grid of hyperparameters for model optimization, and include inner folds row numbers
    grid_folds <- lapply(1:length(folds),
                          inner_loop,
                          folds = folds,
                          vec = vec,
                          inner_k = inner_k,
                          grid = grid,
                          seed = seed)

    # Extract grid dataframe from results
    grid <- grid_folds %>% purrr::map(1) %>% dplyr::bind_rows()

    # Extract row numbers for inner folds from results
    inner_folds <- grid_folds %>% purrr::map(2)

    # Extract the names of the inner folds from results
    names(inner_folds) <- grid_folds %>% purrr::map(3) %>% unlist(.)
    return(list(grid = grid,
                outer_folds = folds,
                inner_folds = inner_folds))
  }
  return(generate_folds(outer_k,inner_k = inner_k, vec = vec, grid = grid, seed = seed))
}
