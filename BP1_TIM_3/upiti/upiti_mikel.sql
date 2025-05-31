-- Upit 1
CREATE VIEW 10_najtrazenijih_artikala AS
SELECT   a.naziv AS naziv_artikla,
		 k.naziv AS kategorija,
         d.naziv_tvrtke AS dobavljac,
		 najtrazeniji.broj_narudzbi
FROM     artikl a
JOIN     (SELECT   id_artikl,
				   COUNT(id) AS broj_narudzbi
		  FROM     stavka_narudzbe_kupca
		  GROUP BY id_artikl
		  ORDER BY broj_narudzbi DESC
          LIMIT    10)
          AS najtrazeniji
          ON a.id = najtrazeniji.id_artikl
JOIN	 dobavljac d ON a.id_dobavljac = d.id
JOIN	 kategorija k ON a.id_kategorija = k.id;

-- Upit 2
CREATE VIEW trenutni_godisnji_promet AS
SELECT   SUM(artikl.cijena * placeni_artikli.ukupno_artikla) AS trenutni_godisnji_promet
FROM	 (SELECT   id_artikl,
				   SUM(kolicina) AS ukupno_artikla
		  FROM	   stavka_narudzbe_kupca
		  WHERE	   id_narudzba_kupca
		  IN	   (SELECT   id
		 		    FROM     narudzba_kupca
				    WHERE	 status_narudzbe = 'Plaćeno' AND YEAR(datum_placanja) = YEAR(CURDATE()))
		 GROUP BY id_artikl)
		 AS placeni_artikli
JOIN	 artikl ON placeni_artikli.id_artikl = artikl.id;

-- Upit 3
CREATE VIEW otpisi_unatrag_mjesec_dana AS
SELECT    a.naziv,
		  o.kolicina,
          o.razlog,
          o.datum,
          z.ime,
          z.prezime
FROM	  otpis o
LEFT JOIN artikl a ON o.id_artikl = a.id
LEFT JOIN zaposlenik z ON o.id_zaposlenik = z.id
WHERE	  datum >= CURDATE() - INTERVAL 1 MONTH;

-- Upit 4
CREATE VIEW strojevi_s_ukupnim_troskom_vecim_od_1500 AS
SELECT	 s.naziv, 
		 trosak.ukupno
FROM	 stroj s
JOIN	 (SELECT   id_stroj,
				   SUM(iznos_troska) AS ukupno
		  FROM	   evidencija_odrzavanja
		  GROUP BY id_stroj
		  HAVING   ukupno > 1500)
		  AS trosak
WHERE 	  trosak.id_stroj = s.id
ORDER BY  trosak.ukupno DESC;

-- Upit 5
CREATE VIEW ukupni_trosak_po_otpisanim_artiklima AS
SELECT    a.naziv, 
		  SUM(a.cijena * o.kolicina) AS ukupni_trosak
FROM	  otpis o
LEFT JOIN artikl a ON o.id_artikl = a.id
GROUP BY  a.id
ORDER BY  ukupni_trosak DESC;

-- Upit 6
CREATE VIEW zaposlenici_po_pozicijama AS
SELECT   pozicija, 
		 COUNT(id) AS broj_zaposlenika
FROM	 zaposlenik
GROUP BY pozicija;