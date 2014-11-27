require 'sequel'
require 'csv'

db = Sequel.connect 'postgres://localhost/avnsp'

CSV.foreach('./scripts/personer.csv', headers: true) do |raw|
  hash = {}
  raw.to_hash.each.map do |k,v|
    next unless k
    hash[k.strip.to_sym] = v.gsub('\\n', "\n").strip
  end
  #[:id, :ts, :fnamn, :enamn, :smek, :epost, :icq, :prog, :inskriv, :fritext, :last_checked]
  db[:members].insert(id: hash[:id],
                      first_name: hash[:fnamn],
                      last_name: hash[:enamn],
                      nick: hash[:smek],
                      email: hash[:epost],
                      studied: hash[:prog],
                      started: hash[:inskriv].to_i,
                      timestamp: hash[:ts])
end
