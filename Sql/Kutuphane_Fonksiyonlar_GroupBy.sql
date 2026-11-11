/* =====================================================================
   KÜTÜPHANE UYGULAMASI - HAZIR FONKSİYONLAR, GROUP BY ve HAVING
   Konular:
     Bölüm 1: Toplama fonksiyonları  (COUNT, SUM, AVG, MAX, MIN)
     Bölüm 2: Metin fonksiyonları    (UPPER, LOWER, LEFT, RIGHT, LEN,
                                      LTRIM, RTRIM, TRIM + bonus)
     Bölüm 3: Matematik fonksiyonları (ROUND, FLOOR, CEILING + bonus)
     Bölüm 4: GROUP BY
     Bölüm 5: HAVING
     Bölüm 6: Hepsi bir arada
     Bölüm 7: Öğrenci alıştırmaları

   Ön koşul: Kutuphane_Veri_Ekleme.sql çalıştırılmış olmalı.
   Her sorgunun altında, o veriyle BEKLENEN sonuç yazılıdır.
   ===================================================================== */
USE KutuphaneDB;
GO


/* =====================================================================
   BÖLÜM 1: TOPLAMA (AGGREGATE) FONKSİYONLARI
   Çok satırı alıp TEK bir değer döndürürler.
   COUNT : sayar          SUM : toplar        AVG : ortalama alır
   MAX   : en büyük       MIN : en küçük
   NULL değerler COUNT(*) dışındaki tüm fonksiyonlarda YOK SAYILIR.
   ===================================================================== */

-- 1.1  COUNT(*) : Kütüphanede kaç farklı kitap var?
SELECT COUNT(*) AS KitapSayisi
FROM Kitaplar;
-- Beklenen: 18

-- 1.2  COUNT(*) ile COUNT(sütun) farkı
SELECT COUNT(*)          AS TumKitaplar,         -- 18 (tüm satırlar)
       COUNT(YayinYili)  AS YiliBilinenler       -- 17 (Devlet'in yılı NULL)
FROM Kitaplar;

-- 1.3  COUNT(DISTINCT ...) : Tekrarları saymadan say
SELECT COUNT(*)                AS ToplamOdunc,        -- 16
       COUNT(DISTINCT UyeID)   AS FarkliUye,          -- 10
       COUNT(DISTINCT KitapID) AS FarkliKitap         -- 13
FROM Oduncler;

-- 1.4  COUNT + WHERE : Henüz iade edilmemiş kaç ödünç var?
SELECT COUNT(*) AS IadeEdilmemis
FROM Oduncler
WHERE IadeTarihi IS NULL;
-- Beklenen: 11

-- 1.5  SUM : Kütüphanedeki toplam kitap adedi (stok) ve toplam sayfa
SELECT SUM(StokAdedi)   AS ToplamStok,
       SUM(SayfaSayisi) AS ToplamSayfa
FROM Kitaplar;
-- Beklenen: 35 adet, 5921 sayfa

-- 1.6  SUM + WHERE : Roman kategorisindeki toplam stok
SELECT SUM(StokAdedi) AS RomanStok
FROM Kitaplar
WHERE KategoriID = 1;
-- Beklenen: 16

-- 1.7  AVG : Ortalama sayfa sayısı
SELECT AVG(SayfaSayisi) AS OrtalamaSayfa
FROM Kitaplar;
-- Beklenen: 328   <-- DİKKAT: INT sütunun ortalaması da INT olur, küsurat atılır!

-- 1.8  AVG küsuratlı: sütunu 1.0 ile çarparak ondalıklı sayıya çevirin
SELECT AVG(SayfaSayisi * 1.0)             AS OrtalamaSayfa,      -- 328.944444
       AVG(CAST(SayfaSayisi AS DECIMAL(10,2))) AS OrtalamaSayfa2 -- aynı sonuç
FROM Kitaplar;

-- 1.9  MAX ve MIN : En kalın / en ince kitap ve en eski / en yeni yayın yılı
SELECT MAX(SayfaSayisi) AS EnKalin,     -- 687
       MIN(SayfaSayisi) AS EnInce,      -- 112
       MAX(YayinYili)   AS EnYeni,      -- 2016
       MIN(YayinYili)   AS EnEski       -- 1866
FROM Kitaplar;

-- 1.10 MAX / MIN tarihlerde ve metinlerde de çalışır
SELECT MIN(OduncTarihi) AS IlkOdunc,     -- 2026-09-10
       MAX(OduncTarihi) AS SonOdunc      -- 2026-10-08
FROM Oduncler;

SELECT MIN(KitapAdi)    AS AlfabetikIlk, -- 1984 (rakamlar harflerden önce gelir)
       MAX(KitapAdi)    AS AlfabetikSon  -- Zamanın Kısa Tarihi
FROM Kitaplar;

-- 1.11 En kalın kitabın ADINI bulmak (alt sorgu ile)
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi = (SELECT MAX(SayfaSayisi) FROM Kitaplar);
-- Beklenen: Suç ve Ceza, 687

-- 1.12 Ortalamanın üstündeki kitaplar
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi > (SELECT AVG(SayfaSayisi) FROM Kitaplar)
ORDER BY SayfaSayisi DESC;
-- Beklenen: 328'den uzun 9 kitap (Suç ve Ceza ... 1984)

-- 1.13 İade edilmiş ödünçlerin ortalama süresi (gün)
SELECT AVG(DATEDIFF(DAY, OduncTarihi, IadeTarihi) * 1.0) AS OrtalamaGun
FROM Oduncler
WHERE IadeTarihi IS NOT NULL;
-- Beklenen: 13.6 gün  (12, 18, 13, 12, 13 günlerin ortalaması)
GO


/* =====================================================================
   BÖLÜM 2: METİN (STRING) FONKSİYONLARI
   UPPER(m)        : tümü BÜYÜK harf
   LOWER(m)        : tümü küçük harf
   LEFT(m, n)      : soldan n karakter
   RIGHT(m, n)     : sağdan n karakter
   LEN(m)          : karakter sayısı (sondaki boşlukları SAYMAZ)
   LTRIM(m)        : soldaki boşlukları siler
   RTRIM(m)        : sağdaki boşlukları siler
   TRIM(m)         : iki taraftaki boşlukları siler (SQL Server 2017+)
   ===================================================================== */

-- 2.1  UPPER ve LOWER
SELECT Ad, UPPER(Soyad) AS SoyadBuyuk, LOWER(Ad) AS AdKucuk
FROM Uyeler;
-- Örnek: Ayşe | YILMAZ | ayşe

-- 2.2  TÜRKÇE KARAKTER SORUNU: i / İ ve ı / I
--      Varsayılan harmanlamada (collation) UPPER('i') = 'I' olur, 'İ' değil!
--      Türkçe kurallarla çevirmek için COLLATE Turkish_CI_AS eklenir.
SELECT N'istanbul ılık'                                   AS Orijinal,
       UPPER(N'istanbul ılık')                            AS Varsayilan,
       UPPER(N'istanbul ılık' COLLATE Turkish_CI_AS)      AS Turkce;
-- Turkce sütunu: İSTANBUL ILIK

SELECT KitapAdi, UPPER(KitapAdi COLLATE Turkish_CI_AS) AS BuyukHarf
FROM Kitaplar;

-- 2.3  UPPER ile büyük/küçük harf duyarsız karşılaştırma
SELECT Ad, Soyad FROM Uyeler
WHERE UPPER(Ad) = N'CAN';
-- Beklenen: Can Öztürk

-- 2.4  LEFT : Adın baş harfi + soyad  (A. Yılmaz)
SELECT LEFT(Ad, 1) + N'. ' + Soyad AS KisaAd
FROM Uyeler;

-- 2.5  LEFT : Baş harflerden kısaltma (Ayşe Yılmaz -> AY)
SELECT Ad, Soyad, LEFT(Ad, 1) + LEFT(Soyad, 1) AS BasHarfler
FROM Uyeler;

-- 2.6  LEFT : Kitap adının ilk 10 karakteri + "..."
SELECT KitapAdi, LEFT(KitapAdi, 10) + N'...' AS KisaBaslik
FROM Kitaplar;
-- Örnek: Kürk Mantolu Madonna -> Kürk Manto...

-- 2.7  RIGHT : Telefonu gizleyip son 4 hanesini gösterme
SELECT Ad, Soyad, N'*******' + RIGHT(Telefon, 4) AS GizliTelefon
FROM Uyeler
WHERE Telefon IS NOT NULL;
-- Örnek: Ayşe Yılmaz -> *******2233

-- 2.8  RIGHT : ISBN'in son 3 hanesi
SELECT KitapAdi, ISBN, RIGHT(ISBN, 3) AS Son3Hane
FROM Kitaplar;

-- 2.9  LEFT : Telefonun operatör kodu (ilk 4 hane)
SELECT Ad, Soyad, LEFT(Telefon, 4) AS OperatorKodu
FROM Uyeler
WHERE Telefon IS NOT NULL;

-- 2.10 LEN : Kitap adlarının uzunluğu, en uzundan en kısaya
SELECT KitapAdi, LEN(KitapAdi) AS Uzunluk
FROM Kitaplar
ORDER BY Uzunluk DESC;
-- Beklenen: İlk sırada Memleketimden İnsan Manzaraları (31),
--           son sırada 1984 (4)

-- 2.11 LEN + WHERE : Adı 20 karakterden uzun kitaplar
SELECT KitapAdi, LEN(KitapAdi) AS Uzunluk
FROM Kitaplar
WHERE LEN(KitapAdi) > 20;

-- 2.12 LEN + MAX : En uzun kitap adının uzunluğu
SELECT MAX(LEN(KitapAdi)) AS EnUzunAd,   -- 31
       MIN(LEN(KitapAdi)) AS EnKisaAd    -- 4
FROM Kitaplar;

-- 2.13 LTRIM, RTRIM, TRIM : Boşluk temizleme
--      Köşeli parantezler boşlukları görmek için eklendi.
SELECT N'[' + N'   Küçük Prens   ' + N']'          AS Orijinal,  -- [   Küçük Prens   ]
       N'[' + LTRIM(N'   Küçük Prens   ') + N']'   AS SolTemiz,  -- [Küçük Prens   ]
       N'[' + RTRIM(N'   Küçük Prens   ') + N']'   AS SagTemiz,  -- [   Küçük Prens]
       N'[' + LTRIM(RTRIM(N'   Küçük Prens   ')) + N']' AS IkisiDe, -- [Küçük Prens]
       N'[' + TRIM(N'   Küçük Prens   ') + N']'    AS TrimIle;   -- [Küçük Prens]

-- 2.14 LEN sondaki boşlukları SAYMAZ, baştakileri sayar
SELECT LEN(N'Huzur')       AS Normal,    -- 5
       LEN(N'Huzur   ')    AS SondaBosluk, -- 5  (!)
       LEN(N'   Huzur')    AS BastaBosluk, -- 8
       DATALENGTH(N'Huzur   ') AS Bayt;    -- 16 (NVARCHAR'da her karakter 2 bayt)

-- 2.15 Gerçek hayat örneği: Kullanıcı boşluklu veri girdiyse
--      (Tablo değişkeni ile geçici tablo - kalıcı tabloyu bozmaz)
DECLARE @GeciciUye TABLE (Ad NVARCHAR(50));
INSERT INTO @GeciciUye VALUES (N'  Ayşe'), (N'Mehmet  '), (N'  Can  ');

SELECT N'[' + Ad + N']'               AS Kirli,
       N'[' + LTRIM(RTRIM(Ad)) + N']' AS Temiz,
       LEN(Ad)                        AS KirliUzunluk,
       LEN(LTRIM(RTRIM(Ad)))          AS TemizUzunluk
FROM @GeciciUye;

-- 2.16 Fonksiyonları iç içe kullanmak: Ad'ı "Ayşe" biçimine getirmek
--      (ilk harf büyük, kalanı küçük)
SELECT N'aYŞE' AS Girdi,
       UPPER(LEFT(N'aYŞE', 1)) + LOWER(RIGHT(N'aYŞE', LEN(N'aYŞE') - 1)) AS Duzeltilmis;
-- Beklenen: Ayşe

-- 2.17 BONUS - CHARINDEX ve SUBSTRING: e-postadan kullanıcı adını ayırma
SELECT Eposta,
       LEFT(Eposta, CHARINDEX(N'@', Eposta) - 1)    AS KullaniciAdi,
       SUBSTRING(Eposta, CHARINDEX(N'@', Eposta) + 1, 50) AS AlanAdi
FROM Uyeler
WHERE Eposta IS NOT NULL;
-- Örnek: ayse.yilmaz@okul.edu.tr -> ayse.yilmaz | okul.edu.tr

-- 2.18 BONUS - REPLACE ve CONCAT
SELECT REPLACE(Telefon, '05', '+90 5')            AS UluslararasiTel,
       CONCAT(Ad, N' ', Soyad, N' (', UyeID, N')') AS Etiket
FROM Uyeler
WHERE Telefon IS NOT NULL;
-- CONCAT, NULL değerleri boş metin sayar; + operatörü ise NULL döndürür.
GO


/* =====================================================================
   BÖLÜM 3: MATEMATİK FONKSİYONLARI
   ROUND(x, n)  : n basamağa YUVARLAR (5 ve üstü yukarı)
   FLOOR(x)     : AŞAĞI yuvarlar (x'ten küçük/eşit en büyük tam sayı)
   CEILING(x)   : YUKARI yuvarlar (x'ten büyük/eşit en küçük tam sayı)
   ===================================================================== */

-- 3.1  Üçünün farkı tek bakışta
SELECT 328.944    AS Sayi,
       ROUND(328.944, 0) AS Round0,    -- 329.000
       ROUND(328.944, 1) AS Round1,    -- 328.900
       ROUND(328.944, 2) AS Round2,    -- 328.940
       FLOOR(328.944)    AS Floor_,    -- 328
       CEILING(328.944)  AS Ceiling_;  -- 329

-- 3.2  Negatif sayılarda dikkat!
SELECT FLOOR(-2.3)   AS Floor_,     -- -3  (daha küçük tam sayıya)
       CEILING(-2.3) AS Ceiling_,   -- -2
       ROUND(-2.5, 0) AS Round_;    -- -3.0

-- 3.3  Ortalama sayfa sayısını üç şekilde yuvarlama
SELECT AVG(SayfaSayisi * 1.0)            AS HamOrtalama,   -- 328.944444
       ROUND(AVG(SayfaSayisi * 1.0), 2)  AS Yuvarla2,      -- 328.940000
       FLOOR(AVG(SayfaSayisi * 1.0))     AS AsagiYuvarla,  -- 328
       CEILING(AVG(SayfaSayisi * 1.0))   AS YukariYuvarla  -- 329
FROM Kitaplar;

-- 3.4  ROUND sonucundaki gereksiz sıfırlardan kurtulmak: CAST
SELECT CAST(AVG(SayfaSayisi * 1.0) AS DECIMAL(10,2)) AS Ortalama   -- 328.94
FROM Kitaplar;

-- 3.5  CEILING gerçek hayat örneği: Günde 30 sayfa okuyan biri
--      her kitabı kaç günde bitirir? (yarım gün olmaz, yukarı yuvarlanır)
SELECT KitapAdi, SayfaSayisi,
       SayfaSayisi / 30.0            AS TamHesap,
       CEILING(SayfaSayisi / 30.0)   AS OkumaGunu
FROM Kitaplar
ORDER BY OkumaGunu DESC;
-- Örnek: Suç ve Ceza 687 / 30 = 22.9 -> 23 gün;  Küçük Prens 112 / 30 = 3.73 -> 4 gün

-- 3.6  FLOOR gerçek hayat örneği: Kitap kaç TAM hafta okunur?
SELECT KitapAdi,
       CEILING(SayfaSayisi / 30.0)          AS OkumaGunu,
       FLOOR(CEILING(SayfaSayisi / 30.0) / 7) AS TamHafta
FROM Kitaplar;

-- 3.7  FLOOR ile kitabın yaşı ve on yıl (dönem)
SELECT KitapAdi, YayinYili,
       YEAR(GETDATE()) - YayinYili          AS KitapYasi,
       FLOOR(YayinYili / 10.0) * 10         AS Donem
FROM Kitaplar
WHERE YayinYili IS NOT NULL
ORDER BY YayinYili;
-- Örnek: 1943 -> 1940,  1998 -> 1990,  2016 -> 2010

-- 3.8  Negatif basamakla ROUND: onlara / yüzlere yuvarlama
SELECT KitapAdi, SayfaSayisi,
       ROUND(SayfaSayisi, -1) AS OnlaraYuvarla,    -- 687 -> 690
       ROUND(SayfaSayisi, -2) AS YuzlereYuvarla    -- 687 -> 700, 152 -> 200
FROM Kitaplar;

-- 3.9  Yüzde hesaplama ve yuvarlama: Her kitap toplam stoğun yüzde kaçı?
SELECT KitapAdi, StokAdedi,
       ROUND(StokAdedi * 100.0 / (SELECT SUM(StokAdedi) FROM Kitaplar), 1) AS StokYuzdesi
FROM Kitaplar
ORDER BY StokYuzdesi DESC;
-- Örnek: Küçük Prens 4 / 35 = %11.4

-- 3.10 BONUS - ABS, POWER, SQRT, % (mod)
SELECT ABS(-15)       AS Mutlak,      -- 15
       POWER(2, 10)   AS Us,          -- 1024
       SQRT(144)      AS Karekok,     -- 12
       17 % 5         AS Kalan;       -- 2

-- Mod örneği: ID'si çift olan kitaplar
SELECT KitapID, KitapAdi FROM Kitaplar
WHERE KitapID % 2 = 0;
GO


/* =====================================================================
   BÖLÜM 4: GROUP BY
   Satırları ortak bir değere göre GRUPLAR; toplama fonksiyonu her grup
   için ayrı hesaplanır.
   KURAL: SELECT'te toplama fonksiyonu İÇİNDE OLMAYAN her sütun
          GROUP BY'da da yazılmalıdır.
   ===================================================================== */

-- 4.1  Her kategoride kaç kitap var? (ID ile)
SELECT KategoriID, COUNT(*) AS KitapSayisi
FROM Kitaplar
GROUP BY KategoriID;

-- 4.2  Aynı sorgu kategori ADIYLA (WHERE ile birleştirme)
SELECT kt.KategoriAdi, COUNT(*) AS KitapSayisi
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
ORDER BY KitapSayisi DESC;
-- Beklenen: Roman 8, Bilim 3, Bilim Kurgu 2, diğerleri 1

-- 4.3  Kategori başına birden çok istatistik
SELECT kt.KategoriAdi,
       COUNT(*)                                  AS KitapSayisi,
       SUM(k.StokAdedi)                          AS ToplamStok,
       SUM(k.SayfaSayisi)                        AS ToplamSayfa,
       CAST(AVG(k.SayfaSayisi * 1.0) AS DECIMAL(10,1)) AS OrtSayfa,
       MAX(k.SayfaSayisi)                        AS EnKalin,
       MIN(k.SayfaSayisi)                        AS EnInce
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
ORDER BY KitapSayisi DESC;
-- Roman satırı: 8 | 16 | 2925 | 365.6 | 687 | 152

-- 4.4  Her ülkeden kaç yazar var?
SELECT Ulke, COUNT(*) AS YazarSayisi
FROM Yazarlar
GROUP BY Ulke
ORDER BY YazarSayisi DESC;
-- Beklenen: Türkiye 6, İngiltere 3, ABD 3, Fransa 1, Rusya 1, Yunanistan 1

-- 4.5  Her yazarın kaç kitabı var?
SELECT y.Ad + N' ' + y.Soyad AS Yazar, COUNT(*) AS KitapSayisi
FROM Yazarlar AS y, KitapYazar AS ky
WHERE y.YazarID = ky.YazarID
GROUP BY y.Ad, y.Soyad
ORDER BY KitapSayisi DESC, Yazar;

-- 4.6  Her üye kaç kitap ödünç almış?
SELECT u.Ad, u.Soyad, COUNT(*) AS OduncSayisi
FROM Uyeler AS u, Oduncler AS o
WHERE u.UyeID = o.UyeID
GROUP BY u.Ad, u.Soyad
ORDER BY OduncSayisi DESC;

-- 4.7  Her kitap kaç kez ödünç alınmış?
SELECT k.KitapAdi, COUNT(*) AS OduncSayisi
FROM Kitaplar AS k, Oduncler AS o
WHERE k.KitapID = o.KitapID
GROUP BY k.KitapAdi
ORDER BY OduncSayisi DESC;
-- İlk sıra: Kürk Mantolu Madonna 3, ikinci: 1984 2

-- 4.8  Tarih fonksiyonuyla gruplama: Aylara göre ödünç sayısı
SELECT MONTH(OduncTarihi) AS Ay, COUNT(*) AS OduncSayisi
FROM Oduncler
GROUP BY MONTH(OduncTarihi)
ORDER BY Ay;
-- Beklenen: 9 (Eylül) -> 11,  10 (Ekim) -> 5

-- 4.9  Ay ADIYLA gruplama (DATENAME)
SELECT DATENAME(MONTH, KayitTarihi) AS KayitAyi, COUNT(*) AS UyeSayisi
FROM Uyeler
GROUP BY DATENAME(MONTH, KayitTarihi);
-- Beklenen: September 10, October 2
-- (Türkçe ay adı için önce: SET LANGUAGE Turkish;  -> Eylül, Ekim)

-- 4.10 İade durumuna göre gruplama (CASE ile)
SELECT CASE WHEN IadeTarihi IS NULL THEN N'Ödünçte'
            ELSE N'İade edildi' END AS Durum,
       COUNT(*) AS Adet
FROM Oduncler
GROUP BY CASE WHEN IadeTarihi IS NULL THEN N'Ödünçte'
              ELSE N'İade edildi' END;
-- Beklenen: Ödünçte 11, İade edildi 5

-- 4.11 METİN fonksiyonuyla gruplama: Adın baş harfine göre üye sayısı
SELECT LEFT(Ad, 1) AS BasHarf, COUNT(*) AS UyeSayisi
FROM Uyeler
GROUP BY LEFT(Ad, 1)
ORDER BY BasHarf;
-- Beklenen: E 3 (Elif, Emre, Ece), M 2 (Mehmet, Merve), diğerleri 1

-- 4.12 MATEMATİK fonksiyonuyla gruplama: Kitapları on yıllara (döneme) göre say
SELECT FLOOR(YayinYili / 10.0) * 10 AS Donem, COUNT(*) AS KitapSayisi
FROM Kitaplar
WHERE YayinYili IS NOT NULL
GROUP BY FLOOR(YayinYili / 10.0) * 10
ORDER BY Donem;
-- Beklenen: 1860:1, 1930:1, 1940:5, 1950:2, 1960:2, 1980:2, 1990:1, 2000:2, 2010:1

-- 4.13 Sayfa sayısı aralığına göre gruplama (CASE + GROUP BY)
SELECT CASE WHEN SayfaSayisi < 200 THEN N'1) İnce (<200)'
            WHEN SayfaSayisi < 400 THEN N'2) Orta (200-399)'
            ELSE N'3) Kalın (400+)' END AS KalinlikGrubu,
       COUNT(*) AS KitapSayisi
FROM Kitaplar
GROUP BY CASE WHEN SayfaSayisi < 200 THEN N'1) İnce (<200)'
              WHEN SayfaSayisi < 400 THEN N'2) Orta (200-399)'
              ELSE N'3) Kalın (400+)' END
ORDER BY KalinlikGrubu;
-- Beklenen: İnce 4, Orta 8, Kalın 6

-- 4.14 SIK YAPILAN HATA: GROUP BY'da olmayan sütunu SELECT'e yazmak
--      Aşağıdaki sorgu HATA verir (Msg 8120). Yorumu kaldırıp deneyin:
-- SELECT KategoriID, KitapAdi, COUNT(*)
-- FROM Kitaplar
-- GROUP BY KategoriID;
--      Çünkü bir kategoride birden çok kitap adı var; SQL hangisini
--      göstereceğini bilemez.
GO


/* =====================================================================
   BÖLÜM 5: HAVING
   GROUP BY ile oluşan GRUPLARI süzer.
   WHERE  : gruplamadan ÖNCE satırları süzer (toplama fonksiyonu KULLANILAMAZ)
   HAVING : gruplamadan SONRA grupları süzer (toplama fonksiyonu kullanılır)

   Çalışma sırası:  FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY
   ===================================================================== */

-- 5.1  HAVING + COUNT : 1'den fazla kitabı olan kategoriler
SELECT kt.KategoriAdi, COUNT(*) AS KitapSayisi
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
HAVING COUNT(*) > 1;
-- Beklenen: Roman 8, Bilim 3, Bilim Kurgu 2

-- 5.2  HAVING + COUNT : Birden çok kitabı olan yazarlar
SELECT y.Ad + N' ' + y.Soyad AS Yazar, COUNT(*) AS KitapSayisi
FROM Yazarlar AS y, KitapYazar AS ky
WHERE y.YazarID = ky.YazarID
GROUP BY y.Ad, y.Soyad
HAVING COUNT(*) >= 2;
-- Beklenen: Stephen Hawking, Orhan Pamuk, George Orwell, Ahmet Hamdi Tanpınar (2'şer)

-- 5.3  HAVING + COUNT : Birden fazla yazarın geldiği ülkeler
SELECT Ulke, COUNT(*) AS YazarSayisi
FROM Yazarlar
GROUP BY Ulke
HAVING COUNT(*) > 1;
-- Beklenen: Türkiye 6, İngiltere 3, ABD 3

-- 5.4  HAVING + SUM : Toplam stoğu 5 ve üzeri olan kategoriler
SELECT kt.KategoriAdi, SUM(k.StokAdedi) AS ToplamStok
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
HAVING SUM(k.StokAdedi) >= 5;
-- Beklenen: Roman 16, Bilim 5

-- 5.5  HAVING + AVG : Ortalama sayfa sayısı 300'ün üstünde olan kategoriler
SELECT kt.KategoriAdi,
       CAST(AVG(k.SayfaSayisi * 1.0) AS DECIMAL(10,1)) AS OrtSayfa
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
HAVING AVG(k.SayfaSayisi * 1.0) > 300
ORDER BY OrtSayfa DESC;
-- Beklenen: Şiir 480.0, Felsefe 400.0, Roman 365.6, Bilim Kurgu 312.0

-- 5.6  HAVING + MAX : En kalın kitabı 400 sayfayı geçen kategoriler
SELECT kt.KategoriAdi, MAX(k.SayfaSayisi) AS EnKalin
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
HAVING MAX(k.SayfaSayisi) > 400;
-- Beklenen: Roman 687, Şiir 480

-- 5.7  HAVING + MIN : En ince kitabı bile 250 sayfadan kalın olan kategoriler
SELECT kt.KategoriAdi, MIN(k.SayfaSayisi) AS EnInce
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
HAVING MIN(k.SayfaSayisi) > 250;
-- Beklenen: Tarih 296, Şiir 480, Felsefe 400, Bilim Kurgu 272, Polisiye 256

-- 5.8  HAVING : 1'den fazla ödünç almış üyeler
SELECT u.Ad, u.Soyad, COUNT(*) AS OduncSayisi
FROM Uyeler AS u, Oduncler AS o
WHERE u.UyeID = o.UyeID
GROUP BY u.Ad, u.Soyad
HAVING COUNT(*) > 1;
-- Beklenen: Ayşe, Mehmet, Zeynep, Can, Elif, Selin (2'şer)

-- 5.9  WHERE ve HAVING BİRLİKTE:
--      1940'tan SONRA yayımlanan kitaplar arasında, 2+ kitabı olan kategoriler
SELECT kt.KategoriAdi, COUNT(*) AS KitapSayisi
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
  AND k.YayinYili > 1940              -- satır filtresi (WHERE)
GROUP BY kt.KategoriAdi
HAVING COUNT(*) >= 2                  -- grup filtresi (HAVING)
ORDER BY KitapSayisi DESC;
-- Beklenen: Roman 7 (Suç ve Ceza elendi), Bilim 3, Bilim Kurgu 2

-- 5.10 HAVING'de birden çok koşul (AND / OR)
SELECT kt.KategoriAdi, COUNT(*) AS KitapSayisi, SUM(k.StokAdedi) AS Stok
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
HAVING COUNT(*) = 1 AND SUM(k.StokAdedi) >= 2;
-- Beklenen: Tarih (1 kitap, 2 stok), Çocuk (1, 4), Polisiye (1, 2)

-- 5.11 HAVING + metin fonksiyonu: Baş harfi en az 2 üyede ortak olan harfler
SELECT LEFT(Ad, 1) AS BasHarf, COUNT(*) AS UyeSayisi
FROM Uyeler
GROUP BY LEFT(Ad, 1)
HAVING COUNT(*) >= 2;
-- Beklenen: E 3, M 2

-- 5.12 HAVING + matematik fonksiyonu: 2'den fazla kitap içeren dönemler
SELECT FLOOR(YayinYili / 10.0) * 10 AS Donem, COUNT(*) AS KitapSayisi
FROM Kitaplar
WHERE YayinYili IS NOT NULL
GROUP BY FLOOR(YayinYili / 10.0) * 10
HAVING COUNT(*) > 2;
-- Beklenen: 1940 -> 5 kitap

-- 5.13 WHERE ile HAVING farkı - YANLIŞ kullanım:
--      Toplama fonksiyonu WHERE'de kullanılamaz (Msg 147). Deneyin:
-- SELECT KategoriID, COUNT(*) FROM Kitaplar
-- WHERE COUNT(*) > 1
-- GROUP BY KategoriID;
GO


/* =====================================================================
   BÖLÜM 6: HEPSİ BİR ARADA
   ===================================================================== */

-- 6.1  Kategori raporu: büyük harfli ad, kitap sayısı, yuvarlanmış ortalama,
--      toplam okuma günü; yalnızca 2+ kitaplı kategoriler
SELECT UPPER(kt.KategoriAdi COLLATE Turkish_CI_AS)        AS Kategori,
       COUNT(*)                                          AS Kitap,
       ROUND(AVG(k.SayfaSayisi * 1.0), 0)                AS OrtSayfa,
       SUM(CEILING(k.SayfaSayisi / 30.0))                AS ToplamOkumaGunu
FROM Kitaplar AS k, Kategoriler AS kt
WHERE k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
HAVING COUNT(*) >= 2
ORDER BY Kitap DESC;

-- 6.2  Üye karnesi: "A. YILMAZ" biçiminde ad, ödünç sayısı, iade oranı (%)
SELECT LEFT(u.Ad, 1) + N'. ' + UPPER(u.Soyad COLLATE Turkish_CI_AS) AS Uye,
       COUNT(*)                                    AS Odunc,
       COUNT(o.IadeTarihi)                         AS Iade,
       ROUND(COUNT(o.IadeTarihi) * 100.0 / COUNT(*), 0) AS IadeYuzdesi
FROM Uyeler AS u, Oduncler AS o
WHERE u.UyeID = o.UyeID
GROUP BY u.Ad, u.Soyad
ORDER BY IadeYuzdesi DESC, Odunc DESC;
-- Not: COUNT(o.IadeTarihi) NULL'ları saymadığı için doğrudan iade sayısını verir.

-- 6.3  Ülke bazında yazar özeti: ülke adının ilk 3 harfi (kod),
--      yazar sayısı, yazarların kitap sayısı toplamı
SELECT UPPER(LEFT(y.Ulke, 3) COLLATE Turkish_CI_AS) AS UlkeKodu,
       COUNT(DISTINCT y.YazarID)  AS YazarSayisi,
       COUNT(*)                   AS KitapSayisi
FROM Yazarlar AS y, KitapYazar AS ky
WHERE y.YazarID = ky.YazarID
GROUP BY UPPER(LEFT(y.Ulke, 3) COLLATE Turkish_CI_AS)
ORDER BY KitapSayisi DESC;
-- Beklenen: TÜR 6 yazar 8 kitap, İNG 3 yazar 5 kitap, ABD 3 yazar 3 kitap ...

-- 6.4  Gecikme raporu: teslim tarihi geçmiş ödünçler üye bazında
SELECT u.Ad + N' ' + u.Soyad                    AS Uye,
       COUNT(*)                                  AS GecikenKitap,
       SUM(DATEDIFF(DAY, o.SonTeslimTarihi, GETDATE())) AS ToplamGecikmeGun,
       MAX(DATEDIFF(DAY, o.SonTeslimTarihi, GETDATE())) AS EnUzunGecikme
FROM Oduncler AS o, Uyeler AS u
WHERE o.UyeID = u.UyeID
  AND o.IadeTarihi IS NULL
  AND o.SonTeslimTarihi < CAST(GETDATE() AS DATE)
GROUP BY u.Ad, u.Soyad
ORDER BY ToplamGecikmeGun DESC;
-- Sonuç, sorguyu çalıştırdığınız güne göre değişir.
GO


/* =====================================================================
   BÖLÜM 7: ÖĞRENCİ ALIŞTIRMALARI (cevapları kendiniz yazın)
   ===================================================================== */
-- F1.  Kütüphanedeki kitapların ortalama yayın yılını tam sayıya YUVARLAYARAK bulun.
-- F2.  Tüm yazarların soyadlarını BÜYÜK harfle, adlarını küçük harfle listeleyin
--      (Türkçe karakterlere dikkat).
-- F3.  Her kitabın adının ilk 3 ve son 3 harfini yan yana gösterin.
-- F4.  Adı 5 karakterden KISA olan kitapları LEN ile bulun.
-- F5.  Her kitap için "günde 25 sayfa" okuma hızıyla kaç gün süreceğini
--      CEILING ile, kaç tam hafta süreceğini FLOOR ile hesaplayın.
-- F6.  Her kategorideki en eski ve en yeni kitabın yayın yılını gösterin.
-- F7.  Toplam sayfa sayısı 500'ü geçen kategorileri listeleyin.
-- F8.  Soyadı 5 harften uzun olan üyeleri, soyadının ilk harfine göre gruplayıp sayın.
-- F9.  Her üyenin ödünç aldığı kitapların ORTALAMA sayfa sayısını,
--      bir ondalık basamağa yuvarlayarak bulun; ortalaması 300'ün üstünde olanları gösterin.
-- F10. Telefon numarasının operatör koduna (ilk 4 hane) göre üye sayısını bulun;
--      yalnızca 1'den fazla üyesi olan kodları gösterin.
