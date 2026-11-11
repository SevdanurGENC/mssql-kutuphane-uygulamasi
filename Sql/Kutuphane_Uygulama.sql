/* =====================================================================
   MSSQL VERİTABANI GİRİŞ DERSİ - UYGULAMA
   Konu    : Kütüphane Veritabanı (KutuphaneDB)
   Kapsam  : CREATE DATABASE, CREATE TABLE, kısıtlar (PK, FK, UNIQUE,
             CHECK, DEFAULT), INSERT, SELECT, WHERE, ORDER BY, JOIN,
             GROUP BY, HAVING, UPDATE, DELETE
   Çalıştırma: SSMS'te dosyayı açıp bölüm bölüm seçerek F5 ile çalıştırın.
   Not     : Kitap bilgileri (ISBN, sayfa sayısı) ders için örnek veridir.
   ===================================================================== */


/* ---------------------------------------------------------------------
   ADIM 1: VERİTABANINI OLUŞTURMA
   Aynı isimde veritabanı varsa önce silinir (uygulamayı tekrar
   çalıştırabilmek için).
   --------------------------------------------------------------------- */
USE master;
GO

IF DB_ID(N'KutuphaneDB') IS NOT NULL
BEGIN
    ALTER DATABASE KutuphaneDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE KutuphaneDB;
END
GO

CREATE DATABASE KutuphaneDB;
GO

USE KutuphaneDB;
GO


/* ---------------------------------------------------------------------
   ADIM 2: TABLOLARI OLUŞTURMA
   Sıra önemlidir: önce başka tabloya bağlı OLMAYAN tablolar
   (Kategoriler, Yazarlar, Uyeler), sonra yabancı anahtar içeren
   tablolar (Kitaplar, KitapYazar, Oduncler) oluşturulur.
   --------------------------------------------------------------------- */

-- 2.1 Kategoriler
CREATE TABLE Kategoriler (
    KategoriID   INT IDENTITY(1,1) PRIMARY KEY,
    KategoriAdi  NVARCHAR(50) NOT NULL UNIQUE
);
GO

-- 2.2 Yazarlar
CREATE TABLE Yazarlar (
    YazarID  INT IDENTITY(1,1) PRIMARY KEY,
    Ad       NVARCHAR(50) NOT NULL,
    Soyad    NVARCHAR(50) NOT NULL,
    Ulke     NVARCHAR(50) NULL
);
GO

-- 2.3 Uyeler
CREATE TABLE Uyeler (
    UyeID        INT IDENTITY(1,1) PRIMARY KEY,
    Ad           NVARCHAR(50)  NOT NULL,
    Soyad        NVARCHAR(50)  NOT NULL,
    Eposta       NVARCHAR(100) NULL UNIQUE,
    Telefon      VARCHAR(15)   NULL,
    KayitTarihi  DATE NOT NULL DEFAULT GETDATE()
);
GO

-- 2.4 Kitaplar  (Kategoriler ile 1:N ilişki)
CREATE TABLE Kitaplar (
    KitapID      INT IDENTITY(1,1) PRIMARY KEY,
    ISBN         CHAR(13)      NOT NULL UNIQUE,
    KitapAdi     NVARCHAR(150) NOT NULL,
    YayinYili    SMALLINT      NULL,
    SayfaSayisi  INT           NULL CHECK (SayfaSayisi > 0),
    StokAdedi    INT           NOT NULL DEFAULT 1 CHECK (StokAdedi >= 0),
    KategoriID   INT           NOT NULL,
    CONSTRAINT FK_Kitaplar_Kategoriler
        FOREIGN KEY (KategoriID) REFERENCES Kategoriler(KategoriID)
);
GO

-- 2.5 KitapYazar  (Kitaplar - Yazarlar arasındaki N:M ilişkiyi çözen ara tablo)
CREATE TABLE KitapYazar (
    KitapID  INT NOT NULL,
    YazarID  INT NOT NULL,
    CONSTRAINT PK_KitapYazar PRIMARY KEY (KitapID, YazarID),   -- bileşik birincil anahtar
    CONSTRAINT FK_KitapYazar_Kitaplar FOREIGN KEY (KitapID) REFERENCES Kitaplar(KitapID),
    CONSTRAINT FK_KitapYazar_Yazarlar FOREIGN KEY (YazarID) REFERENCES Yazarlar(YazarID)
);
GO

-- 2.6 Oduncler  (Uyeler ve Kitaplar ile 1:N ilişki)
CREATE TABLE Oduncler (
    OduncID          INT IDENTITY(1,1) PRIMARY KEY,
    KitapID          INT  NOT NULL,
    UyeID            INT  NOT NULL,
    OduncTarihi      DATE NOT NULL DEFAULT GETDATE(),
    SonTeslimTarihi  DATE NOT NULL,
    IadeTarihi       DATE NULL,          -- NULL ise kitap henüz iade edilmemiştir
    CONSTRAINT FK_Oduncler_Kitaplar FOREIGN KEY (KitapID) REFERENCES Kitaplar(KitapID),
    CONSTRAINT FK_Oduncler_Uyeler   FOREIGN KEY (UyeID)   REFERENCES Uyeler(UyeID),
    CONSTRAINT CK_Oduncler_Tarih    CHECK (SonTeslimTarihi >= OduncTarihi)
);
GO


/* ---------------------------------------------------------------------
   ADIM 3: ÖRNEK VERİ EKLEME (INSERT)
   Türkçe karakterler için metinlerin başına N konur: N'Şiir'
   --------------------------------------------------------------------- */

INSERT INTO Kategoriler (KategoriAdi) VALUES
(N'Roman'), (N'Bilim'), (N'Tarih'), (N'Şiir'), (N'Çocuk');

INSERT INTO Yazarlar (Ad, Soyad, Ulke) VALUES
(N'Sabahattin', N'Ali',            N'Türkiye'),     -- 1
(N'Yaşar',      N'Kemal',          N'Türkiye'),     -- 2
(N'Orhan',      N'Pamuk',          N'Türkiye'),     -- 3
(N'Stephen',    N'Hawking',        N'İngiltere'),   -- 4
(N'Leonard',    N'Mlodinow',       N'ABD'),         -- 5
(N'İlber',      N'Ortaylı',        N'Türkiye'),     -- 6
(N'Nazım',      N'Hikmet',         N'Türkiye'),     -- 7
(N'Antoine',    N'de Saint-Exupéry', N'Fransa');    -- 8

INSERT INTO Kitaplar (ISBN, KitapAdi, YayinYili, SayfaSayisi, StokAdedi, KategoriID) VALUES
('9780000000011', N'Kürk Mantolu Madonna',             1943, 160, 3, 1),  -- 1
('9780000000028', N'İnce Memed',                       1955, 436, 2, 1),  -- 2
('9780000000035', N'Kırmızı Saçlı Kadın',              2016, 204, 1, 1),  -- 3
('9780000000042', N'Zamanın Kısa Tarihi',              1988, 256, 2, 2),  -- 4
('9780000000059', N'Zamanın Daha Kısa Tarihi',         2005, 176, 1, 2),  -- 5
('9780000000066', N'Osmanlı''yı Yeniden Keşfetmek',    2006, 296, 2, 3),  -- 6
('9780000000073', N'Memleketimden İnsan Manzaraları',  1966, 480, 1, 4),  -- 7
('9780000000080', N'Küçük Prens',                      1943, 112, 4, 5),  -- 8
('9780000000097', N'Benim Adım Kırmızı',               1998, 472, 2, 1);  -- 9
-- Not: Metin içinde tek tırnak ('), iki tek tırnak ('') yazılarak eklenir.

INSERT INTO KitapYazar (KitapID, YazarID) VALUES
(1, 1), (2, 2), (3, 3), (4, 4),
(5, 4), (5, 5),          -- 5 numaralı kitabın İKİ yazarı var (N:M örneği)
(6, 6), (7, 7), (8, 8), (9, 3);

INSERT INTO Uyeler (Ad, Soyad, Eposta, Telefon, KayitTarihi) VALUES
(N'Ayşe',   N'Yılmaz', N'ayse.yilmaz@okul.edu.tr',  '05321112233', '2026-09-08'),  -- 1
(N'Mehmet', N'Demir',  N'mehmet.demir@okul.edu.tr', '05332223344', '2026-09-08'),  -- 2
(N'Zeynep', N'Kaya',   N'zeynep.kaya@okul.edu.tr',  NULL,          '2026-09-10'),  -- 3
(N'Can',    N'Öztürk', N'can.ozturk@okul.edu.tr',   '05443334455', '2026-09-15'),  -- 4
(N'Elif',   N'Şahin',  NULL,                        '05554445566', '2026-09-20'),  -- 5
(N'Burak',  N'Çelik',  N'burak.celik@okul.edu.tr',  '05065556677', '2026-10-01');  -- 6 (henüz ödünç almadı)

INSERT INTO Oduncler (KitapID, UyeID, OduncTarihi, SonTeslimTarihi, IadeTarihi) VALUES
(1, 1, '2026-09-10', '2026-09-24', '2026-09-22'),   -- zamanında iade
(8, 1, '2026-09-25', '2026-10-09', NULL),           -- Ayşe'de
(2, 2, '2026-09-12', '2026-09-26', '2026-09-30'),   -- geç iade
(4, 2, '2026-09-28', '2026-10-12', NULL),           -- Mehmet'te
(1, 3, '2026-09-15', '2026-09-29', NULL),           -- teslim tarihi geçmiş!
(6, 3, '2026-09-16', '2026-09-30', '2026-09-29'),
(9, 4, '2026-09-18', '2026-10-02', NULL),           -- teslim tarihi geçmiş!
(5, 5, '2026-09-21', '2026-10-05', '2026-10-03'),
(1, 5, '2026-10-01', '2026-10-15', NULL);
GO

-- Eklenen verileri kontrol edelim
SELECT * FROM Kategoriler;
SELECT * FROM Yazarlar;
SELECT * FROM Kitaplar;
SELECT * FROM KitapYazar;
SELECT * FROM Uyeler;
SELECT * FROM Oduncler;
GO


/* ---------------------------------------------------------------------
   ADIM 4: TEMEL SORGULAR (SELECT, WHERE, ORDER BY)
   --------------------------------------------------------------------- */

-- 4.1 Belirli sütunları seçme ve sütuna takma ad (alias) verme
SELECT KitapAdi AS [Kitap Adı], YayinYili AS [Yayın Yılı]
FROM Kitaplar;

-- 4.2 WHERE ile filtreleme: 300 sayfadan uzun kitaplar
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi > 300;

-- 4.3 Birden fazla koşul (AND / OR) ve sıralama (ORDER BY)
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili >= 1950 AND KategoriID = 1
ORDER BY YayinYili DESC;

-- 4.4 LIKE ile metin arama: adında "Kırmızı" geçen kitaplar
SELECT KitapAdi FROM Kitaplar
WHERE KitapAdi LIKE N'%Kırmızı%';

-- 4.5 BETWEEN ve IN
SELECT KitapAdi, YayinYili FROM Kitaplar
WHERE YayinYili BETWEEN 1940 AND 1960;

SELECT Ad, Soyad, Ulke FROM Yazarlar
WHERE Ulke IN (N'İngiltere', N'ABD', N'Fransa');

-- 4.6 NULL kontrolü: e-postası olmayan üyeler (= NULL DEĞİL, IS NULL kullanılır)
SELECT Ad, Soyad FROM Uyeler
WHERE Eposta IS NULL;

-- 4.7 TOP: en kalın 3 kitap
SELECT TOP 3 KitapAdi, SayfaSayisi
FROM Kitaplar
ORDER BY SayfaSayisi DESC;
GO


/* ---------------------------------------------------------------------
   ADIM 5: TABLOLARI BİRLEŞTİRME (JOIN)
   --------------------------------------------------------------------- */

-- 5.1 INNER JOIN: Kitaplar ve kategori adları
SELECT k.KitapAdi, kt.KategoriAdi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID;

-- 5.2 Üç tablo birleştirme (N:M): Kitaplar ve yazarları
SELECT k.KitapAdi, y.Ad + N' ' + y.Soyad AS Yazar
FROM Kitaplar AS k
INNER JOIN KitapYazar AS ky ON k.KitapID = ky.KitapID
INNER JOIN Yazarlar   AS y  ON ky.YazarID = y.YazarID
ORDER BY k.KitapAdi;

-- 5.3 Şu anda ödünçte olan kitaplar ve kimde oldukları
SELECT u.Ad + N' ' + u.Soyad AS Uye, k.KitapAdi, o.OduncTarihi, o.SonTeslimTarihi
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.IadeTarihi IS NULL;

-- 5.4 LEFT JOIN: Hiç ödünç almamış üyeleri de göster
SELECT u.Ad, u.Soyad, o.OduncID
FROM Uyeler AS u
LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
ORDER BY u.UyeID;

-- 5.5 Hiç ödünç almamış üyeler (LEFT JOIN + IS NULL)
SELECT u.Ad, u.Soyad
FROM Uyeler AS u
LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
WHERE o.OduncID IS NULL;
GO


/* ---------------------------------------------------------------------
   ADIM 6: GRUPLAMA VE TOPLAMA FONKSİYONLARI
   --------------------------------------------------------------------- */

-- 6.1 Toplam kitap sayısı, toplam stok, ortalama sayfa
SELECT COUNT(*)          AS KitapSayisi,
       SUM(StokAdedi)    AS ToplamStok,
       AVG(SayfaSayisi)  AS OrtalamaSayfa,
       MAX(SayfaSayisi)  AS EnKalin,
       MIN(SayfaSayisi)  AS EnInce
FROM Kitaplar;

-- 6.2 Her kategoride kaç kitap var?
SELECT kt.KategoriAdi, COUNT(k.KitapID) AS KitapSayisi
FROM Kategoriler AS kt
LEFT JOIN Kitaplar AS k ON kt.KategoriID = k.KategoriID
GROUP BY kt.KategoriAdi
ORDER BY KitapSayisi DESC;

-- 6.3 HAVING: 1'den fazla ödünç almış üyeler
SELECT u.Ad, u.Soyad, COUNT(*) AS OduncSayisi
FROM Oduncler AS o
INNER JOIN Uyeler AS u ON o.UyeID = u.UyeID
GROUP BY u.Ad, u.Soyad
HAVING COUNT(*) > 1;

-- 6.4 Teslim tarihi geçmiş, iade edilmemiş kitaplar ve gecikme gün sayısı
SELECT u.Ad + N' ' + u.Soyad AS Uye, k.KitapAdi, o.SonTeslimTarihi,
       DATEDIFF(DAY, o.SonTeslimTarihi, GETDATE()) AS GecikmeGun
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.IadeTarihi IS NULL AND o.SonTeslimTarihi < CAST(GETDATE() AS DATE)
ORDER BY GecikmeGun DESC;
GO


/* ---------------------------------------------------------------------
   ADIM 7: VERİ GÜNCELLEME VE SİLME (UPDATE, DELETE)
   UYARI: WHERE yazılmazsa TÜM satırlar güncellenir/silinir!
   --------------------------------------------------------------------- */

-- 7.1 Zeynep, Kürk Mantolu Madonna'yı bugün iade etti
UPDATE Oduncler
SET IadeTarihi = CAST(GETDATE() AS DATE)
WHERE UyeID = 3 AND KitapID = 1 AND IadeTarihi IS NULL;

-- 7.2 Küçük Prens'in stoğu 2 adet artırıldı
UPDATE Kitaplar
SET StokAdedi = StokAdedi + 2
WHERE KitapAdi = N'Küçük Prens';

-- 7.3 Yeni üye ekleyip sonra silme
INSERT INTO Uyeler (Ad, Soyad, Eposta) VALUES (N'Deneme', N'Üye', N'deneme@okul.edu.tr');
SELECT * FROM Uyeler;

DELETE FROM Uyeler
WHERE Eposta = N'deneme@okul.edu.tr';
SELECT * FROM Uyeler;
GO


/* ---------------------------------------------------------------------
   ADIM 8: KISITLARI TEST ETME
   Aşağıdaki komutlar BİLEREK HATA verir. Tek tek çalıştırıp
   hata mesajlarını okuyun ve hangi kısıtın devreye girdiğini bulun.
   --------------------------------------------------------------------- */

-- 8.1 UNIQUE ihlali: aynı ISBN ile ikinci kitap
-- INSERT INTO Kitaplar (ISBN, KitapAdi, KategoriID) VALUES ('9780000000011', N'Kopya Kitap', 1);

-- 8.2 FOREIGN KEY ihlali: olmayan kategori (99)
-- INSERT INTO Kitaplar (ISBN, KitapAdi, KategoriID) VALUES ('9780000000103', N'Yeni Kitap', 99);

-- 8.3 CHECK ihlali: negatif stok
-- UPDATE Kitaplar SET StokAdedi = -1 WHERE KitapID = 1;

-- 8.4 FOREIGN KEY ihlali: ödünç kaydı olan üyeyi silmek
-- DELETE FROM Uyeler WHERE UyeID = 1;

-- 8.5 NOT NULL ihlali: adı olmayan yazar
-- INSERT INTO Yazarlar (Soyad) VALUES (N'İsimsiz');
