CREATE VIEW vw_artikli_kategorije AS
SELECT 
    k.naziv AS kategorija,
    a.naziv AS artikl,
    a.kolicina,
    a.cijena,
    (a.cijena * a.kolicina) AS ukupna_vrijednost
FROM artikl a
LEFT JOIN kategorija k ON a.id_kategorija = k.id
WHERE a.kolicina > 0
ORDER BY k.naziv, a.naziv;


CREATE VIEW vw_dobavljaci_artikli AS
SELECT 
    d.naziv_tvrtke AS dobavljac,
    COUNT(a.id) AS broj_artikala,
    COALESCE(SUM(a.kolicina), 0) AS ukupna_kolicina
FROM dobavljac d
LEFT JOIN artikl a ON d.id = a.id_dobavljac
GROUP BY d.naziv_tvrtke
ORDER BY broj_artikala DESC, ukupna_kolicina DESC;


CREATE VIEW vw_otpis_30dana AS
SELECT 
    a.naziv AS artikl,
    o.kolicina,
    o.razlog,
    o.datum,
    z.ime,
    z.prezime
FROM otpis o
JOIN artikl a ON o.id_artikl = a.id
JOIN zaposlenik z ON o.id_zaposlenik = z.id
WHERE o.datum >= CURDATE() - INTERVAL 30 DAY
ORDER BY o.datum DESC;


SELECT 
    s.naziv AS stroj,
    COUNT(eo.id) AS broj_odrzavanja,
    COALESCE(SUM(eo.iznos_troska), 0) AS ukupni_trosak,
    COALESCE(AVG(eo.iznos_troska), 0) AS prosjecni_trosak
FROM stroj s
LEFT JOIN evidencija_odrzavanja eo ON s.id = eo.id_stroj
GROUP BY s.naziv
ORDER BY ukupni_trosak DESC;

SELECT 
    z.ime,
    z.prezime,
    COUNT(DISTINCT r.id_stroj) AS broj_strojeva,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, r.vrijeme_pocetka, r.vrijeme_zavrsetka)) / 60, 2) AS ukupno_sati_rada
FROM rukovanje r
JOIN zaposlenik z ON r.id_zaposlenik = z.id
GROUP BY z.id
HAVING ukupno_sati_rada > 10
ORDER BY ukupno_sati_rada DESC
LIMIT 10;