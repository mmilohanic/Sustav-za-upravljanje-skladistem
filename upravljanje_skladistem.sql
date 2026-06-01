-- SHOW VARIABLES LIKE 'secure_file_priv'; # Pokrenuti ovu naredbu da vidite kamo treba premjestiti/kopirati direktorij 'data'
# Pokrenuti sve odjednom nakon što su podešene postavke za uvoz podataka koristeći CSV datoteke (kursor na prazan redak i klik na ikonu gdje je samo munja)

DROP DATABASE IF EXISTS upravljanje_skladistem;
CREATE DATABASE upravljanje_skladistem;
USE upravljanje_skladistem;
SET GLOBAL local_infile = 1;

CREATE TABLE zaposlenik (
	id INTEGER AUTO_INCREMENT,
    ime VARCHAR(20) NOT NULL,
    prezime VARCHAR(30) NOT NULL,
    pozicija VARCHAR(30) NOT NULL,
    datum_zaposlenja DATE NOT NULL,
    
    PRIMARY KEY (id)
);

CREATE TABLE evidencija_pristupa (
	id INTEGER AUTO_INCREMENT,
    vrijeme_ulaska DATETIME NOT NULL,
    vrijeme_izlaska DATETIME NOT NULL,
    id_zaposlenik INTEGER,
    
    PRIMARY KEY (id),
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE SET NULL
);

CREATE TABLE kupac (
	id INTEGER AUTO_INCREMENT,
    naziv_tvrtke VARCHAR(50) NOT NULL,
    oib CHAR(11) NOT NULL UNIQUE,
    kontakt_telefon VARCHAR(20),
    email VARCHAR(35) NOT NULL,
    drzava VARCHAR(30) NOT NULL,
    grad VARCHAR(20) NOT NULL,
    ulica VARCHAR(40) NOT NULL,
    postanski_broj VARCHAR(10) NOT NULL,
    
    CHECK (email LIKE '%@%.%'),
    
    PRIMARY KEY (id)
);

CREATE TABLE prijevoznik (
	id INTEGER AUTO_INCREMENT,
    naziv_tvrtke VARCHAR(50) NOT NULL,
    oib CHAR(11) NOT NULL UNIQUE,
    kontakt_telefon VARCHAR(20),
    email VARCHAR(35) NOT NULL,
    zajamceni_rok_isporuke INTEGER NOT NULL,
    
    CHECK (zajamceni_rok_isporuke > 0),
    CHECK (email LIKE '%@%.%'),
    
    PRIMARY KEY (id)
);

CREATE TABLE dobavljac (
	id INTEGER AUTO_INCREMENT,
    naziv_tvrtke VARCHAR(50) NOT NULL,
    oib CHAR(11) NOT NULL UNIQUE,
    kontakt_telefon VARCHAR(20),
    email VARCHAR(35) NOT NULL,
    
    CHECK (email LIKE '%@%.%'),
    
    PRIMARY KEY (id)
);

CREATE TABLE kategorija (
	id INTEGER AUTO_INCREMENT,
    naziv VARCHAR(50) NOT NULL UNIQUE,
    opis TEXT,
    
    PRIMARY KEY (id)
);

CREATE TABLE artikl (
	id INTEGER AUTO_INCREMENT,
    naziv VARCHAR(50) NOT NULL UNIQUE,
    opis TEXT,
    cijena NUMERIC(9,2) NOT NULL,
    kolicina INTEGER NOT NULL,
    id_kategorija INTEGER NOT NULL,
    id_dobavljac INTEGER,
    
    CHECK (kolicina >= 0),
    
    PRIMARY KEY (id),
    FOREIGN KEY (id_kategorija) REFERENCES kategorija (id),
    FOREIGN KEY (id_dobavljac) REFERENCES dobavljac (id) ON DELETE SET NULL
);

CREATE TABLE narudzba_kupca (
	id INTEGER AUTO_INCREMENT,
    datum_narudzbe DATE DEFAULT (CURRENT_DATE),
    broj_narudzbe VARCHAR(10) NOT NULL UNIQUE,
    status_narudzbe ENUM('Zaprimljeno', 'Obrada', 'Poslano', 'Isporučeno', 'Plaćeno') NOT NULL,
    datum_placanja DATE,
    id_kupac INTEGER NOT NULL,
    id_prijevoznik INTEGER,
    
    PRIMARY KEY (id),
    FOREIGN KEY (id_kupac) REFERENCES kupac (id) ON DELETE CASCADE,
    FOREIGN KEY (id_prijevoznik) REFERENCES prijevoznik (id) ON DELETE SET NULL
);

CREATE TABLE stavka_narudzbe_kupca (
	id INTEGER AUTO_INCREMENT,
    id_narudzba_kupca INTEGER NOT NULL,
    id_artikl INTEGER NOT NULL,
    kolicina INTEGER NOT NULL,
    
    UNIQUE (id_narudzba_kupca, id_artikl),
    
    PRIMARY KEY (id),
    FOREIGN KEY (id_narudzba_kupca) REFERENCES narudzba_kupca (id) ON DELETE CASCADE,
    FOREIGN KEY (id_artikl) REFERENCES artikl (id)
);

CREATE TABLE otpis (
	id INTEGER AUTO_INCREMENT,
    id_artikl INTEGER NOT NULL,
    kolicina INTEGER NOT NULL,
    razlog TEXT,
    datum DATE NOT NULL,
    id_zaposlenik INTEGER,
    
    CHECK (kolicina > 0),
    
    PRIMARY KEY (id),
    FOREIGN KEY (id_artikl) REFERENCES artikl (id) ON DELETE CASCADE,
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE SET NULL
);

CREATE TABLE narudzba_dobavljacu (
	id INTEGER AUTO_INCREMENT,
    datum_narudzbe DATE DEFAULT (CURRENT_DATE),
    broj_narudzbe VARCHAR(10) NOT NULL UNIQUE,
    status_narudzbe ENUM('Naručeno', 'U obradi', 'Na čekanju', 'U tranzitu', 'Dostavljeno') NOT NULL,
    id_dobavljac INTEGER,
    id_zaposlenik INTEGER,
    
    PRIMARY KEY (id),
    FOREIGN KEY (id_dobavljac) REFERENCES dobavljac (id) ON DELETE SET NULL,
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE SET NULL
);

CREATE TABLE stavka_narudzbe_dobavljacu (
	id INTEGER AUTO_INCREMENT,
    id_narudzba_dobavljacu INTEGER NOT NULL,
    id_artikl INTEGER NOT NULL,
    kolicina INTEGER NOT NULL,
    
    UNIQUE (id_narudzba_dobavljacu, id_artikl),
    
    PRIMARY KEY (id),
    FOREIGN KEY (id_narudzba_dobavljacu) REFERENCES narudzba_dobavljacu (id) ON DELETE CASCADE,
    FOREIGN KEY (id_artikl) REFERENCES artikl (id)
);

CREATE TABLE stroj (
	id INTEGER AUTO_INCREMENT,
    naziv VARCHAR(30) NOT NULL,
    tip VARCHAR(30) NOT NULL,
    datum_nabave DATE NOT NULL,
    
    PRIMARY KEY (id)
);

CREATE TABLE evidencija_odrzavanja (
	id INTEGER AUTO_INCREMENT,
    datum DATE NOT NULL,
    opis TEXT NOT NULL,
    iznos_troska NUMERIC(9,2) NOT NULL,
    id_stroj INTEGER,
    id_zaposlenik INTEGER,
    
    PRIMARY KEY (id),
    FOREIGN KEY (id_stroj) REFERENCES stroj (id) ON DELETE SET NULL,
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE SET NULL
);

CREATE TABLE rukovanje (
	id INTEGER AUTO_INCREMENT,
    id_stroj INTEGER NOT NULL,
    id_zaposlenik INTEGER NOT NULL,
    datum DATE NOT NULL,
    vrijeme_pocetka DATETIME NOT NULL,
    vrijeme_zavrsetka DATETIME NOT NULL,
    
    UNIQUE (id_stroj, id_zaposlenik, vrijeme_pocetka, vrijeme_zavrsetka),
    
    PRIMARY KEY (id),
    FOREIGN KEY (id_stroj) REFERENCES stroj (id) ON DELETE CASCADE,
    FOREIGN KEY (id_zaposlenik) REFERENCES zaposlenik (id) ON DELETE CASCADE
);

DELIMITER !%
CREATE TRIGGER provjera_statusa_narudzbi_kupca
	BEFORE DELETE ON kupac
		FOR EACH ROW
			BEGIN
				IF EXISTS (
					SELECT *
					FROM narudzba_kupca
					WHERE id_kupac = OLD.id AND status_narudzbe = 'Dostavljeno'
				) THEN
					SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = 'Nije moguće obrisati kupca: postoje neplaćene narudžbe.';
				END IF;
			END; !%

CREATE TRIGGER provjera_placanja
	BEFORE UPDATE ON narudzba_kupca
		FOR EACH ROW
			BEGIN
				IF NEW.status_narudzbe = 'Plaćeno'
					THEN SET NEW.datum_placanja = CURRENT_DATE;
				END IF;
			END; !%

CREATE TRIGGER provjera_statusa_narudzbi_dobavljaca
	BEFORE DELETE ON dobavljac
		FOR EACH ROW
			BEGIN
				IF EXISTS (
					SELECT *
					FROM narudzba_dobavljacu
					WHERE id_dobavljac = OLD.id AND status_narudzbe != 'Dostavljeno'
				) THEN
					SIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = 'Nije moguće obrisati dobavljača: postoje narudžbe koje još nisu dostavljene.';
				END IF;
			END; !%
DELIMITER ;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/zaposlenik.csv'
	INTO TABLE zaposlenik
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/evidencija_pristupa.csv'
	INTO TABLE evidencija_pristupa
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/kupac.csv'
	INTO TABLE kupac
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/prijevoznik.csv'
	INTO TABLE prijevoznik
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/dobavljac.csv'
	INTO TABLE dobavljac
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/kategorija.csv'
	INTO TABLE kategorija
	FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/artikl.csv'
	INTO TABLE artikl
	FIELDS TERMINATED BY ','
    OPTIONALLY ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/narudzba_kupca.csv'
	INTO TABLE narudzba_kupca
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES
    (id,datum_narudzbe,broj_narudzbe,status_narudzbe,@datum_placanja,id_kupac,id_prijevoznik)
    SET datum_placanja = NULLIF(@datum_placanja, '');

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/stavka_narudzbe_kupca.csv'
	INTO TABLE stavka_narudzbe_kupca
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/otpis.csv'
	INTO TABLE otpis
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/narudzba_dobavljacu.csv'
	INTO TABLE narudzba_dobavljacu
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/stavka_narudzbe_dobavljacu.csv'
	INTO TABLE stavka_narudzbe_dobavljacu
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/stroj.csv'
	INTO TABLE stroj
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/evidencija_odrzavanja.csv'
	INTO TABLE evidencija_odrzavanja
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data/rukovanje.csv'
	INTO TABLE rukovanje
	FIELDS TERMINATED BY ','
	LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES;

