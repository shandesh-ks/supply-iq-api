# Build stage to install dependencies
FROM base AS build

# Copy Ruby dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy Rails application files
COPY . .

# Precompile assets and migrate DB
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
    bundle exec rails db:migrate

# Install Python dependencies (Fixes externally managed error)
COPY requirements.txt .
RUN python3 -m venv /venv && \
    /venv/bin/python3 -m pip install --break-system-packages --no-cache-dir -r requirements.txt
