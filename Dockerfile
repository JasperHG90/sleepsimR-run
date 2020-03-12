##
FROM r-base

# Install R devtools
RUN apt-get update && \
  apt-get install -y libcurl4-openssl-dev libssl-dev libssh2-1-dev libxml2-dev && \
  R -e "install.packages('remotes', dependencies = c('Imports', 'Depends'))"

## Install sleepsimR api client
RUN R -e "remotes::install_github('JasperHG90/sleepsimR@a939b956e3cc27402472c323e5d4b7ea69f55231', dependencies='Imports')"
RUN R -e "remotes::install_github('JasperHG90/sleepsimRapiClient@1ea8e5bf2d8adaae53f6666d1d6b623fc5cc9cbb', dependencies='Imports')"
RUN R -e "install.packages('argparser')"
RUN R -e "install.packages('logger')"

## Copy app
COPY ./app /app

## Set entry point
ENTRYPOINT ["Rscript", "app/run_sleepsimR.R"]
