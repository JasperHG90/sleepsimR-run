##
FROM r-base

# Install R devtools
RUN apt-get update && \
  apt-get install -y libcurl4-openssl-dev libssl-dev libssh2-1-dev libxml2-dev && \
  R -e "install.packages('remotes', dependencies = c('Imports', 'Depends'))"

## Install sleepsimR api client
RUN R -e "remotes::install_github('JasperHG90/sleepsimR@8802534972644adc9a32568ae63cba86c2c26ddb', dependencies='Imports')"
RUN R -e "remotes::install_github('JasperHG90/sleepsimRapiClient@bb3d02e8b74e686a3272315c82c0eae7845a0fc2', dependencies='Imports')"
RUN R -e "install.packages('argparser')"
RUN R -e "install.packages('logger')"

## Copy app
COPY ./app /app

## Set entry point
ENTRYPOINT ["Rscript", "app/run_sleepsimR.R"]
