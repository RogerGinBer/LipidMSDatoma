FROM public.ecr.aws/docker/library/r-base:4.3.1 AS builder

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends libglpk40 libssl-dev libcurl4-openssl-dev libxml2-dev libnetcdf-dev pandoc wget \
    && rm -rf /var/lib/apt/lists/*

# Download and install Python 3.11
RUN wget https://www.python.org/ftp/python/3.11.0/Python-3.11.0.tar.xz \
    && tar -xf Python-3.11.0.tar.xz \
    && cd Python-3.11.0 \
    && ./configure --enable-optimizations \
    && make -j$(nproc) \
    && make altinstall \
    && cd .. \
    && rm -rf Python-3.11.0*

# Install pip for Python 3.11
RUN wget https://bootstrap.pypa.io/get-pip.py \
    && python3.11 get-pip.py \
    && rm get-pip.py


# Install R packages from CRAN
RUN install2.r --error \
    rmarkdown \
    BiocManager \
    pak \
    readr \
    magrittr \
    dplyr \
    data.table \
    xtable \
    aws.s3 \
    aws.ec2metadata

# Install Bioconductor packages
RUN Rscript -e 'BiocManager::install(c("MSnbase"))'

# Install remotes first
RUN Rscript -e "install.packages('remotes', repos='https://cloud.r-project.org')"

# Install slickR from GitHub
RUN Rscript -e "remotes::install_github('yonicd/slickR')"

# Now install your packages
RUN Rscript -e "pak::pkg_install(c('RogerGinBer/RHermes', 'maialba3/LipidMS', 'maialba3/FAMetA'))"

# Install Python packages
RUN python3.11 -m pip install \
    --break-system-packages \
    rpy2 \
    boto3 \
    requests-toolbelt \
    requests-aws4auth \
    requests \
    pyyaml \
    s3fs \
    aiohttp \
    aiofile \
    gql

FROM public.ecr.aws/docker/library/r-base:4.3.1

# Install runtime dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends libssl-dev libcurl4-openssl-dev libsqlite3-dev libglpk40 pandoc libxml2 libnetcdf22 wget procps \
    && rm -rf /var/lib/apt/lists/*

# Download and install Python 3.11
RUN wget https://www.python.org/ftp/python/3.11.0/Python-3.11.0.tar.xz \
    && tar -xf Python-3.11.0.tar.xz \
    && cd Python-3.11.0 \
    && ./configure --enable-optimizations --with-ensurepip=install \
    && make -j$(nproc) \
    && make altinstall \
    && cd .. \
    && rm -rf Python-3.11.0*

# Install pip for Python 3.11
RUN wget https://bootstrap.pypa.io/get-pip.py \
&& python3.11 get-pip.py \
&& rm get-pip.py


# Copy R packages from the builder image
COPY --from=builder /usr/local/lib/R/site-library/ /usr/local/lib/R/site-library/

# Copy Python packages from the builder image
COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/

COPY datomaconfig.yml /app/
COPY annotateLipids.Rmd /app/
COPY workflow_LipidMS.Rmd /app/

# Necessary files for running your tool on the Datoma infrastructure
COPY install_jobrunner.py /app/install_jobrunner.py
RUN chmod +x /app/install_jobrunner.py
COPY install_jobrunner_and_run.sh /app/install_jobrunner_and_run.sh
RUN chmod +x /app/install_jobrunner_and_run.sh

RUN mkdir /app/Output

WORKDIR /app
ENTRYPOINT ["/bin/bash" ,"/app/install_jobrunner_and_run.sh" ]