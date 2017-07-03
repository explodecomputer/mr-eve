FROM ubuntu:14.04

MAINTAINER "Gibran Hemani" g.hemani@bristol.ac.uk


# set user
RUN useradd docker \
  && mkdir /home/docker \
  && chown docker:docker /home/docker \
  && addgroup docker staff

RUN apt-get update && apt-get install -y \
    gdebi-core \
    pandoc pandoc-citeproc \
    libproj-dev libgdal-dev \
    libxml2-dev libxt-dev libcairo2-dev \
    libssh2-1-dev libcurl4-openssl-dev \
    less git make wget nano \
    software-properties-common python-software-properties \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install R
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list \
  && apt-get update \
  && apt-get install r-base-core -y --force-yes \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set default CRAN repo and DL method
RUN echo 'options(repos=c(CRAN = "https://cran.rstudio.com/"), download.file.method="libcurl")' >> /etc/R/Rprofile.site

# install R packages
RUN sudo su - -c "R -e \"install.packages(c('shiny','RNeo4j'))\""

# Download and install latest version of shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
   VERSION=$(cat version.txt)  && \
   wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
   gdebi -n ss-latest.deb && \
   rm -f version.txt ss-latest.deb && \
   cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/

# expose port to access app
EXPOSE 3838

# give docker user permission to write to logs
RUN chown docker /var/log/shiny-server

# Copy app across
# e.g. git clone git@github.com:explodecomputer/mr-eve.git && cd mr-eve/shiny/ && docker build -t mr-eve-shiny .

RUN sudo su - -c "R -e \"install.packages(c('shinydashboard'))\""

RUN rm -r /srv/shiny-server/*
COPY . /srv/shiny-server/

# start it
CMD exec shiny-server >> /var/log/shiny-server.log 2>&1
