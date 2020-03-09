httr::http_error("http://localhost:5002")

httr::content(httr::GET("http://localhost:5002/info"))

params <- httr::content(httr::POST("http://localhost:5002/parameters", body=list("uid"= "abcde"), encode = "json"))
iid <- params$iteration_id

nb <- list(
  "uid" = "abcde",
  "scenario_uid" = params$scenario_id[[1]],
  "iteration_uid" = params$iteration_id[[1]],
  "emiss_mu_bar" = c(3,1,9),
  "gamma_int_bar" = c(1,2,5,3,6,6),
  "emiss_var_bar" = c(2,1,5),
  "emiss_varmu_bar" = c(7,1,2),
  "credible_intervals" = c(4,1,2)
)

httr::content(httr::POST("http://localhost:5002/results", body=nb, encode="json"))
