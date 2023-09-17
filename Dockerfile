FROM alpine:latest

# Maintainer info
LABEL maintainer="jmok@veracode.com"

RUN apk add --no-cache git bash

RUN git clone https://github.com/m4ckdaddy/ReportingAPI.git /app

# Set the working directory
WORKDIR /app

# Provide execute permissions to the shell scripts
RUN chmod +x *.sh

# Default command to run your script
CMD ["./one-week-results.sh"]
