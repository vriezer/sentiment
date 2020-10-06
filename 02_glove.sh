CORPUS='Data/corpus.txt' # Input file containing corpus
VOCAB_FILE='Data/vocab.txt' # File containing vocabulary (unique words) in model
COOCCURRENCE_FILE='Data/cooccurrence.bin' # Intermediate cooccurrence files
COOCCURRENCE_SHUF_FILE='Data/cooccurrence.shuf.bin' # Intermediate cooccurrence files
BUILDDIR=./build # Location of GloVe binaries
SAVE_FILE='Data/vectors' # Output file containing vectors for each token in the vocabulary
VERBOSE=2 # Level of terminal output during process
MEMORY=30.0 # Amount of RAM available to process, in GB
VOCAB_MIN_COUNT=5 # Minimum number of times a token should occur before it is part of the model
VECTOR_SIZE=300 # Number of dimensions to estimate the model on
MAX_ITER=100 # Number of iterations allowed for the model to converge
WINDOW_SIZE=7 # Symmetric window size for co-occurrence counts
BINARY=0 # Boolean indicating if co-occurrences should be binary or counts
NUM_THREADS=16 # Number of threads used for model computation
X_MAX=100 # Parameter specifying cutoff in weighting function

## To run this script, just type sh 02_glove.sh in a terminal
## Make sure that the working directory is correct, as well as the CORPUS filename above
## Also note that the script output reports that the cost is NaN for every iteration. 
## This is because of the very small corpus size, and should not be the case with normal operation

echo
echo "$ $BUILDDIR/vocab_count -min-count $VOCAB_MIN_COUNT -verbose $VERBOSE < $CORPUS > $VOCAB_FILE"
$BUILDDIR/vocab_count -min-count $VOCAB_MIN_COUNT -verbose $VERBOSE < $CORPUS > $VOCAB_FILE
echo "$ $BUILDDIR/cooccur -memory $MEMORY -vocab-file $VOCAB_FILE -verbose $VERBOSE -window-size $WINDOW_SIZE < $CORPUS > $COOCCURRENCE_FILE"
$BUILDDIR/cooccur -memory $MEMORY -vocab-file $VOCAB_FILE -verbose $VERBOSE -window-size $WINDOW_SIZE < $CORPUS > $COOCCURRENCE_FILE
echo "$ $BUILDDIR/shuffle -memory $MEMORY -verbose $VERBOSE < $COOCCURRENCE_FILE > $COOCCURRENCE_SHUF_FILE"
$BUILDDIR/shuffle -memory $MEMORY -verbose $VERBOSE < $COOCCURRENCE_FILE > $COOCCURRENCE_SHUF_FILE
echo "$ $BUILDDIR/glove -save-file $SAVE_FILE -threads $NUM_THREADS -input-file $COOCCURRENCE_SHUF_FILE -x-max $X_MAX -iter $MAX_ITER -vector-size $VECTOR_SIZE -binary $BINARY -vocab-file $VOCAB_FILE -verbose $VERBOSE"
$BUILDDIR/glove -save-file $SAVE_FILE -threads $NUM_THREADS -input-file $COOCCURRENCE_SHUF_FILE -x-max $X_MAX -iter $MAX_ITER -vector-size $VECTOR_SIZE -binary $BINARY -vocab-file $VOCAB_FILE -verbose $VERBOSE

