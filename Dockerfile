FROM ruby:3.2

# Install system dependencies and Ruby tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      nodejs \
      git \
      graphviz \
    && gem install \
      bundler -v 2.1.4 \
      webrick \
    && gem uninstall bundler -v '>= 3' || true \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# Copy only Gemfile and Gemfile.lock to leverage Docker layer caching
COPY Gemfile Gemfile.lock /tmp/

# Install gems during build
RUN cd /tmp && bundle install --jobs 4 --retry 3 --path /usr/local/bundle

# Set the working directory for the app
WORKDIR /usr/src/app

# Jekyll serves on port 4000
EXPOSE 4000

# Default command: run jekyll serve using mounted folder
CMD ["bash", "-c", "./dotenv bundle exec jekyll serve --host 0.0.0.0 -w --config _config.yml,_config_docker.yml --watch"]
