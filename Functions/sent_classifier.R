#' Classify sentiment based on dictionary
#'
#' Classify sentiment based on dictionary
#'
#' @param ud_data A data frame containing UDPipe output
#' @param sent_dict A sentiment dictionary containing the columns lemma, upos and prox
#' @param val_data Can be undefined. A data frame containing validation data, with the columns doc_id, sentence_id and sentiment. When val_data is provided, it will produce sentiment scores only for the sentences that have also been hand-coded
#' @return A data frame with sentiment scores per sentence, and document level (sentiment) word and sentence counts
#' @export
#' @examples
#' sent_classifier(ud_data, sent_dict, val_data = NULL)
#################################################################################################
########################## Generate sentiment scores per sentence ###############################
#################################################################################################



## Classify sentiment based on UDPipe output and a sentiment dictionary
## Also generates validation data when val_data is a data frame containing 
## at least the columns doc_id, sentence_id and sentiment
sent_classifier <- function (ud_data, sent_dict, val_data = NULL) {
  ud_sent <- ud_data %>%
    mutate(lem_u = str_c(lemma,'_',upos)) %>%
    left_join(sent_dict, by = 'lem_u')
  
  ## Group by sentences, and generate dictionary scores per sentence
  ud_sent <- ud_sent %>%
    group_by(doc_id,sentence_id) %>%
    mutate(
      prox = case_when(
        is.na(prox) == T ~ 0,
        TRUE ~ prox
      )
    ) %>%
    summarise(sent_sum = sum(prox),
              sent_sum_pos = sum(prox[prox>0]),
              sent_sum_neg = sum(prox[prox<0]),
              words = length(lemma),
              sent_words = sum(prox != 0),
              # sent_lemmas = list(lem_u[prox != 0])
    )
  
  ## If dictionary validation, return just the sentences that have been hand-coded
  if (!is.null(val_data)) {
    codes_sent <- ud_sent %>%
      left_join(.,val_data, by=c('doc_id','sentence_id')) %>%
      filter(!is.na(sentiment))
    return(codes_sent)
  }
  
  ## Generate document-level stastistics for dictionary
  text_sent <- ud_sent %>%
    group_by(doc_id) %>%
    summarise(
      text.words = sum(words),
      text.sent_words = sum(sent_words),
      text.sentences = n()
    )
  out <- ud_sent %>%
    left_join(.,text_sent,by='doc_id') %>%
    ungroup()
  return(out)
}