/* =====================================================================
   KÜTÜPHANE UYGULAMASI - KULLANICI TANIMLI FONKSİYONLAR (CREATE FUNCTION)
     Bölüm 1: Fonksiyon nedir? Türleri
     Bölüm 2: Skaler fonksiyonlar (tek değer döndürür)
     Bölüm 3: Tablodan veri okuyan skaler fonksiyonlar
     Bölüm 4: Skaler fonksiyonları sorgularda kullanmak
     Bölüm 5: Satır içi tablo döndüren fonksiyonlar (Inline TVF)
     Bölüm 6: Çok ifadeli tablo döndüren fonksiyon (Multi-statement TVF)
     Bölüm 7: CROSS APPLY / OUTER APPLY (bonus)
     Bölüm 8: Fonksiyonu değiştirme, inceleme, silme / Sık yapılan hatalar
     Bölüm 9: Öğrenci alıştırmaları

   Ön koşul: Kutuphane_Veri_Ekleme.sql çalıştırılmış olmalı.
   Not     : DROP FUNCTION IF EXISTS komutu SQL Server 2016 ve sonrasında çalışır.
             Tarihe bağlı sonuçlar (kitap yaşı, gecikme) çalıştırdığınız güne göre değişir.
   ===================================================================== */
USE KutuphaneDB;
GO


/* =====================================================================
   BÖLÜM 1: FONKSİYON NEDİR?
   SQL Server'ın hazır fonksiyonları vardır: UPPER, LEN, ROUND, GETDATE...
   CREATE FUNCTION ile KENDİ fonksiyonlarımızı yazabiliriz.

   ÜÇ TÜRÜ VARDIR:
   1) Skaler fonksiyon          : TEK bir değer döndürür (sayı, metin, tarih)
                                  SELECT dbo.fn_AdSoyad(Ad, Soyad) FROM Uyeler
   2) Satır içi tablo fonksiyonu : TABLO döndürür, tek SELECT'ten oluşur
                                  SELECT * FROM dbo.fn_KategoriKitaplari(N'Roman')
   3) Çok ifadeli tablo fonksiyonu: TABLO döndürür, içinde birden çok komut olur

   KURALLAR:
   - Skaler fonksiyon çağrılırken şema adı (dbo.) YAZILMALIDIR.
   - Fonksiyonlar tablolardaki veriyi DEĞİŞTİREMEZ (INSERT/UPDATE/DELETE yok).
   - CREATE FUNCTION, batch'in ilk komutu olmalıdır (öncesinde GO).
   - Adlandırmada genelde "fn_" öneki kullanılır.

   FONKSİYON - VIEW - PROSEDÜR FARKI:
   View      : Parametre ALMAZ, tablo döndürür.
   Fonksiyon : Parametre ALIR, değer veya tablo döndürür; SELECT içinde kullanılır.
   Prosedür  : Parametre alır, veri DEĞİŞTİREBİLİR; EXEC ile çalıştırılır.
   ===================================================================== */


/* =====================================================================
   BÖLÜM 2: SKALER FONKSİYONLAR

   YAPI:
   CREATE FUNCTION dbo.FonksiyonAdi (@Parametre VeriTipi, ...)
   RETURNS DonusTipi
   AS
   BEGIN
       ... komutlar ...
       RETURN deger;
   END
   ===================================================================== */

-- 2.1  fn_AdSoyad : Ad ve soyadı birleştirir
--      SENARYO: Her raporda Ad + ' ' + Soyad yazmaktan kurtulalım.
DROP FUNCTION IF EXISTS dbo.fn_AdSoyad;
GO
CREATE FUNCTION dbo.fn_AdSoyad (@Ad NVARCHAR(50), @Soyad NVARCHAR(50))
RETURNS NVARCHAR(101)
AS
BEGIN
    RETURN RTRIM(@Ad + N' ' + @Soyad);
END;
GO

-- Deneme: sabit değerle
SELECT dbo.fn_AdSoyad(N'Ayşe', N'Yılmaz') AS Sonuc;      -- Ayşe Yılmaz

-- Tabloyla: aynı fonksiyon hem üyelerde hem yazarlarda çalışır
SELECT dbo.fn_AdSoyad(Ad, Soyad) AS Uye   FROM Uyeler;
SELECT dbo.fn_AdSoyad(Ad, Soyad) AS Yazar FROM Yazarlar;
-- Platon'un soyadı boş olduğu için RTRIM sondaki boşluğu siler: "Platon"


-- 2.2  fn_KitapYasi : Yayın yılından kitabın yaşını hesaplar
--      SENARYO: "50 yaşından büyük klasikler" rafı oluşturulacak.
DROP FUNCTION IF EXISTS dbo.fn_KitapYasi;
GO
CREATE FUNCTION dbo.fn_KitapYasi (@YayinYili SMALLINT)
RETURNS INT
AS
BEGIN
    RETURN YEAR(GETDATE()) - @YayinYili;
END;
GO

SELECT KitapAdi, YayinYili, dbo.fn_KitapYasi(YayinYili) AS KitapYasi
FROM Kitaplar
ORDER BY KitapYasi DESC;
-- 2026 yılında: Suç ve Ceza 160, Kürk Mantolu Madonna 83, Kırmızı Saçlı Kadın 10
-- Devlet'in yılı NULL olduğu için yaşı da NULL olur.


-- 2.3  fn_OkumaGunu : Günlük okuma hızına göre kitabın kaç günde biteceği
--      SENARYO: Üyelere "bu kitap sizin hızınızla kaç gün sürer?" bilgisi.
--      İki parametre alır; CEILING ile yukarı yuvarlar.
DROP FUNCTION IF EXISTS dbo.fn_OkumaGunu;
GO
CREATE FUNCTION dbo.fn_OkumaGunu (@SayfaSayisi INT, @GunlukSayfa INT)
RETURNS INT
AS
BEGIN
    RETURN CEILING(@SayfaSayisi * 1.0 / @GunlukSayfa);
END;
GO

SELECT KitapAdi,
       SayfaSayisi,
       dbo.fn_OkumaGunu(SayfaSayisi, 30) AS Gunde30Sayfa,
       dbo.fn_OkumaGunu(SayfaSayisi, 50) AS Gunde50Sayfa
FROM Kitaplar
ORDER BY SayfaSayisi DESC;
-- Örnek: Suç ve Ceza 687 -> 23 gün / 14 gün;  Küçük Prens 112 -> 4 gün / 3 gün


-- 2.4  fn_TelefonGizle : Telefonun yalnızca son 4 hanesini gösterir
--      SENARYO: Görevli ekranında telefon numaraları açık görünmesin.
DROP FUNCTION IF EXISTS dbo.fn_TelefonGizle;
GO
CREATE FUNCTION dbo.fn_TelefonGizle (@Telefon VARCHAR(15))
RETURNS VARCHAR(15)
AS
BEGIN
    RETURN '*******' + RIGHT(@Telefon, 4);
END;
GO

SELECT dbo.fn_AdSoyad(Ad, Soyad) AS Uye,
       dbo.fn_TelefonGizle(Telefon) AS Telefon
FROM Uyeler;
-- Örnek: Ayşe Yılmaz | *******2233   (telefonu olmayanlarda NULL)


-- 2.5  fn_KalinlikGrubu : Sayfa sayısına göre "İnce / Orta / Kalın"
--      SENARYO: Kitaplar raf etiketinde kalınlık grubuyla gösterilecek.
--      Fonksiyon içinde IF ... ELSE ve DECLARE (değişken) kullanımı.
DROP FUNCTION IF EXISTS dbo.fn_KalinlikGrubu;
GO
CREATE FUNCTION dbo.fn_KalinlikGrubu (@SayfaSayisi INT)
RETURNS NVARCHAR(10)
AS
BEGIN
    DECLARE @Grup NVARCHAR(10);

    IF @SayfaSayisi < 200
        SET @Grup = N'İnce';
    ELSE IF @SayfaSayisi < 400
        SET @Grup = N'Orta';
    ELSE
        SET @Grup = N'Kalın';

    RETURN @Grup;
END;
GO

SELECT KitapAdi, SayfaSayisi, dbo.fn_KalinlikGrubu(SayfaSayisi) AS Grup
FROM Kitaplar
ORDER BY SayfaSayisi;
-- Beklenen: İnce 4 kitap, Orta 8 kitap, Kalın 6 kitap


-- 2.6  fn_GecikmeGunu : Bir ödüncün kaç gün geciktiği
--      SENARYO: İade edilmişse iade tarihine, edilmemişse bugüne göre hesapla.
--      Gecikme yoksa (erken iade) 0 döndür.
DROP FUNCTION IF EXISTS dbo.fn_GecikmeGunu;
GO
CREATE FUNCTION dbo.fn_GecikmeGunu (@SonTeslimTarihi DATE, @IadeTarihi DATE)
RETURNS INT
AS
BEGIN
    DECLARE @BitisTarihi DATE;
    DECLARE @Gun INT;

    SET @BitisTarihi = ISNULL(@IadeTarihi, CAST(GETDATE() AS DATE));
    SET @Gun = DATEDIFF(DAY, @SonTeslimTarihi, @BitisTarihi);

    IF @Gun < 0
        SET @Gun = 0;

    RETURN @Gun;
END;
GO

-- Deneme: sabit tarihlerle
SELECT dbo.fn_GecikmeGunu('2026-09-26', '2026-09-30') AS GecIade,      -- 4
       dbo.fn_GecikmeGunu('2026-09-24', '2026-09-22') AS ErkenIade;    -- 0 (eksi değil)


-- 2.7  fn_GecikmeCezasi : Gecikme cezası (günlük 2,50 TL - örnek tutar)
--      SENARYO: Fonksiyon içinden BAŞKA bir fonksiyon çağırmak.
DROP FUNCTION IF EXISTS dbo.fn_GecikmeCezasi;
GO
CREATE FUNCTION dbo.fn_GecikmeCezasi (@SonTeslimTarihi DATE, @IadeTarihi DATE)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN dbo.fn_GecikmeGunu(@SonTeslimTarihi, @IadeTarihi) * 2.50;
END;
GO

SELECT OduncID,
       SonTeslimTarihi,
       IadeTarihi,
       dbo.fn_GecikmeGunu(SonTeslimTarihi, IadeTarihi)   AS GecikmeGun,
       dbo.fn_GecikmeCezasi(SonTeslimTarihi, IadeTarihi) AS CezaTL
FROM Oduncler;
-- İade edilmiş ödünçlerden yalnızca OduncID 3 gecikmiştir: 4 gün, 10.00 TL.
-- İade edilmemişlerin cezası bugüne göre hesaplanır.
GO


/* =====================================================================
   BÖLÜM 3: TABLODAN VERİ OKUYAN SKALER FONKSİYONLAR
   Fonksiyon içinde SELECT ile tablodan değer okunup döndürülebilir.
   ===================================================================== */

-- 3.1  fn_KategoriKitapSayisi : Bir kategoride kaç kitap var?
DROP FUNCTION IF EXISTS dbo.fn_KategoriKitapSayisi;
GO
CREATE FUNCTION dbo.fn_KategoriKitapSayisi (@KategoriID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Sayi INT;

    SELECT @Sayi = COUNT(*)
    FROM Kitaplar
    WHERE KategoriID = @KategoriID;

    RETURN @Sayi;
END;
GO

SELECT dbo.fn_KategoriKitapSayisi(1) AS RomanSayisi;     -- 8

SELECT KategoriAdi, dbo.fn_KategoriKitapSayisi(KategoriID) AS KitapSayisi
FROM Kategoriler
ORDER BY KitapSayisi DESC;
-- Beklenen: Roman 8, Bilim 3, Bilim Kurgu 2, ... Psikoloji 0, Biyografi 0


-- 3.2  fn_UyeOduncSayisi : Bir üyenin toplam ödünç sayısı
DROP FUNCTION IF EXISTS dbo.fn_UyeOduncSayisi;
GO
CREATE FUNCTION dbo.fn_UyeOduncSayisi (@UyeID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Sayi INT;

    SELECT @Sayi = COUNT(*)
    FROM Oduncler
    WHERE UyeID = @UyeID;

    RETURN @Sayi;
END;
GO

SELECT dbo.fn_AdSoyad(Ad, Soyad) AS Uye,
       dbo.fn_UyeOduncSayisi(UyeID) AS OduncSayisi
FROM Uyeler
ORDER BY OduncSayisi DESC;
-- Beklenen: 12 üye; Burak ve Ece 0


-- 3.3  fn_MusaitAdet : Bir kitabın rafta kaç adedi var?
--      SENARYO: Görevli "bu kitap verilebilir mi?" diye bakacak.
--      Rafta = Stok - şu anda ödünçte olan (iade edilmemiş) adet
DROP FUNCTION IF EXISTS dbo.fn_MusaitAdet;
GO
CREATE FUNCTION dbo.fn_MusaitAdet (@KitapID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Stok INT;
    DECLARE @Oduncte INT;

    SELECT @Stok = StokAdedi
    FROM Kitaplar
    WHERE KitapID = @KitapID;

    SELECT @Oduncte = COUNT(*)
    FROM Oduncler
    WHERE KitapID = @KitapID AND IadeTarihi IS NULL;

    RETURN @Stok - @Oduncte;
END;
GO

SELECT dbo.fn_MusaitAdet(1) AS KurkMantoluRafta;         -- 1  (stok 3, ödünçte 2)

SELECT KitapAdi, StokAdedi, dbo.fn_MusaitAdet(KitapID) AS RaftakiAdet
FROM Kitaplar
ORDER BY RaftakiAdet DESC;
-- Örnek: Küçük Prens 4 -> 3, Suç ve Ceza 3 -> 3, 1984 3 -> 1


-- 3.4  fn_EnCokOkunanKitap : Kütüphanenin en çok ödünç alınan kitabının adı
--      SENARYO: Ana ekranda "Ayın kitabı" gösterilecek. Parametresiz fonksiyon.
DROP FUNCTION IF EXISTS dbo.fn_EnCokOkunanKitap;
GO
CREATE FUNCTION dbo.fn_EnCokOkunanKitap ()
RETURNS NVARCHAR(150)
AS
BEGIN
    DECLARE @KitapAdi NVARCHAR(150);

    SELECT TOP 1 @KitapAdi = k.KitapAdi
    FROM Oduncler AS o
    INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
    GROUP BY k.KitapAdi
    ORDER BY COUNT(*) DESC;

    RETURN @KitapAdi;
END;
GO

SELECT dbo.fn_EnCokOkunanKitap() AS AyinKitabi;          -- Kürk Mantolu Madonna
-- Not: Parametre olmasa da parantezler () yazılmalıdır.
GO


/* =====================================================================
   BÖLÜM 4: SKALER FONKSİYONLARI SORGULARDA KULLANMAK
   Fonksiyonlar SELECT, WHERE, ORDER BY ve GROUP BY içinde kullanılabilir.
   ===================================================================== */

-- 4.1  WHERE içinde: 75 yaşından büyük kitaplar (klasikler rafı)
SELECT KitapAdi, YayinYili, dbo.fn_KitapYasi(YayinYili) AS Yas
FROM Kitaplar
WHERE dbo.fn_KitapYasi(YayinYili) > 75;
-- 2026 yılında: 1951'den önceki 8 kitap

-- 4.2  WHERE içinde: Rafta en az 2 adedi bulunan kitaplar
SELECT KitapAdi, dbo.fn_MusaitAdet(KitapID) AS Rafta
FROM Kitaplar
WHERE dbo.fn_MusaitAdet(KitapID) >= 2;
-- Beklenen: İnce Memed 2, Osmanlı'yı Yeniden Keşfetmek 2, Küçük Prens 3, Suç ve Ceza 3

-- 4.3  GROUP BY içinde: Kalınlık gruplarına göre kitap sayısı
SELECT dbo.fn_KalinlikGrubu(SayfaSayisi) AS Grup, COUNT(*) AS KitapSayisi
FROM Kitaplar
GROUP BY dbo.fn_KalinlikGrubu(SayfaSayisi);
-- Beklenen: İnce 4, Orta 8, Kalın 6

-- 4.4  JOIN ile birlikte: Ödünç raporu (fonksiyonlarla sadeleşmiş)
SELECT dbo.fn_AdSoyad(u.Ad, u.Soyad)                       AS Uye,
       k.KitapAdi,
       o.SonTeslimTarihi,
       dbo.fn_GecikmeGunu(o.SonTeslimTarihi, o.IadeTarihi)   AS GecikmeGun,
       dbo.fn_GecikmeCezasi(o.SonTeslimTarihi, o.IadeTarihi) AS CezaTL
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.IadeTarihi IS NULL
ORDER BY CezaTL DESC;
-- Henüz iade edilmemiş 11 ödünç ve bugüne kadar biriken cezaları

-- 4.5  Gecikmeli iade edilmiş kitaplar
SELECT dbo.fn_AdSoyad(u.Ad, u.Soyad) AS Uye,
       k.KitapAdi,
       dbo.fn_GecikmeGunu(o.SonTeslimTarihi, o.IadeTarihi)   AS GecikmeGun,
       dbo.fn_GecikmeCezasi(o.SonTeslimTarihi, o.IadeTarihi) AS CezaTL
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.IadeTarihi IS NOT NULL
  AND dbo.fn_GecikmeGunu(o.SonTeslimTarihi, o.IadeTarihi) > 0;
-- Beklenen: Mehmet Demir | İnce Memed | 4 | 10.00

-- 4.6  Toplama fonksiyonuyla: Üye başına toplam ceza
SELECT dbo.fn_AdSoyad(u.Ad, u.Soyad) AS Uye,
       SUM(dbo.fn_GecikmeCezasi(o.SonTeslimTarihi, o.IadeTarihi)) AS ToplamCezaTL
FROM Oduncler AS o
INNER JOIN Uyeler AS u ON o.UyeID = u.UyeID
GROUP BY u.Ad, u.Soyad
ORDER BY ToplamCezaTL DESC;

-- 4.7  Fonksiyon sonucuyla hesap: Bir okuma kulübü günde 25 sayfa okursa
--      Roman kategorisindeki tüm kitapları kaç günde bitirir?
SELECT SUM(dbo.fn_OkumaGunu(SayfaSayisi, 25)) AS ToplamGun
FROM Kitaplar
WHERE KategoriID = 1;
-- Beklenen: 122 gün (7 + 18 + 9 + 19 + 28 + 7 + 16 + 18)
GO


/* =====================================================================
   BÖLÜM 5: SATIR İÇİ TABLO DÖNDÜREN FONKSİYONLAR (INLINE TVF)
   Parametreli VIEW gibi düşünebilirsiniz.

   YAPI:
   CREATE FUNCTION dbo.FonksiyonAdi (@Parametre VeriTipi)
   RETURNS TABLE
   AS
   RETURN
   (
       SELECT ...
   );

   Kullanımı: SELECT * FROM dbo.FonksiyonAdi(deger)
   ===================================================================== */

-- 5.1  fn_KategoriKitaplari : Kategori adı verilen kitapları listeler
--      SENARYO: Görevli ekranında kategori seçince kitaplar listelenecek.
DROP FUNCTION IF EXISTS dbo.fn_KategoriKitaplari;
GO
CREATE FUNCTION dbo.fn_KategoriKitaplari (@KategoriAdi NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT k.KitapID, k.KitapAdi, k.YayinYili, k.SayfaSayisi, k.StokAdedi
    FROM Kitaplar AS k
    INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
    WHERE kt.KategoriAdi = @KategoriAdi
);
GO

SELECT * FROM dbo.fn_KategoriKitaplari(N'Roman');         -- 8 satır
SELECT * FROM dbo.fn_KategoriKitaplari(N'Bilim Kurgu');   -- 1984, Ben, Robot
SELECT * FROM dbo.fn_KategoriKitaplari(N'Psikoloji');     -- boş

-- Tablo gibi WHERE ve ORDER BY yazılabilir:
SELECT KitapAdi, SayfaSayisi
FROM dbo.fn_KategoriKitaplari(N'Roman')
WHERE SayfaSayisi > 400
ORDER BY SayfaSayisi DESC;
-- Beklenen: Suç ve Ceza 687, Benim Adım Kırmızı 472, İnce Memed 436, Huzur 432


-- 5.2  fn_UyeOduncGecmisi : Bir üyenin tüm ödünç geçmişi
--      SENARYO: Üye kartı ekranında geçmiş ödünçler gösterilecek.
DROP FUNCTION IF EXISTS dbo.fn_UyeOduncGecmisi;
GO
CREATE FUNCTION dbo.fn_UyeOduncGecmisi (@UyeID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT k.KitapAdi, o.OduncTarihi, o.SonTeslimTarihi, o.IadeTarihi
    FROM Oduncler AS o
    INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
    WHERE o.UyeID = @UyeID
);
GO

SELECT * FROM dbo.fn_UyeOduncGecmisi(1);    -- Ayşe: Kürk Mantolu Madonna, Küçük Prens
SELECT * FROM dbo.fn_UyeOduncGecmisi(6);    -- Burak: boş (hiç ödünç almamış)

-- Yalnızca henüz iade edilmemiş olanlar:
SELECT * FROM dbo.fn_UyeOduncGecmisi(4)
WHERE IadeTarihi IS NULL;
-- Beklenen: Can - Benim Adım Kırmızı, Kozmos


-- 5.3  fn_YazarKitaplari : Soyadı verilen yazarın kitapları
DROP FUNCTION IF EXISTS dbo.fn_YazarKitaplari;
GO
CREATE FUNCTION dbo.fn_YazarKitaplari (@Soyad NVARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT k.KitapAdi, k.YayinYili, kt.KategoriAdi
    FROM Yazarlar AS y
    INNER JOIN KitapYazar  AS ky ON y.YazarID    = ky.YazarID
    INNER JOIN Kitaplar    AS k  ON ky.KitapID   = k.KitapID
    INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
    WHERE y.Soyad = @Soyad
);
GO

SELECT * FROM dbo.fn_YazarKitaplari(N'Pamuk');      -- 2 kitap
SELECT * FROM dbo.fn_YazarKitaplari(N'Orwell');     -- 1984, Hayvan Çiftliği
SELECT * FROM dbo.fn_YazarKitaplari(N'Hawking');    -- 2 kitap


-- 5.4  fn_TarihAraligiOdunclar : İki tarih arasındaki ödünçler
--      SENARYO: Aylık rapor - "Eylül'de neler okundu?"
DROP FUNCTION IF EXISTS dbo.fn_TarihAraligiOdunclar;
GO
CREATE FUNCTION dbo.fn_TarihAraligiOdunclar (@Baslangic DATE, @Bitis DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT dbo.fn_AdSoyad(u.Ad, u.Soyad) AS Uye,
           k.KitapAdi,
           o.OduncTarihi
    FROM Oduncler AS o
    INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
    INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
    WHERE o.OduncTarihi BETWEEN @Baslangic AND @Bitis
);
GO

SELECT * FROM dbo.fn_TarihAraligiOdunclar('2026-09-01', '2026-09-30')
ORDER BY OduncTarihi;                                     -- Eylül: 11 satır

SELECT * FROM dbo.fn_TarihAraligiOdunclar('2026-10-01', '2026-10-31')
ORDER BY OduncTarihi;                                     -- Ekim: 5 satır

-- Tablo fonksiyonu üzerinde GROUP BY: Eylül'de kim kaç kitap aldı?
SELECT Uye, COUNT(*) AS KitapSayisi
FROM dbo.fn_TarihAraligiOdunclar('2026-09-01', '2026-09-30')
GROUP BY Uye
ORDER BY KitapSayisi DESC;


-- 5.5  fn_SayfaAraligi : Belirli sayfa aralığındaki kitaplar
--      SENARYO: "Hafta sonu bitirebileceğim, 200-300 sayfalık bir kitap öner."
DROP FUNCTION IF EXISTS dbo.fn_SayfaAraligi;
GO
CREATE FUNCTION dbo.fn_SayfaAraligi (@EnAz INT, @EnCok INT)
RETURNS TABLE
AS
RETURN
(
    SELECT KitapAdi, SayfaSayisi
    FROM Kitaplar
    WHERE SayfaSayisi BETWEEN @EnAz AND @EnCok
);
GO

SELECT * FROM dbo.fn_SayfaAraligi(200, 300) ORDER BY SayfaSayisi;
-- Beklenen: Kırmızı Saçlı Kadın 204, Zamanın Kısa Tarihi 256,
--           Doğu Ekspresinde Cinayet 256, Ben, Robot 272,
--           Osmanlı'yı Yeniden Keşfetmek 296

-- Tablo fonksiyonunu başka bir tabloyla JOIN etmek:
-- 200-300 sayfalık kitapların yazarları
SELECT s.KitapAdi, s.SayfaSayisi, dbo.fn_AdSoyad(y.Ad, y.Soyad) AS Yazar
FROM dbo.fn_SayfaAraligi(200, 300) AS s
INNER JOIN Kitaplar   AS k  ON s.KitapAdi = k.KitapAdi
INNER JOIN KitapYazar AS ky ON k.KitapID  = ky.KitapID
INNER JOIN Yazarlar   AS y  ON ky.YazarID = y.YazarID;
GO


/* =====================================================================
   BÖLÜM 6: ÇOK İFADELİ TABLO DÖNDÜREN FONKSİYON (MULTI-STATEMENT TVF)
   Döndürülecek tablo önce TANIMLANIR, sonra içine adım adım satır eklenir.
   IF gibi komutlar kullanılabilir.

   YAPI:
   CREATE FUNCTION dbo.FonksiyonAdi (@Parametre VeriTipi)
   RETURNS @Sonuc TABLE (Sutun1 VeriTipi, Sutun2 VeriTipi)
   AS
   BEGIN
       INSERT INTO @Sonuc ...
       RETURN;
   END
   ===================================================================== */

-- 6.1  fn_UyeKarnesi : Bir üyenin bilgilerini satır satır özetler
--      SENARYO: Üye kartı ekranında "Bilgi - Değer" şeklinde özet tablo.
--      Not: @Sonuc tablosuna INSERT yapmak serbesttir; yasak olan
--           GERÇEK tablolardaki veriyi değiştirmektir.
DROP FUNCTION IF EXISTS dbo.fn_UyeKarnesi;
GO
CREATE FUNCTION dbo.fn_UyeKarnesi (@UyeID INT)
RETURNS @Sonuc TABLE (Bilgi NVARCHAR(30), Deger NVARCHAR(150))
AS
BEGIN
    -- Üye yoksa tek satırlık bilgi döndür
    IF NOT EXISTS (SELECT 1 FROM Uyeler WHERE UyeID = @UyeID)
    BEGIN
        INSERT INTO @Sonuc VALUES (N'Hata', N'Üye bulunamadı');
        RETURN;
    END

    INSERT INTO @Sonuc
    SELECT N'Ad Soyad', dbo.fn_AdSoyad(Ad, Soyad)
    FROM Uyeler WHERE UyeID = @UyeID;

    INSERT INTO @Sonuc
    SELECT N'Kayıt Tarihi', CONVERT(NVARCHAR(10), KayitTarihi, 104)
    FROM Uyeler WHERE UyeID = @UyeID;

    INSERT INTO @Sonuc
    SELECT N'Toplam Ödünç', CAST(COUNT(*) AS NVARCHAR(10))
    FROM Oduncler WHERE UyeID = @UyeID;

    INSERT INTO @Sonuc
    SELECT N'Elindeki Kitap', CAST(COUNT(*) AS NVARCHAR(10))
    FROM Oduncler WHERE UyeID = @UyeID AND IadeTarihi IS NULL;

    INSERT INTO @Sonuc
    SELECT N'Elindeki Kitaplar', k.KitapAdi
    FROM Oduncler AS o
    INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
    WHERE o.UyeID = @UyeID AND o.IadeTarihi IS NULL;

    RETURN;
END;
GO

SELECT * FROM dbo.fn_UyeKarnesi(4);
-- Beklenen:
--   Ad Soyad          | Can Öztürk
--   Kayıt Tarihi      | 15.09.2026   (104 = gg.aa.yyyy biçimi)
--   Toplam Ödünç      | 2
--   Elindeki Kitap    | 2
--   Elindeki Kitaplar | Benim Adım Kırmızı
--   Elindeki Kitaplar | Kozmos

SELECT * FROM dbo.fn_UyeKarnesi(6);     -- Burak: toplam 0, elindeki 0
SELECT * FROM dbo.fn_UyeKarnesi(99);    -- Hata | Üye bulunamadı
GO


/* =====================================================================
   BÖLÜM 7: CROSS APPLY / OUTER APPLY (BONUS)
   Tablo fonksiyonuna, başka bir tablonun HER SATIRINDAN parametre göndermek.
   CROSS APPLY : Fonksiyon boş dönerse satır GELMEZ  (INNER JOIN gibi)
   OUTER APPLY : Fonksiyon boş dönse de satır GELİR  (LEFT JOIN gibi)
   ===================================================================== */

-- 7.1  Her üyenin ödünç geçmişi tek listede
SELECT u.Ad, g.KitapAdi, g.OduncTarihi
FROM Uyeler AS u
CROSS APPLY dbo.fn_UyeOduncGecmisi(u.UyeID) AS g
ORDER BY u.Ad;
-- Beklenen: 16 satır (Burak ve Ece YOK)

-- 7.2  Aynısı OUTER APPLY ile
SELECT u.Ad, g.KitapAdi, g.OduncTarihi
FROM Uyeler AS u
OUTER APPLY dbo.fn_UyeOduncGecmisi(u.UyeID) AS g
ORDER BY u.Ad;
-- Beklenen: 18 satır (Burak ve Ece NULL ile gelir)

-- 7.3  Her kategorinin kitapları (kategori adı fonksiyona parametre olur)
SELECT kt.KategoriAdi, f.KitapAdi
FROM Kategoriler AS kt
OUTER APPLY dbo.fn_KategoriKitaplari(kt.KategoriAdi) AS f
ORDER BY kt.KategoriAdi;
-- Beklenen: 20 satır (Psikoloji ve Biyografi NULL ile)
GO


/* =====================================================================
   BÖLÜM 8: FONKSİYONU DEĞİŞTİRME, İNCELEME, SİLME / SIK YAPILAN HATALAR
   ===================================================================== */

-- 8.1  ALTER FUNCTION: Gecikme cezasını günlük 3 TL yapalım
ALTER FUNCTION dbo.fn_GecikmeCezasi (@SonTeslimTarihi DATE, @IadeTarihi DATE)
RETURNS DECIMAL(10,2)
AS
BEGIN
    RETURN dbo.fn_GecikmeGunu(@SonTeslimTarihi, @IadeTarihi) * 3.00;
END;
GO

SELECT dbo.fn_GecikmeCezasi('2026-09-26', '2026-09-30') AS Ceza;   -- 12.00 (4 gün x 3)

-- 8.2  Fonksiyonun kodunu görmek
EXEC sp_helptext 'dbo.fn_GecikmeCezasi';

-- 8.3  Veritabanındaki tüm kullanıcı fonksiyonlarını listelemek
--      FN = skaler, IF = satır içi tablo, TF = çok ifadeli tablo fonksiyonu
SELECT name AS FonksiyonAdi, type AS Tur, type_desc AS TurAciklama
FROM sys.objects
WHERE type IN ('FN', 'IF', 'TF')
ORDER BY type, name;

-- 8.4  HATA: Skaler fonksiyonu dbo. olmadan çağırmak (Msg 195). Deneyin:
-- SELECT fn_AdSoyad(Ad, Soyad) FROM Uyeler;

-- 8.5  HATA: Fonksiyon içinde gerçek tabloyu değiştirmek (Msg 443). Deneyin:
-- CREATE FUNCTION dbo.fn_Hatali (@KitapID INT)
-- RETURNS INT
-- AS
-- BEGIN
--     UPDATE Kitaplar SET StokAdedi = StokAdedi + 1 WHERE KitapID = @KitapID;
--     RETURN 1;
-- END;
-- GO
--      Veri değiştirmek için fonksiyon değil SAKLI YORDAM (stored procedure) kullanılır.

-- 8.6  HATA: Tablo fonksiyonunu SELECT listesinde çağırmak (Msg 4121). Deneyin:
-- SELECT dbo.fn_KategoriKitaplari(N'Roman');
--      Tablo fonksiyonları FROM içinde kullanılır.

-- 8.7  HATA: Kullanımdaki fonksiyonu silmeye çalışmak
--      fn_GecikmeCezasi, fn_GecikmeGunu'yu kullanır; ama SQL Server bunu
--      engellemez. fn_GecikmeGunu silinirse fn_GecikmeCezasi ÇALIŞIRKEN hata verir.
--      Bu yüzden silmeden önce bağımlılıkları kontrol edin:
EXEC sp_depends 'dbo.fn_GecikmeGunu';

-- 8.8  Fonksiyon silmek (yorumu kaldırıp deneyebilirsiniz, sonra 2.4'ü tekrar çalıştırın)
-- DROP FUNCTION dbo.fn_TelefonGizle;
GO


/* =====================================================================
   BÖLÜM 9: ÖĞRENCİ ALIŞTIRMALARI
   ===================================================================== */
-- F1.  Bir metnin ilk harfini büyük, kalanını küçük yapan fn_IlkHarfBuyuk
--      skaler fonksiyonunu yazın. (İpucu: UPPER, LOWER, LEFT, RIGHT, LEN)
-- F2.  Kitabın yayın yılını alıp "XX. yüzyıl" bilgisini döndüren
--      fn_Yuzyil fonksiyonunu yazın. (1943 -> 20, 2016 -> 21)
--      (İpucu: FLOOR veya CEILING)
-- F3.  Bir yazarın kitap sayısını döndüren fn_YazarKitapSayisi(@YazarID)
--      fonksiyonunu yazın ve tüm yazarları kitap sayılarıyla listeleyin.
-- F4.  Ödünç tarihine 14 gün ekleyerek son teslim tarihini döndüren
--      fn_SonTeslimHesapla(@OduncTarihi) fonksiyonunu yazın.
-- F5.  Ülke adı verilen yazarları listeleyen fn_UlkeYazarlari(@Ulke)
--      satır içi tablo fonksiyonunu yazın.
-- F6.  Bir kitabı ödünç almış üyeleri listeleyen fn_KitabiOkuyanlar(@KitapID)
--      tablo fonksiyonunu yazın. Kürk Mantolu Madonna için 3 üye gelmeli.
-- F7.  Teslim tarihi verilen günden önce olan ve iade edilmemiş ödünçleri
--      döndüren fn_Gecikenler(@Tarih) fonksiyonunu yazın.
-- F8.  fn_KategoriKitaplari fonksiyonunu ALTER FUNCTION ile değiştirerek
--      her kitabın rafta kaç adet olduğunu (fn_MusaitAdet) da gösterin.
