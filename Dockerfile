# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.1.4
ARG PYTHON_VERSION=3.9

# Use Ruby base image
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install system dependencies for Ruby, Python, and ML libraries
RUN apt-get update -qq && apt-get install --no-install-recommends -y \
    curl libjemalloc2 libvips sqlite3 build-essential git pkg-config \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

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
COPY requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Final production image
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Ensure Python dependencies are installed globally
COPY --from=build /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=build /usr/local/bin /usr/local/bin

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

EXPOSE ${PORT:-3000}

CMD ["/bin/sh", "-c", "python3 --version && exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
