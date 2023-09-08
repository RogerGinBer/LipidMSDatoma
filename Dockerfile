FROM public.ecr.aws/docker/library/r-base AS builder

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends libglpk40 libssl-dev libcurl4-openssl-dev libxml2-dev libnetcdf-dev pandoc python3.11 python3.11-dev python3-pip \
    && rm -rf /var/lib/apt/lists/*

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

# Install R application packages
RUN Rscript -e 'pak::pkg_install(c("RogerGinBer/RHermes", "maialba3/LipidMS"))'

ARG PIP_EXTRA_INDEX_URL

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
    gql \
    datoma-jobrunner

FROM public.ecr.aws/docker/library/r-base

# Install runtime dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends libglpk40 pandoc libxml2 libnetcdf19 python3.11 procps \
    && rm -rf /var/lib/apt/lists/*

# Copy R packages from the builder image
COPY --from=builder /usr/local/lib/R/site-library/ /usr/local/lib/R/site-library/

# Copy Python packages from the builder image
COPY --from=builder /usr/local/lib/python3.11/dist-packages/ /usr/local/lib/python3.11/dist-packages/

COPY datomaconfig.yml /app/
COPY annotateLipids.Rmd /app/

WORKDIR /app
ENTRYPOINT [ "python3.11", "-m", "datoma_jobrunner.entrypoint" ]
