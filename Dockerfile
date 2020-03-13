## Base image
FROM r-base

# Install R devtools
RUN apt-get update && \
  apt-get install -y libcurl4-openssl-dev libssl-dev libssh2-1-dev libxml2-dev && \
  R -e "install.packages('remotes', dependencies = c('Imports', 'Depends'))"

## Install sleepsimR api client
RUN R -e "remotes::install_github('emmekeaarts/mHMMbayes@369420e05cb96e6af761a8bd9bd30b8539d27a24', dependencies='Imports')"
RUN R -e "remotes::install_github('JasperHG90/sleepsimR@v0.1', dependencies='Imports')"
RUN R -e "remotes::install_github('JasperHG90/sleepsimRapiClient@v0.1', dependencies='Imports')"
RUN R -e "install.packages('argparser')"
RUN R -e "install.packages('logger')"

## Copy app
COPY ./app /app

## Set entry point
ENTRYPOINT ["Rscript", "app/run_sleepsimR.R"]
