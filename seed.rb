$stdout.sync = true

require 'sequel'
require 'bcrypt'

DB = Sequel.connect(ENV['ELEPHANTSQL_URL'] || 'postgres://localhost/avnsp')

email    = ENV.fetch('ADMIN_EMAIL', 'admin@example.com')
password = ENV.fetch('ADMIN_PASSWORD', 'admin')

unless DB[:members].where(admin: true).any?
  DB[:members].insert(
    first_name:    'Admin',
    last_name:     'Admin',
    email:         email,
    password_hash: BCrypt::Password.create(password).to_s,
    admin:         true
  )
end

warn "┌──────────────────────────────────────────┐"
warn "│             Admin credentials            │"
warn "│  Email:    #{email.ljust(30)}│"
warn "│  Password: #{password.ljust(30)}│"
warn "└──────────────────────────────────────────┘"
