# The sentiment is in the details: Developing a language-agnostic approach to sentence-level sentiment analysis in news media

The code provided in this repository belongs to the publication "The sentiment is in the details: Developing a language-agnostic approach to sentence-level sentiment analysis in news media". It provides a workflow for reproducing the sentiment analysis approach described in this study. The main script files are found in the root folder, with the filenames indicating the order in which the scripts should be executed. The code in 03_dictionary_generation.R and the seed dictionary in uk_seed_dict_full.csv are adapted from [lrheault/emotion](https://github.com/lrheault/emotion).

The script files in the Functions folder contain helper functions to construct, test and apply the dictionary. The Docs.zip file contains sample documents for use in combination with the scripts. The file should be extracted to the root of the repository before running the scripts. The Sources folder contains a sample dictionary and a sample of hand-coded sentences. Note that both the dictionary and the sentence classifications are not representative of a proper implementation of this method, they are for illustrative purposes only. Finally, the build folder contains a set of executable binaries built from the GloVe source, which can be found in the glove folder. The Data folder is used for storing the GloVe output files.

The code provided here has only been tested on Linux. As of yet there are no pre-compiled GloVe binaries for Windows available, which means the workflow presented here can only be used on a Unix-based system (Linux or MacOS).

## Dependencies
Besides the GloVe binaries, the following R packages are required:
- UDPipe: For NLP parsing
- dplyr: For data wrangling
- tidyr: For generating optimization grid of parameter combinations
- stringr: For string manipulation
- readtext: For loading the sample documents
- data.table: For matrix computations
- caret: For generating cross-validation folds
- future.apply: For doing parallel computations

A SessionInfo file of a working environment is provided in this repository for future reference.

## Notes on replication
- The GloVe command generates the output `cost: -nan` for every iteration when using the provided sample material. This is due to the extremely small size of the sample. In real-world applications, there should be values here.
- When creating or using a seed dictionary, keep in mind that all lemma_UPOS combinations in the seed dictionary also need to occur in the corpus.
- Some UDPipe models have the tendency to structurally apply the wrong UPOS tag to specific words, so the seed dictionary should be evaluated against the number of occurrences of the relevant lemma_UPOS pairs in the corpus.
- The seed dictionary provided in uk_seed_dict.csv is only for illustrative purposes.

## File descriptions
Below follows an overview of the script files, and their in- and output. All input and output is read from and written to the Data subdirectory, unless otherwise noted:

- **01_data_processing.R:** Imports raw text data from files, and parses it using UDPipe
  - *Input:* Raw txt files in ./Docs
  - *Output:*
    - corpus.txt: Corpus containing lemma_UPOS pairs for all documents combined
    - ud_data.Rds: Data frame containing UDPipe output of all documents

- **02_glove.sh:** Bash script to generate GloVe word embedding files in ./Data
  - *Input:* corpus.txt
  - *Output:* Various intermediate files, vocab.txt and vectors
    - vocab.txt: File containing the vocabulary (unique words) in the GloVe model
    - vectors: File containing the vector values for each word in the vocabulary

- **03_dictionary_generation.R:** Generates initial sentiment dictionary, based on Rheault et al., 2008.
  - *Input:*
    - vectors
    - vocab.txt
    - uk_seed_dict.csv
  - *Output:*
    full-lexicon.csv: CSV file containing the full dictionary output, i.e. sentiment scores for all words in the vocabulary

- **04_sentiment_validation.R:** Validates parameters against human-coded data to determine optimum dictionary parameters. Can take quite some time to run!
  - *Input:*
    - full-lexicon.csv
    - val_data.csv
    - ud_data.Rds
  - *Output:*
    - val_res.Rds: List containing optimal dictionary parameters and performance measures

- **05_sentiment_scoring.R:** Scores sentences in UDPipe output based on optimal dictionary parameters
  - *Input:*
    - full-lexicon.csv
    - ud_data.Rds
    - val_res.Rds
  - *Output:* Sentiment scores per sentence for input provided by ud_data.Rds
