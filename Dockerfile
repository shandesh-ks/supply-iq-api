## syntax = docker/dockerfile:1
#
#ARG RUBY_VERSION=3.1.4
#ARG PYTHON_VERSION=3.9
#
## 🏗 Base image: Use Ruby Slim
#FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base
#
#WORKDIR /rails
#
## ✅ Install system dependencies for Ruby, Python, and ML libraries
#RUN apt-get update -qq && apt-get install --no-install-recommends -y \
#    curl libjemalloc2 libvips sqlite3 build-essential git pkg-config \
#    python-is-python3 python3 python3-pip python3-venv \
#    && rm -rf /var/lib/apt/lists/*
#
## ✅ Set environment variables for Rails
#ENV RAILS_ENV="production" \
#    BUNDLE_DEPLOYMENT="1" \
#    BUNDLE_PATH="/usr/local/bundle" \
#    BUNDLE_WITHOUT="development"
#
## 🏗 Build image: Install Ruby gems
#FROM base AS build
#
#COPY Gemfile Gemfile.lock ./
#
## ✅ Ensure Bundler 2.4.19 is installed
#RUN gem install bundler -v 2.4.19 && \
#    bundle install && \
#    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
#    bundle exec bootsnap precompile --gemfile
#
## 🏗 Copy Rails application files
#COPY . .
#
## ✅ Precompile assets and migrate DB
#RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
#    bundle exec rails db:migrate
#
## ✅ Install Python dependencies in a virtual environment
#COPY requirements.txt .
#RUN python3 -m venv /venv && \
#    /venv/bin/python3 -m pip install --break-system-packages --no-cache-dir -r requirements.txt
#
## 🏗 Final image: Use minimal Ruby runtime
#FROM base
#
#COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
#COPY --from=build /rails /rails
#COPY --from=build /venv /venv
#
## ✅ Set up Rails user
#RUN groupadd --system --gid 1000 rails && \
#    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
#    chown -R rails:rails db log storage tmp
#
#USER 1000:1000
#
#EXPOSE ${PORT:-3000}
#
## ✅ Final CMD: Ensure Python is available and start Rails server
##CMD ["./bin/rails", "server"]
##CMD ["bash", "-c", "/venv/bin/python3 --version && bundle exec rails server -b 0.0.0.0 -p $PORT"]
#CMD ["/bin/sh", "-c", "/venv/bin/python3 --version && exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]

# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.1.4
ARG PYTHON_VERSION=3.9

# Use Ruby base image
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install system dependencies for Ruby, Python, and ML libraries
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl libjemalloc2 libvips sqlite3 \
    build-essential git pkg-config \
    python${PYTHON_VERSION} python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables for Rails
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Build stage to install dependencies
FROM base AS build

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy Rails application files
COPY . .

# Precompile assets and migrate DB
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
    bundle exec rails db:migrate

# Install Python dependencies
COPY requirements.txt .
RUN python3 -m venv /venv && \
    /venv/bin/pip install --no-cache-dir -r requirements.txt

# Final production image
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails
COPY --from=build /venv /venv

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

EXPOSE ${PORT:-3000}

CMD ["/bin/sh", "-c", "/venv/bin/python3 --version && exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
