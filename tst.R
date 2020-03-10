library(httr)

# Check for error
http_error("http://localhost:5002")

# Get the number of allocated/completed iterations
content(GET("http://localhost:5002/info", authenticate(user="container", password="mypwd")))

# Retrieve a set of parameters
params <- content(GET("http://localhost:5002/parameters",
                      #add_headers("uid" = "abcdef"),
                      authenticate(user="container", password="mypwd"),
                      encode = "json"))
# Get iteration id
iid <- params$iteration_id[[1]]

# Make bs list of parameters
nb <- list(
  "uid" = "abcdef",
  "scenario_uid" = params$scenario_id[[1]],
  "iteration_uid" = params$iteration_id[[1]],
  "emiss_mu_bar" = c(3,1,9),
  "gamma_int_bar" = c(1,2,5,3,6,6),
  "emiss_var_bar" = c(2,1,5),
  "emiss_varmu_bar" = c(7,1,2),
  "credible_intervals" = c(4,1,2)
)

# POST
content(POST("http://localhost:5002/results",
             body=nb,
             authenticate(user="container", password="mypwd"),
             encode="json"))
