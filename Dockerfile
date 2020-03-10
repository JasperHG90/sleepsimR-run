## Script below has been taken from rocker/r-devel
## See: https://hub.docker.com/r/rocker/r-devel

FROM r-base

## Remain current
RUN apt-get update -qq \
	&& apt-get dist-upgrade -y

## From the Build-Depends of the Debian R package, plus subversion, and clang-3.8
## Compiler flags from https://www.stats.ox.ac.uk/pub/bdr/memtests/README.txt
##
## Also add   git autotools-dev automake  so that we can build littler from source
##
RUN apt-get update -qq \
	&& apt-get install -t unstable -y --no-install-recommends \
		automake \
		autotools-dev \
		bison \
		clang \
		libc++-dev \
		libc++abi-dev \
		gfortran \
		git \
		libblas-dev \
		libbz2-dev \
		libcurl4-openssl-dev \
		liblapack-dev \
	&& rm -rf /var/lib/apt/lists/*

## Add symlink and check out R-devel
RUN ln -s $(which llvm-symbolizer-7) /usr/local/bin/llvm-symbolizer \
	&& cd /tmp \
	&& svn co https://svn.r-project.org/R/trunk R-devel

## Build and install according extending the standard 'recipe' I emailed/posted years ago
## Leak detection does not work at build time, see https://github.com/google/sanitizers/issues/764 and the fact that we cannot add privileges during build (e.g. https://unix.stackexchange.com/q/329816/19205)
RUN cd /tmp/R-devel \
	&& R_PAPERSIZE=letter \
	   R_BATCHSAVE="--no-save --no-restore" \
	   R_BROWSER=xdg-open \
	   PAGER=/usr/bin/pager \
	   PERL=/usr/bin/perl \
	   R_UNZIPCMD=/usr/bin/unzip \
	   R_ZIPCMD=/usr/bin/zip \
	   R_PRINTCMD=/usr/bin/lpr \
	   LIBnn=lib \
	   AWK=/usr/bin/awk \
	   CC="clang -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero -fno-omit-frame-pointer -fsanitize-address-use-after-scope" \
	   CXX="clang++ -stdlib=libc++ -fsanitize=address,undefined -fno-sanitize=float-divide-by-zero -fno-omit-frame-pointer -fsanitize-address-use-after-scope" \
	   CFLAGS="-g -O3 -Wall -pedantic -mtune=native" \
	   FFLAGS="-g -O2 -mtune=native" \
	   FCFLAGS="-g -O2 -mtune=native" \
	   CXXFLAGS="-g -O3 -Wall -pedantic -mtune=native" \
	   MAIN_LD="clang++ -stdlib=libc++ -fsanitize=undefined,address" \
	   FC="gfortran" \
	   F77="gfortran" \
	   ASAN_OPTIONS=detect_leaks=0 \
	   ./configure --enable-R-shlib \
	       --without-blas \
	       --without-lapack \
	       --with-readline \
	       --without-recommended-packages \
	       --program-suffix=dev \
	       --disable-openmp \
	&& ASAN_OPTIONS=detect_leaks=0 make \
	&& ASAN_OPTIONS=detect_leaks=0 make install \
	&& ASAN_OPTIONS=detect_leaks=0 make clean

## Set Renviron to get libs from base R install
RUN echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron

## Set default CRAN repo
RUN echo 'options("repos"="http://cran.rstudio.com")' >> /usr/local/lib/R/etc/Rprofile.site

## to also build littler against RD
##   1)	 apt-get install git autotools-dev automake
##   2)	 use CC from RD CMD config CC, ie same as R
##   3)	 use PATH to include RD's bin, ie
## ie
##   CC="clang-3.5 -fsanitize=undefined -fno-sanitize=float-divide-by-zero,vptr,function -fno-sanitize-recover" \
##   PATH="/usr/local/lib/R/bin/:$PATH" \
##   ./bootstrap

## Create R-devel symlinks
RUN cd /usr/local/bin \
	&& mv R Rdevel \
	&& mv Rscript Rscriptdevel \
	&& ln -s Rdevel RD \
	&& ln -s Rscriptdevel RDscript

## Install sleepsimR api client
RUN R -e "devtools::install_github('JasperHG90/sleepsimRapiClient')"

## Copy app
COPY ./app /app

## Set entry point
ENTRYPOINT ["Rscript", "app/run_sleepsimR.R"]
