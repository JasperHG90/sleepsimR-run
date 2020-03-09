## Communicate with the simulator setting API

#' Fetch simulation settings used for this simulation scenario
#'
query_simulation_settings <- function() {

}

#' Check if connection to server is possible
#'
#' @importFrom httr http_error
#'
#' @export
check_connection <- function() {
  serv <- Sys.getenv("SLEEPSIMR_MASTER_HOST")
  # Get retinas from the api
  httr::http_error(serv)
}

#' Register the address of the host server
#'
#' @param url url of the master host
#'
#' @export
set_host <- function(url) {
  Sys.setenv("SLEEPSIMR_MASTER_HOST" = url)
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
