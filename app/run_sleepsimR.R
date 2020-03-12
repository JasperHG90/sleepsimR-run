## Code used to run a simulation
library(sleepsimR)
library(sleepsimRapiClient)
library(argparser, quietly=TRUE)
library(logger)

# Set up a parser
args <- arg_parser("Simulate normalized EEG/EOG data and run a multilevel hidden markov model (mHMM)")
# Add arguments
args <- add_argument(args, "username", help="User name used to authenticate with the API.")
args <- add_argument(args, "password", help="Password used to authenticate with the API.")
args <- add_argument(args, "--host", help="Host address on which the sleepsimR API is running.", default="http://localhost:5002")
# Parse
argv <- parse_args(args)

# Set up the logger
#log_threshold("INFO")
log_info("Application is starting up ...")

#' Main function
#'
#' @param username string. username used to authenticate with the API.
#' @param password string. password used to authenticate with the API.
#' @param host string. host on which the API is running.
#'
#' @return exits silently after getting kill command from the API.
#'
#' @details This function runs one out of 36.000 iterations that I have defined
#'     in my master thesis. ...
main <- function(username = argv$username, password = argv$password, host = argv$host) {
  # Set host, user, pwd
  set_host(host)
  set_usr_pwd(password, username)
  # Check if the host is running
  can_connect <- check_connection()
  # Emit message
  if(can_connect) {
    log_info(paste0("sleepsimR API is up and running at host ", host, ". Ready to query parameters ..."))
  } else {
    log_error(paste0("Cannot connect to sleepsimR API at host ", host, ". Exiting now ..."))
  }
  # Query parameters
  log_info("Querying parameters ...")
  sim <- query_simulation_settings()
  log_info(paste0("Successfully queried parameters. Working on iteration ", sim$iteration_id, " ..."))
  # Simulate dataset
  log_info("Simulating dataset ...")
  data_simulated <- simulate_dataset(sim$n, sim$n_t, sim$zeta, sim$Q, sim$dsim_seed)
  # To data frame
  tdf <- data.frame(
    id = data_simulated$obs[,1],
    EEG_mean_beta = data_simulated$obs[,2],
    EOG_median_theta = data_simulated$obs[,3],
    EOG_min_beta = data_simulated$obs[,4]
  )
  states <- data_simulated$states[,2]
  # Get summary statistics for each
  hyp_priors <- list(
    as.vector(tapply(tdf[,-1]$EEG_mean_beta, states, mean)),
    as.vector(tapply(tdf[,-1]$EOG_median_theta, states, mean)),
    as.vector(tapply(tdf[,-1]$EOG_min_beta, states, mean))
  )
  # Reshape start values
  m <- sqrt(length(sim$start_gamma$tpm))
  start_values <- list(
    matrix(unlist(sim$start_gamma$tpm), nrow=m, ncol=m,
           byrow = TRUE),
    matrix(unlist(sim$start_emiss$EEG_Fpz_Cz_mean_beta),
           ncol=2, byrow = TRUE),
    matrix(unlist(sim$start_emiss$EOG_median_theta),
           ncol=2, byrow = TRUE),
    matrix(unlist(sim$start_emiss$EOG_min_beta),
           ncol=2, byrow=TRUE)
  )
  log_info("Running model ...")
  # Run model
  mod <- sleepsimR::run_mHMM(tdf, start_values = start_values, hyperprior_means = hyp_priors,
                  model_seed = sim$model_seed,mcmc_iterations=2500, mcmc_burn_in = 500)
  # Get label switch overview
  # Transpose this matrix so that, at analysis time, I can always call byrow=TRUE. Otherwise,
  #  this is the only value with this problem
  label_switcharoo <- as.vector(t(mod$label_switch))
  # Get the original order
  orig_state_order <- mod$state_orders
  # Remove it from the model
  mod$state_orders <- NULL
  # Get MAP estimates
  map_mod <- MAP(mod)
  # Ignore values I don't care about
  map_mod$PD_subj <- NULL
  map_mod$gamma_int_subj <- NULL
  map_mod$gamma_prob_bar <- NULL
  map_mod$gamma_naccept <- NULL # Not sure I want to throw this away!
  # Get credible intervals
  mod_burned <- burn(mod)
  ci_gamma_int <- as.vector(credible_interval(mod_burned$gamma_int_bar))
  ci_emiss_mu_bar <- lapply(mod_burned$emiss_mu_bar, function(x) as.vector(credible_interval(x)))
  ci_emiss_var_bar <- lapply(mod_burned$emiss_var_bar, function(x) as.vector(credible_interval(x)))
  ci_emiss_varmu_bar <- lapply(mod_burned$emiss_varmu_bar, function(x) as.vector(credible_interval(x)))
  # Make output list
  resp <- register_simulation_outcomes(sim$scenario_id, sim$iteration_id,
                                       emiss_mu_bar = map_mod$emiss_mu_bar,
                                       gamma_int_bar = map_mod$gamma_int_bar,
                                       emiss_var_bar = map_mod$emiss_var_bar,
                                       emiss_varmu_bar = map_mod$emiss_varmu_bar,
                                       credible_interval = list(
                                           "gamma_int_bar" = ci_gamma_int,
                                           "emiss_mu_bar" = ci_emiss_mu_bar,
                                           "emiss_var_bar" = ci_emiss_var_bar,
                                           "emiss_varmu_bar" = ci_emiss_varmu_bar
                                       ),
                                       label_switch = label_switcharoo,
                                       state_orders = orig_state_order)
  # Save data?
  if(sim$save_model) {
    log_info("Saving complete model to disk ...")
    saveRDS(mod, paste0(file.path("/var/sleepsimR", sim$iteration_id), ".rds"))
  }
  # If resp is terminate, then we out!
  if(resp$message == "terminate") {
    log_info("Successfully finished iteration. Exiting gracefully ...")
  }
}
