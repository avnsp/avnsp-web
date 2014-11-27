require 'sequel'
require 'csv'

db = Sequel.connect 'postgres://localhost/avnsp'
konton = {
  1 =>  2021 ,
  2 =>  1920 ,
  3 =>  1910 ,
  5 =>  7320 ,
  6 =>  4010 ,
  7 =>  3021 ,
  8 =>  3022 ,
  9 =>  6250 ,
  10 => 3001 ,
  11 => 3002 ,
  12 => 3003 ,
  13 => 3004 ,
  14 => 4001 ,
  15 => 4002 ,
  16 => 4003 ,
  17 => 4004
}

CSV.foreach('./scripts/arr.csv', headers: true) do |raw|
  hash = {}
  raw.to_hash.each.map do |k,v|
    next unless k
    hash[k.strip.to_sym] = v.gsub('\\n', "\n").strip
  end
  #[:id , :datum , :namn , :plats , :tema , :anm , :avgift , :bokkid , :stopp , :fritext]
  ban = konton[hash[:bokkid].to_i]
  db[:parties].insert(id:   hash[:id],
                      name: hash[:namn],
                      date: hash[:datum],
                      location: hash[:plats],
                      comment: hash[:fritext],
                      theme: hash[:tema],
                      booking_account_number: ban,
                      price: hash[:pris])
end
