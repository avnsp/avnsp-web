Sequel.migration do
  up { run "CREATE TYPE party_type AS ENUM ('fest', 'arbetslunch')" }
  down { run "DROP TYPE party_type" }
end

