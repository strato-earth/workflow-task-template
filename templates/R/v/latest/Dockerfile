# Stage 1: Build environment to compile R (using Amazon Linux 2023)
FROM amazonlinux:2023 AS builder

# Install necessary development tools and libraries using dnf
RUN dnf update -y && \
    dnf install -y \
        gcc \
        gcc-c++ \
        gcc-gfortran \
        make \
        libX11-devel \
        libXt-devel \
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
        libRmath-devel \
        openssl-devel \
        git \
        tar \
        which \
        unzip && \
    dnf clean all && rm -rf /var/cache/dnf/*

# Set R version to 4.4.1
ENV R_VERSION=4.4.1

# Download and install R
RUN curl -O https://cran.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz && \
    tar -zxvf R-${R_VERSION}.tar.gz && \
    cd R-${R_VERSION} && \
    ./configure --with-x=no --enable-R-shlib --with-readline=yes --enable-BLAS-shlib --enable-R-static-lib && \
    make && \
    make install && \
    cd .. && \
    rm -rf R-${R_VERSION} R-${R_VERSION}.tar.gz

FROM public.ecr.aws/lambda/provided:al2023

RUN dnf update -y && \
    dnf install -y \
        unzip jq && \
    dnf clean all && rm -rf /var/cache/dnf/*

COPY --from=builder /usr/local/bin/R /usr/local/bin/R
COPY --from=builder /usr/local/bin/Rscript /usr/local/bin/Rscript
COPY --from=builder /usr/local/lib64/R /usr/local/lib64/R

COPY --from=builder /usr/lib64/libgfortran.so.5 /usr/lib64/libgfortran.so.5
COPY --from=builder /usr/lib64/libm.so.6 /usr/lib64/libm.so.6
COPY --from=builder /usr/lib64/libquadmath.so.0 /usr/lib64/libquadmath.so.0
COPY --from=builder /usr/lib64/libreadline.so.8 /usr/lib64/libreadline.so.8
COPY --from=builder /usr/lib64/libpcre2-8.so.0 /usr/lib64/libpcre2-8.so.0
COPY --from=builder /usr/lib64/liblzma.so.5 /usr/lib64/liblzma.so.5
COPY --from=builder /usr/lib64/libbz2.so.1 /usr/lib64/libbz2.so.1
COPY --from=builder /usr/lib64/libz.so.1 /usr/lib64/libz.so.1
COPY --from=builder /usr/lib64/libicuuc.so.67 /usr/lib64/libicuuc.so.67
COPY --from=builder /usr/lib64/libicui18n.so.67 /usr/lib64/libicui18n.so.67
COPY --from=builder /usr/lib64/libgomp.so.1 /usr/lib64/libgomp.so.1
COPY --from=builder /usr/lib64/libc.so.6 /usr/lib64/libc.so.6
COPY --from=builder /usr/lib64/ld-linux-x86-64.so.2 /usr/lib64/ld-linux-x86-64.so.2
COPY --from=builder /usr/lib64/libgcc_s.so.1 /usr/lib64/libgcc_s.so.1
COPY --from=builder /usr/lib64/libtinfo.so.6 /usr/lib64/libtinfo.so.6
COPY --from=builder /usr/lib64/libicudata.so.67 /usr/lib64/libicudata.so.67
COPY --from=builder /usr/lib64/libstdc++.so.6 /usr/lib64/libstdc++.so.6

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/ && \
    rm -rf /var/cache/dnf/* /tmp/*

COPY src/ /var/task/
RUN chmod +x /var/task/*.sh && mv /var/task/bootstrap.sh /var/runtime/bootstrap

RUN R -e "install.packages(c('dplyr', 'httr', 'tibble', 'jsonlite', 'rmarkdown', 'testthat', 'tidyselect' ,'withr'), repos='http://cran.rstudio.com/')"

WORKDIR /var/task

ENTRYPOINT ["/var/task/entrypoint.sh"]
