#exportera medlemmar
echo "SELECT p.id, p.ts as timestamp, p.fnamn as first_name, p.enamn as last_name, p.smek as nick, p.epost as email, p.prog as studied, p.inskriv as started FROM person p" |mysql avnsp --default-character-set=utf8 > person.csv

#exportera arren
echo "select a.id, a.datum as date, a.namn as name, a.plats as location, a.tema as theme, a.avgift as price, b.nummer as booking_account_number, a.fritext as comment from arr a left join bokkonto b on a.bokkid = b.id" |mysql avnsp --default-character-set=utf8 > arr.csv

#export anmälningslista
echo "select arrid as party_id, persid as member_id, fritext as message, veg as vegitarian, alkfri as non_alcoholic, kost as allergies from anm" |mysql avnsp --default-character-set=utf8 > anm.csv

#export fotoalbum
echo "select id, persid as created_by, arrid as party_id, skapad as timestamp, namn as name from album" |mysql avnsp --default-character-set=utf8 > album.csv

#export foton
echo "select id, albid as album_id, dt as timestamp, orgfil as name from bild" |mysql avnsp --default-character-set=utf8 > bild.csv

