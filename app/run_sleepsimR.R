## Code used to run a simulation
library(sleepsimR)
library(sleepsimRapiClient)
library(argparser, quietly=TRUE)
library(logger)

# Set up a parser
args <- arg_parser("Simulate normalized EEG/EOG data and run a multilevel hidden markov model (mHMM)")
# Add arguments
args <- add_argument(args, "--username", help="User name used to authenticate with the API.", type="character", default=NULL)
args <- add_argument(args, "--password", help="Password used to authenticate with the API.", type="character", default=NULL)
args <- add_argument(args, "--host", help="Host address on which the sleepsimR API is running.", type="character", default=NULL)
# Parse
argv <- parse_args(args)

# Set up the logger
log_info("Application is starting up ...")

#' Main function. Runs a single iteration of my simulation study
#'
#' @param username string. username used to authenticate with the API.
#' @param password string. password used to authenticate with the API.
#' @param host string. host on which the API is running.
#'
#' @return exits silently after getting kill command from the API.
#'
#' @details This function runs one out of 36.000 iterations that make up my simulation study.
#'     This program uses the R library sleepsimR <https://github.com/JasperHG90/sleepsimR>
#'     to simulate a dataset and run the multilevel hidden markov model implemented by my
#'     supervisor Dr. Emmeke Aarts in the R library mHMMbayes <https://github.com/emmekeaarts/mHMMbayes>.
#'     The program assumes that you are running the sleepsimR API <https://github.com/JasperHG90/sleepsimR-api>
#'     either locally or at some publicly reachable address. It proceeds as follows:
#'      (1) Query simulation settings (parameters, number of subjects etc.) from the API
#'          using the sleepsimRapiClient R library <https://github.com/JasperHG90/sleepsimRapiClient>
#'      (2) Run the mHMM on the simulated dataset
#'      (3) Extract parameter estimates
#'      (4) Send the results back to the API
#'      (5) If the simulation settings include the command to save the entire model file
#'          (happens with approx. 5% of all models), then save the model file in the folder
#'          /var/sleepsimR.
#'    This program has been designed to run inside a docker container. It is hosted on docker
#'    hub <https://hub.docker.com/r/jhginn/sleepsimr-run> and registered on Zenodo under the
#'    DOI: 10.5281/zenodo.3709058 <https://zenodo.org/record/3709058>. Please read the README
#'    for detailed information on setting up this program.
main <- function(username = argv$username, password = argv$password, host = argv$host) {
  # Check if passed
  if(is.na(username)) {
    if(Sys.getenv("SLEEPSIMR_API_USERNAME") == "") {
      stop("Environment variable 'SLEEPSIMR_API_USERNAME' not set but is required. Either pass it to the docker container using --username <username> or set it as an environment variable")
    }
  }
  if(is.na(password)) {
    if(Sys.getenv("SLEEPSIMR_API_PASSWORD") == "") {
      stop("Environment variable 'SLEEPSIMR_API_PASSWORD' not set but is required. Either pass it to the docker container using --password <password> or set it as an environment variable")
    }
  }
  if(is.na(host)) {
    if(Sys.getenv("SLEEPSIMR_MASTER_HOST") == "") {
      stop("Environment variable 'SLEEPSIMR_MASTER_HOST' not set but is required. Either pass it to the docker container using --host <host> or set it as an environment variable")
    }
  }
  # Set host, user, pwd
  if(!is.na(host)) {
    set_host(host)
  }
  if(!is.na(password) & !is.na(username)) {
    set_usr_pwd(password, username)
  }
  # Check if the host is running
  can_connect <- check_connection()
  # Emit message
  if(can_connect) {
    log_info(paste0("sleepsimR API is up and running at host ", Sys.getenv("SLEEPSIMR_MASTER_HOST"), ". Ready to query parameters ..."))
  } else {
    log_error(paste0("Cannot connect to sleepsimR API at host ", host, ". Exiting now ..."))
  }
  # Query parameters
  log_info("Querying parameters ...")
  sim <- query_simulation_settings()
  # If no more simulations, stop
  if("message" %in% names(sim)) {
    stop(sim$message)
  }
  log_info(paste0("Successfully queried parameters. Working on iteration ", sim$iteration_id,
                  "With parameters", "..."))
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
  em1 <- tapply(tdf[,-1]$EEG_mean_beta, states, mean)
  em2 <- tapply(tdf[,-1]$EOG_median_theta, states, mean)
  em3 <- tapply(tdf[,-1]$EOG_min_beta, states, mean)
  hyp_priors <- list(
    as.vector(em1[sort.list(as.numeric(names(em1)))]),
    as.vector(em2[sort.list(as.numeric(names(em2)))]),
    as.vector(em3[sort.list(as.numeric(names(em3)))])
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
  # Number of states/dependent variables
  # (hard-code these)
  mprop <- list(
    "m" = 3,
    "n_dep" = 3
  )
  # Run model
  log_info("Running model ...")
  mod <- sleepsimR::run_mHMM(tdf, start_values = start_values, mprop = mprop, hyperprior_means = hyp_priors,
                             model_seed = sim$model_seed,mcmc_iterations=3250, mcmc_burn_in = 1250,
                             order_data = FALSE)
  # Get label switch overview
  # Transpose this matrix so that, at analysis time, I can always call byrow=TRUE. Otherwise,
  #  this is the only value with this problem
  label_switcharoo <- as.vector(t(mod$label_switch))
  # Get the order of means by n_dep
  state_order <- mod$state_orders
  # If NULL, then make placeholder value
  if(any(vapply(state_order, is.null, TRUE))) {
    for(idx in seq_along(state_order)) {
      state_order[[idx]] <- c(0,0,0)
    }
  }
  # Remove it from the model
  mod$state_orders <- NULL
  # Get MAP estimates
  map_mod <- MAP(mod)
  # Ignore values I don't care about
  map_mod$gamma_int_subj <- NULL
  map_mod$gamma_int_bar <- NULL
  map_mod$gamma_naccept <- NULL # Not sure I want to throw this away!
  # Post-process subject-specific estimates of means
  map_mod$PD_subj <- lapply(map_mod$PD_subj, function(x) {
    # Indices to grab
    idx <- m * length(sim$start_emiss)
    x$mean <- x$mean[1:idx]
    x$median <- x$median[1:idx]
    x$SE <- x$SE[1:idx]
    return(x)
  })
  # Get credible intervals
  mod_burned <- burn(mod)
  ci_gamma_prob <- as.vector(credible_interval(mod_burned$gamma_prob_bar, "0.95"))
  ci_emiss_mu_bar <- lapply(mod_burned$emiss_mu_bar, function(x) as.vector(credible_interval(x, "0.95")))
  ci_emiss_var_bar <- lapply(mod_burned$emiss_var_bar, function(x) as.vector(credible_interval(x, "0.95")))
  ci_emiss_varmu_bar <- lapply(mod_burned$emiss_varmu_bar, function(x) as.vector(credible_interval(x,"0.95")))
  # Make output list
  resp <- register_simulation_outcomes(sim$scenario_id, sim$iteration_id,
                                       PD_subj = map_mod$PD_subj,
                                       emiss_mu_bar = map_mod$emiss_mu_bar,
                                       gamma_prob_bar = map_mod$gamma_prob_bar,
                                       emiss_var_bar = map_mod$emiss_var_bar,
                                       emiss_varmu_bar = map_mod$emiss_varmu_bar,
                                       credible_interval = list(
                                           "gamma_prob_bar" = ci_gamma_prob,
                                           "emiss_mu_bar" = ci_emiss_mu_bar,
                                           "emiss_var_bar" = ci_emiss_var_bar,
                                           "emiss_varmu_bar" = ci_emiss_varmu_bar
                                       ),
                                       label_switch = label_switcharoo,
                                       state_order = state_order)
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

# Call main
main()
