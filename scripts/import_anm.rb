require 'sequel'
require 'csv'

db = Sequel.connect 'postgres://localhost/avnsp'

CSV.foreach('./scripts/anm.csv', headers: true) do |raw|
  hash = {}
  raw.to_hash.each.map do |k,v|
    next unless k
    hash[k.strip.to_sym] = v.gsub('\\n', "\n").strip
  end
  #[:id, :arrid, :persid, :namn, :arr, :veg, :alkfri, :kost, :fritext, :bet, :transid]
  db[:attendances].insert(vegitarian: hash[:veg].to_i == 1,
                          non_alcoholic: hash[:alkfri].to_i == 1,
                          allergies: hash[:kost],
                          party_id: hash[:arrid],
                          member_id: hash[:persid])
end
