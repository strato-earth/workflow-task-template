FROM ubuntu:latest

# Install dependencies for executables (if any)
# RUN apt-get update && \
#     apt-get install -y --no-install-recommends \
#         libsome-library-dev \
#         libanother-library-dev

# Copy built executables to the image
COPY build/executable1 /usr/local/bin/

# Set permissions on executables
RUN chmod +x /usr/local/bin/executable1

ENTRYPOINT ["entrypoint.sh"]
