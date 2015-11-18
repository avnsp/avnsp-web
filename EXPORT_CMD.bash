#exportera medlemmar
echo "SELECT p.id, p.ts as timestamp, p.fnamn as first_name, p.enamn as last_name, p.smek as nick, p.epost as email, p.prog as studied, p.inskriv as started FROM person p" |mysql avnsp --default-character-set=utf8 > person.csv

#exportera arren
echo "select a.id, a.datum as date, a.namn as name, a.plats as location, a.tema as theme, a.avgift as price, b.nummer as booking_account_number, a.fritext as comment from arr a, bokkonto b where a.bokkid = b.id" |mysql avnsp --default-character-set=utf8 > arr.csv

#export anmälningslista
echo "select arrid as party_id, persid as member_id, fritext as message, veg as vegiterian, alkfri as non_alcoholic, kost as allergies from anm limit 1" |mysql avnsp --default-character-set=utf8 > anm.csv


