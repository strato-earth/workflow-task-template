FROM public.ecr.aws/lambda/provided:al2023

# Set R version
ENV R_VERSION=4.4.1

# Set locale variables to avoid warnings
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install necessary packages, including perl
RUN dnf update -y && \
    dnf install -y \
        gcc \
        gcc-c++ \
        gcc-gfortran \
        make \
        readline-devel \
        zlib-devel \
        bzip2-devel \
        xz-devel \
        pcre2-devel \
        curl-devel \
        libjpeg-turbo-devel \
        libpng-devel \
        cairo-devel \
        pango-devel \
        tcl-devel \
        tk-devel \
        blas-devel \
        lapack-devel \
        libicu-devel \
        openssl-devel \
        tar \
        which \
        perl \
        jq \
        unzip \
        glibc-langpack-en && \
    dnf clean all && rm -rf /var/cache/dnf/*

# Download and install R with all base packages and proper flags
RUN curl -O https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz && \
    tar -zxvf R-${R_VERSION}.tar.gz && \
    cd R-${R_VERSION} && \
    ./configure --with-x=no \
                --enable-R-shared \
                --with-readline \
                --enable-BLAS-shlib \
                --with-recommended-packages && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf R-${R_VERSION}*

# Install R packages
RUN R -e "install.packages(c('dplyr', 'httr', 'tibble', 'jsonlite', 'rmarkdown', 'testthat', 'tidyselect', 'withr'), repos='http://cran.rstudio.com/')"

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/ && rm -rf /var/cache/dnf/* /tmp/*

# Copy application code
COPY src/ /var/task/
RUN chmod +x /var/task/*.sh && mv /var/task/bootstrap.sh /var/runtime/bootstrap

WORKDIR /var/task

ENTRYPOINT ["/var/task/entrypoint.sh"]
