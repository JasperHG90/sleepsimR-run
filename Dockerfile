## Base image
FROM r-base

# Install R devtools
RUN apt-get update && \
  apt-get install -y libcurl4-openssl-dev libssl-dev libssh2-1-dev libxml2-dev && \
  R -e "install.packages('remotes', dependencies = c('Imports', 'Depends'))"

## Install sleepsimR api client
RUN R -e "remotes::install_github('emmekeaarts/mHMMbayes@369420e05cb96e6af761a8bd9bd30b8539d27a24', dependencies='Imports')"
RUN R -e "install.packages('argparser')"
RUN R -e "install.packages('logger')"
RUN R -e "remotes::install_github('JasperHG90/sleepsimR@57c8419a96abbb599bb9677526c9192674c9ba8b', dependencies='Imports')"
RUN R -e "remotes::install_github('JasperHG90/sleepsimRapiClient@426471c14fdc0d695eb58270154763eaeef56148', dependencies='Imports')"

## Copy app
COPY ./app /app

## Set entry point
ENTRYPOINT ["Rscript", "app/run_sleepsimR.R"]
