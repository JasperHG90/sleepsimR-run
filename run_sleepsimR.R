## Code used to run a simulation
library(sleepsimR)
library(argparser, quietly=TRUE)

# Set up a parser
args <- arg_parser("Simulate normalized EEG/EOG data and run a multilevel hidden markov model (mHMM)")
# Add arguments
args <- add_argument(args, "--host", help="Host address on which the sleepsimR API is running.", default="http://localhost:5007")
args <- add_argument(args, "api-key", help="API key used to communicate with the API.")
# Parse 
argv <- parse_args(args)
