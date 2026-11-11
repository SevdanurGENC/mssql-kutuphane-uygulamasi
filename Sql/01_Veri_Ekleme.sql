/* =====================================================================
   KÜTÜPHANE UYGULAMASI - GENİŞLETİLMİŞ VERİ EKLEME BETİĞİ
   Her tabloya en az 10 kayıt ekler.

   Ön koşul : 01_Kurulum.sql dosyasındaki ADIM 1 ve ADIM 2
              (veritabanı ve tabloların oluşturulması) çalıştırılmış olmalı.
   Not      : Betik önce tablolardaki mevcut verileri siler, sonra
              yeniden ekler. İstediğiniz kadar tekrar çalıştırabilirsiniz.
              Kitap bilgileri (ISBN, sayfa sayısı) ders için örnek veridir.
   ===================================================================== */
USE KutuphaneDB;
GO

/* ---------------------------------------------------------------------
   0) MEVCUT VERİLERİ TEMİZLE
   Silme sırası önemlidir: önce yabancı anahtar içeren (bağımlı)
   tablolar, sonra bağımsız tablolar silinir.
   --------------------------------------------------------------------- */
DELETE FROM Oduncler;
DELETE FROM KitapYazar;
DELETE FROM Kitaplar;
DELETE FROM Uyeler;
DELETE FROM Yazarlar;
DELETE FROM Kategoriler;
GO

/* ---------------------------------------------------------------------
   IDENTITY_INSERT hakkında:
   ID alanları IDENTITY olduğu için normalde değer girilmez.
   Kayıtların her çalıştırmada AYNI numaraları alması için
   SET IDENTITY_INSERT ... ON ile ID'leri elle veriyoruz.
   Aynı anda yalnızca bir tabloda ON olabilir; işimiz bitince OFF yapılır.
   --------------------------------------------------------------------- */

/* ---------------------------------------------------------------------
   1) KATEGORİLER (10 kayıt)
   Psikoloji ve Biyografi kategorilerinde bilerek kitap yoktur
   (LEFT JOIN alıştırmaları için).
   --------------------------------------------------------------------- */
SET IDENTITY_INSERT Kategoriler ON;
INSERT INTO Kategoriler (KategoriID, KategoriAdi) VALUES
(1,  N'Roman'),
(2,  N'Bilim'),
(3,  N'Tarih'),
(4,  N'Şiir'),
(5,  N'Çocuk'),
(6,  N'Felsefe'),
(7,  N'Psikoloji'),
(8,  N'Biyografi'),
(9,  N'Bilim Kurgu'),
(10, N'Polisiye');
SET IDENTITY_INSERT Kategoriler OFF;
GO

/* ---------------------------------------------------------------------
   2) YAZARLAR (15 kayıt)
   --------------------------------------------------------------------- */
SET IDENTITY_INSERT Yazarlar ON;
INSERT INTO Yazarlar (YazarID, Ad, Soyad, Ulke) VALUES
(1,  N'Sabahattin', N'Ali',              N'Türkiye'),
(2,  N'Yaşar',      N'Kemal',            N'Türkiye'),
(3,  N'Orhan',      N'Pamuk',            N'Türkiye'),
(4,  N'Stephen',    N'Hawking',          N'İngiltere'),
(5,  N'Leonard',    N'Mlodinow',         N'ABD'),
(6,  N'İlber',      N'Ortaylı',          N'Türkiye'),
(7,  N'Nazım',      N'Hikmet',           N'Türkiye'),
(8,  N'Antoine',    N'de Saint-Exupéry', N'Fransa'),
(9,  N'Fyodor',     N'Dostoyevski',      N'Rusya'),
(10, N'George',     N'Orwell',           N'İngiltere'),
(11, N'Agatha',     N'Christie',         N'İngiltere'),
(12, N'Isaac',      N'Asimov',           N'ABD'),
(13, N'Ahmet Hamdi',N'Tanpınar',         N'Türkiye'),
(14, N'Platon',     N'',                 N'Yunanistan'),
(15, N'Carl',       N'Sagan',            N'ABD');
SET IDENTITY_INSERT Yazarlar OFF;
GO

/* ---------------------------------------------------------------------
   3) KİTAPLAR (18 kayıt)
   Sütun sırası: KitapID, ISBN, KitapAdi, YayinYili, SayfaSayisi,
                 StokAdedi, KategoriID
   "Devlet" kitabının yayın yılı bilinmediği için NULL girilmiştir.
   --------------------------------------------------------------------- */
SET IDENTITY_INSERT Kitaplar ON;
INSERT INTO Kitaplar (KitapID, ISBN, KitapAdi, YayinYili, SayfaSayisi, StokAdedi, KategoriID) VALUES
(1,  '9780000000011', N'Kürk Mantolu Madonna',            1943, 160, 3, 1),
(2,  '9780000000028', N'İnce Memed',                      1955, 436, 2, 1),
(3,  '9780000000035', N'Kırmızı Saçlı Kadın',             2016, 204, 1, 1),
(4,  '9780000000042', N'Zamanın Kısa Tarihi',             1988, 256, 2, 2),
(5,  '9780000000059', N'Zamanın Daha Kısa Tarihi',        2005, 176, 1, 2),
(6,  '9780000000066', N'Osmanlı''yı Yeniden Keşfetmek',   2006, 296, 2, 3),
(7,  '9780000000073', N'Memleketimden İnsan Manzaraları', 1966, 480, 1, 4),
(8,  '9780000000080', N'Küçük Prens',                     1943, 112, 4, 5),
(9,  '9780000000097', N'Benim Adım Kırmızı',              1998, 472, 2, 1),
(10, '9780000000103', N'Suç ve Ceza',                     1866, 687, 3, 1),
(11, '9780000000110', N'1984',                            1949, 352, 3, 9),
(12, '9780000000127', N'Hayvan Çiftliği',                 1945, 152, 2, 1),
(13, '9780000000134', N'Doğu Ekspresinde Cinayet',        1934, 256, 2, 10),
(14, '9780000000141', N'Ben, Robot',                      1950, 272, 1, 9),
(15, '9780000000158', N'Saatleri Ayarlama Enstitüsü',     1961, 382, 2, 1),
(16, '9780000000165', N'Devlet',                          NULL, 400, 1, 6),
(17, '9780000000172', N'Kozmos',                          1980, 396, 2, 2),
(18, '9780000000189', N'Huzur',                           1949, 432, 1, 1);
SET IDENTITY_INSERT Kitaplar OFF;
GO

/* ---------------------------------------------------------------------
   4) KİTAP-YAZAR EŞLEŞTİRMESİ (19 kayıt)
   Bu tabloda IDENTITY yoktur, IDENTITY_INSERT gerekmez.
   Kitap 5'in iki yazarı var; Orhan Pamuk, Orwell ve Tanpınar'ın
   ikişer kitabı var (N:M ilişki örnekleri).
   --------------------------------------------------------------------- */
INSERT INTO KitapYazar (KitapID, YazarID) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 4), (5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 3),
(10, 9),
(11, 10),
(12, 10),
(13, 11),
(14, 12),
(15, 13),
(16, 14),
(17, 15),
(18, 13);
GO

/* ---------------------------------------------------------------------
   5) ÜYELER (12 kayıt)
   Dikkat: Eposta alanı UNIQUE olduğu için SQL Server bu sütunda
   yalnızca BİR tane NULL değere izin verir (Elif Şahin).
   Burak Çelik ve Ece Polat hiç ödünç almamıştır.
   --------------------------------------------------------------------- */
SET IDENTITY_INSERT Uyeler ON;
INSERT INTO Uyeler (UyeID, Ad, Soyad, Eposta, Telefon, KayitTarihi) VALUES
(1,  N'Ayşe',   N'Yılmaz',  N'ayse.yilmaz@okul.edu.tr',   '05321112233', '2026-09-08'),
(2,  N'Mehmet', N'Demir',   N'mehmet.demir@okul.edu.tr',  '05332223344', '2026-09-08'),
(3,  N'Zeynep', N'Kaya',    N'zeynep.kaya@okul.edu.tr',   NULL,          '2026-09-10'),
(4,  N'Can',    N'Öztürk',  N'can.ozturk@okul.edu.tr',    '05443334455', '2026-09-15'),
(5,  N'Elif',   N'Şahin',   NULL,                         '05554445566', '2026-09-20'),
(6,  N'Burak',  N'Çelik',   N'burak.celik@okul.edu.tr',   '05065556677', '2026-10-01'),
(7,  N'Selin',  N'Arslan',  N'selin.arslan@okul.edu.tr',  '05376667788', '2026-09-11'),
(8,  N'Emre',   N'Koç',     N'emre.koc@okul.edu.tr',      '05427778899', '2026-09-12'),
(9,  N'Deniz',  N'Aydın',   N'deniz.aydin@okul.edu.tr',   NULL,          '2026-09-18'),
(10, N'Merve',  N'Yıldız',  N'merve.yildiz@okul.edu.tr',  '05318889900', '2026-09-22'),
(11, N'Oğuz',   N'Kurt',    N'oguz.kurt@okul.edu.tr',     '05459990011', '2026-09-25'),
(12, N'Ece',    N'Polat',   N'ece.polat@okul.edu.tr',     '05360001122', '2026-10-05');
SET IDENTITY_INSERT Uyeler OFF;
GO

/* ---------------------------------------------------------------------
   6) ÖDÜNÇLER (16 kayıt)
   IadeTarihi NULL ise kitap henüz iade edilmemiştir.
   Hiç ödünç verilmemiş kitaplar: 3, 7, 14, 16, 18
   --------------------------------------------------------------------- */
SET IDENTITY_INSERT Oduncler ON;
INSERT INTO Oduncler (OduncID, KitapID, UyeID, OduncTarihi, SonTeslimTarihi, IadeTarihi) VALUES
(1,  1,  1,  '2026-09-10', '2026-09-24', '2026-09-22'),  -- zamanında iade
(2,  8,  1,  '2026-09-25', '2026-10-09', NULL),          -- teslim tarihi geçmiş
(3,  2,  2,  '2026-09-12', '2026-09-26', '2026-09-30'),  -- geç iade
(4,  4,  2,  '2026-09-28', '2026-10-12', NULL),          -- teslim tarihi geçmiş
(5,  1,  3,  '2026-09-15', '2026-09-29', NULL),          -- teslim tarihi geçmiş
(6,  6,  3,  '2026-09-16', '2026-09-30', '2026-09-29'),
(7,  9,  4,  '2026-09-18', '2026-10-02', NULL),          -- teslim tarihi geçmiş
(8,  5,  5,  '2026-09-21', '2026-10-05', '2026-10-03'),
(9,  1,  5,  '2026-10-01', '2026-10-15', NULL),
(10, 10, 7,  '2026-09-22', '2026-10-06', '2026-10-05'),
(11, 11, 8,  '2026-09-24', '2026-10-08', NULL),          -- teslim tarihi geçmiş
(12, 13, 9,  '2026-09-29', '2026-10-13', NULL),
(13, 11, 10, '2026-10-02', '2026-10-16', NULL),
(14, 15, 11, '2026-10-05', '2026-10-19', NULL),
(15, 12, 7,  '2026-10-07', '2026-10-21', NULL),
(16, 17, 4,  '2026-10-08', '2026-10-22', NULL);
SET IDENTITY_INSERT Oduncler OFF;
GO

/* ---------------------------------------------------------------------
   7) KONTROL: Her tabloda kaç kayıt var?
   Beklenen: Kategoriler 10, Yazarlar 15, Kitaplar 18,
             KitapYazar 19, Uyeler 12, Oduncler 16
   --------------------------------------------------------------------- */
SELECT N'Kategoriler' AS Tablo, COUNT(*) AS KayitSayisi FROM Kategoriler
UNION ALL SELECT N'Yazarlar',   COUNT(*) FROM Yazarlar
UNION ALL SELECT N'Kitaplar',   COUNT(*) FROM Kitaplar
UNION ALL SELECT N'KitapYazar', COUNT(*) FROM KitapYazar
UNION ALL SELECT N'Uyeler',     COUNT(*) FROM Uyeler
UNION ALL SELECT N'Oduncler',   COUNT(*) FROM Oduncler;
GO
