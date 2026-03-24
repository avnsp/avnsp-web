FROM docker.io/library/ruby:3.4.7-slim AS base

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      imagemagick \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

ENV RACK_ENV=production
ENV PORT=9393

EXPOSE 9393

CMD ["bundle", "exec", "puma", "-q", "-p", "9393", "-e", "production"]
