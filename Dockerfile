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
RUN R -e "remotes::install_github('JasperHG90/sleepsimR@91f45c9f5abe1cedb3f2fd08cbc7fbd5f39e3318', dependencies='Imports')"
RUN R -e "remotes::install_github('JasperHG90/sleepsimRapiClient@9f85b4570e514d419f11297c4d78cbfa660827ac', dependencies='Imports')"

## Copy app
COPY ./app /app

## Set entry point
ENTRYPOINT ["Rscript", "app/run_sleepsimR.R"]
