## Code used to run a simulation
library(sleepsimR)
library(argparser, quietly=TRUE)

# Set up a parser
args <- arg_parser("Simulate normalized EEG/EOG data and run a multilevel hidden markov model (mHMM)")
# Add arguments
args <- add_argument(args, "username", help="User name used to authenticate with the API.")
args <- add_argument(args, "password", help="Password used to authenticate with the API.")
args <- add_argument(args, "--host", help="Host address on which the sleepsimR API is running.", default="http://localhost:5002")
# Parse
argv <- parse_args(args)
