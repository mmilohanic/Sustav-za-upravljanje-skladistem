-- Upit 1: Popis svih narudžbi s osnovnim podacima o kupcu i statusu
SELECT 
    nk.broj_narudzbe,
    nk.datum_narudzbe,
    nk.status_narudzbe,
    k.naziv_tvrtke AS kupac,
    k.grad,
    k.drzava
FROM narudzba_kupca nk
JOIN kupac k ON nk.id_kupac = k.id;



-- Upit 2: Artikli i količine po narudžbi (detaljan prikaz)
SELECT 
    nk.broj_narudzbe,
    a.naziv AS artikl,
    snk.kolicina,
    a.cijena,
    (snk.kolicina * a.cijena) AS ukupno
FROM narudzba_kupca nk
JOIN stavka_narudzbe_kupca snk ON nk.id = snk.id_narudzba_kupca
JOIN artikl a ON snk.id_artikl = a.id
ORDER BY nk.broj_narudzbe;



-- Upit 3: Ukupna vrijednost svake narudžbe
SELECT 
    nk.broj_narudzbe,
    SUM(snk.kolicina * a.cijena) AS ukupna_vrijednost
FROM narudzba_kupca nk
JOIN stavka_narudzbe_kupca snk ON nk.id = snk.id_narudzba_kupca
JOIN artikl a ON snk.id_artikl = a.id
GROUP BY nk.broj_narudzbe;



-- Upit 4: Broj narudžbi po statusu
SELECT 
    status_narudzbe,
    COUNT(*) AS broj_narudzbi
FROM narudzba_kupca
GROUP BY status_narudzbe;



-- Upit 5: Narudžbe koje još nisu plaćene i podaci o prijevozniku
SELECT 
    nk.broj_narudzbe,
    nk.status_narudzbe,
    nk.datum_narudzbe,
    p.naziv_tvrtke AS prijevoznik
FROM narudzba_kupca nk
LEFT JOIN prijevoznik p ON nk.id_prijevoznik = p.id
WHERE nk.datum_placanja IS NULL;