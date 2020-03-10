## Communicate with the simulator setting API

#' Fetch simulation settings used for this simulation scenario
#'
#' @param uid unique id of this container
#'
#' @importFrom httr GET
#' @importFrom httr content
#' @importFrom httr authenticate
#' @importFrom httr add_header
#'
#' @return list containing 14 elements. SImulation settings
query_simulation_settings <- function(uid = getOption("sleepsimR_uid")) {
  # HOST/PWD/USR
  host <- Sys.getenv("SLEEPSIMR_MASTER_HOST")
  usr <- Sys.getenv("SLEEPSIMR_API_USERNAME")
  pwd <- Sys.getenv("SLEEPSIMR_API_PASSWORD")
  # Make endpoint
  ep <- file.path(host, "parameters")
  # GET
  params <- content(GET(ep,
                        add_headers("uid" = uid),
                        authenticate(user=usr, password=pwd),
                        encode = "json"))
  # Return
  return(params)
}

#' Check if connection to server is possible
#'
#' @importFrom httr http_error
#'
#' @return TRUE if connection active, else FALSE
check_connection <- function() {
  serv <- Sys.getenv("SLEEPSIMR_MASTER_HOST")
  # Get retinas from the api
  httr::http_error(serv)
}

#' Register the address of the host server
#'
#' @param url url of the master host
#'
#' @return Exits silently
set_host <- function(url) {
  Sys.setenv("SLEEPSIMR_MASTER_HOST" = url)
}

#' Set the username/password to access the API
#'
#' @param password password used to authenticate with the API
#' @param username username used to authenticate with the API
#'
#' @return Exits silently
set_usr_pwd <- function(password, username) {
  Sys.setenv("SLEEPSIMR_API_USERNAME" = username)
  Sys.setenv("SLEEPSIMR_API_PASSWORD" = password)
}

#' Send the results of the simulation to the master node
#'
#' @param uid Character. unique ID of this simulation program
#' @param status Numeric. http status of the simulation program. See <https://www.restapitutorial.com/httpstatuscodes.html>.
#' @param diagnostics List. diagnostic information on the simulation scenario.
#'
#' @return
#'
#' @export
register_simulation_outcomes <- function(uid, status, diagnostics) {

}
