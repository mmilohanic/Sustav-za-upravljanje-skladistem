-- 5 najskupljih artikala i njihovi dobavljači
SELECT 
    a.naziv AS artikl,
    a.cijena,
    d.naziv_tvrtke AS dobavljac
FROM artikl a
JOIN dobavljac d ON a.id_dobavljac = d.id
ORDER BY a.cijena DESC
LIMIT 5;

-- Zaposlenici s najviše ulazaka u skladište
SELECT 
    z.id,
    z.ime,
    z.prezime,
    COUNT(ep.id) AS broj_ulazaka
FROM zaposlenik z
JOIN evidencija_pristupa ep ON z.id = ep.id_zaposlenik
GROUP BY z.id
ORDER BY broj_ulazaka DESC
LIMIT 5;

-- Strojevi koji se najviše koriste (prema broju rukovanja)
SELECT 
    s.id,
    s.naziv,
    s.tip,
    COUNT(r.id) AS broj_rukovanja
FROM stroj s
JOIN rukovanje r ON s.id = r.id_stroj
GROUP BY s.id
ORDER BY broj_rukovanja DESC;

-- Najčešći razlog otpisa artikala
SELECT razlog, COUNT(*) AS broj_otpisa
FROM otpis
GROUP BY razlog
ORDER BY broj_otpisa DESC
LIMIT 3;

-- Evidencija otpisanih artikala s razlogom i zaposlenikom
CREATE VIEW pogled_otpis_artikala AS
SELECT
    o.id AS id_otpis,
    a.naziv AS artikl,
    o.kolicina,
    o.razlog,
    o.datum,
    z.ime,
    z.prezime
FROM otpis o
JOIN artikl a ON o.id_artikl = a.id
JOIN zaposlenik z ON o.id_zaposlenik = z.id;