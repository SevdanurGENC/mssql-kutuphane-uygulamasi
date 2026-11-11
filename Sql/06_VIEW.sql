/* =====================================================================
   KÜTÜPHANE UYGULAMASI - VIEW (GÖRÜNÜM) ÖRNEKLERİ
     Bölüm 1: VIEW nedir?
     Bölüm 2: View oluşturma (CREATE VIEW)
     Bölüm 3: View'ları sorgulama
     Bölüm 4: View üzerinden view oluşturma
     Bölüm 5: View üzerinden veri güncelleme ve WITH CHECK OPTION
     Bölüm 6: View'ı değiştirme, inceleme, silme
     Bölüm 7: Öğrenci alıştırmaları

   Ön koşul: 01_Veri_Ekleme.sql çalıştırılmış olmalı.
   Not     : DROP VIEW IF EXISTS komutu SQL Server 2016 ve sonrasında çalışır.
   ===================================================================== */
USE KutuphaneDB;
GO


/* =====================================================================
   BÖLÜM 1: VIEW NEDİR?
   View, bir SELECT sorgusuna verilen İSİMDİR. "Sanal tablo" da denir.
   - Veriyi kendisi SAKLAMAZ; her çağrıldığında içindeki sorgu çalışır.
   - Tablo gibi sorgulanır:  SELECT * FROM vw_Adi
   - Faydaları:
       * Uzun JOIN'leri bir kez yazıp tekrar tekrar kullanmak
       * Kullanıcıya yalnızca gereken sütunları göstermek (güvenlik)
       * Sorguları sadeleştirmek

   KURALLAR:
   - CREATE VIEW, batch'in (GO ile ayrılan bölümün) İLK komutu olmalıdır.
     Bu yüzden her CREATE VIEW'dan önce GO yazılır.
   - View içinde ORDER BY kullanılamaz; sıralama view sorgulanırken yapılır.
   - Hesaplanan her sütuna (Ad + ' ' + Soyad gibi) bir takma ad verilmelidir.
   - Adlandırmada genelde "vw_" öneki kullanılır.
   ===================================================================== */


/* =====================================================================
   BÖLÜM 2: VIEW OLUŞTURMA
   ===================================================================== */

-- 2.1  vw_KitapDetay : Kitaplar ve kategori adları (iki tablo, INNER JOIN)
DROP VIEW IF EXISTS vw_KitapDetay;
GO
CREATE VIEW vw_KitapDetay
AS
SELECT k.KitapID,
       k.KitapAdi,
       kt.KategoriAdi,
       k.YayinYili,
       k.SayfaSayisi,
       k.StokAdedi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID;
GO

SELECT * FROM vw_KitapDetay;
-- Beklenen: 18 satır


-- 2.2  vw_KitapYazar : Kitaplar ve yazarları (üç tablo, N:M)
--      RTRIM: Platon'un soyadı boş olduğu için sondaki boşluğu siler.
DROP VIEW IF EXISTS vw_KitapYazar;
GO
CREATE VIEW vw_KitapYazar
AS
SELECT k.KitapAdi,
       RTRIM(y.Ad + N' ' + y.Soyad) AS YazarAdi,
       y.Ulke
FROM Kitaplar AS k
INNER JOIN KitapYazar AS ky ON k.KitapID  = ky.KitapID
INNER JOIN Yazarlar   AS y  ON ky.YazarID = y.YazarID;
GO

SELECT * FROM vw_KitapYazar;
-- Beklenen: 19 satır


-- 2.3  vw_OduncListesi : Tüm ödünç kayıtları, üye ve kitap adlarıyla
DROP VIEW IF EXISTS vw_OduncListesi;
GO
CREATE VIEW vw_OduncListesi
AS
SELECT o.OduncID,
       u.Ad + N' ' + u.Soyad AS UyeAdSoyad,
       k.KitapAdi,
       o.OduncTarihi,
       o.SonTeslimTarihi,
       o.IadeTarihi
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID;
GO

SELECT * FROM vw_OduncListesi;
-- Beklenen: 16 satır


-- 2.4  vw_OduncteKitaplar : Şu anda ödünçte olan kitaplar (WHERE'li view)
DROP VIEW IF EXISTS vw_OduncteKitaplar;
GO
CREATE VIEW vw_OduncteKitaplar
AS
SELECT u.Ad + N' ' + u.Soyad AS UyeAdSoyad,
       k.KitapAdi,
       o.OduncTarihi,
       o.SonTeslimTarihi
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.IadeTarihi IS NULL;
GO

SELECT * FROM vw_OduncteKitaplar;
-- Beklenen: 11 satır


-- 2.5  vw_GecikenOdunclar : Teslim tarihi geçmiş kitaplar ve gecikme günü
--      Sonuç, sorguyu çalıştırdığınız güne göre değişir.
DROP VIEW IF EXISTS vw_GecikenOdunclar;
GO
CREATE VIEW vw_GecikenOdunclar
AS
SELECT u.Ad + N' ' + u.Soyad AS UyeAdSoyad,
       u.Telefon,
       k.KitapAdi,
       o.SonTeslimTarihi,
       DATEDIFF(DAY, o.SonTeslimTarihi, GETDATE()) AS GecikmeGun
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.IadeTarihi IS NULL
  AND o.SonTeslimTarihi < CAST(GETDATE() AS DATE);
GO

SELECT * FROM vw_GecikenOdunclar;


-- 2.6  vw_KategoriIstatistik : Kategori başına özet (GROUP BY'lı view)
--      LEFT JOIN: kitabı olmayan kategoriler de 0 ile görünür.
--      ISNULL: boş kategoride SUM NULL döneceği için 0 yazdırır.
DROP VIEW IF EXISTS vw_KategoriIstatistik;
GO
CREATE VIEW vw_KategoriIstatistik
AS
SELECT kt.KategoriAdi,
       COUNT(k.KitapID)                                AS KitapSayisi,
       ISNULL(SUM(k.StokAdedi), 0)                     AS ToplamStok,
       CAST(AVG(k.SayfaSayisi * 1.0) AS DECIMAL(10,1)) AS OrtalamaSayfa
FROM Kategoriler AS kt
LEFT JOIN Kitaplar AS k ON kt.KategoriID = k.KategoriID
GROUP BY kt.KategoriAdi;
GO

SELECT * FROM vw_KategoriIstatistik;
-- Beklenen: 10 satır
--   Roman 8 | 16 | 365.6      Bilim 3 | 5 | 276.0
--   Bilim Kurgu 2 | 4 | 312.0  Psikoloji 0 | 0 | NULL  Biyografi 0 | 0 | NULL ...


-- 2.7  vw_UyeOduncDurumu : Her üyenin toplam ödüncü ve elindeki kitap sayısı
--      COUNT(o.IadeTarihi) NULL'ları saymaz, yani iade edilenleri sayar.
DROP VIEW IF EXISTS vw_UyeOduncDurumu;
GO
CREATE VIEW vw_UyeOduncDurumu
AS
SELECT u.UyeID,
       u.Ad,
       u.Soyad,
       COUNT(o.OduncID)                          AS ToplamOdunc,
       COUNT(o.IadeTarihi)                       AS IadeEdilen,
       COUNT(o.OduncID) - COUNT(o.IadeTarihi)    AS ElindekiKitap
FROM Uyeler AS u
LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
GROUP BY u.UyeID, u.Ad, u.Soyad;
GO

SELECT * FROM vw_UyeOduncDurumu;
-- Beklenen: 12 satır. Burak ve Ece 0 | 0 | 0; Can 2 | 0 | 2


-- 2.8  vw_UyeIletisim : GÜVENLİK örneği - telefonun yalnızca son 4 hanesi
--      Kullanıcılara tablo yerine bu view'ı açarak telefon numarasını gizleyebiliriz.
DROP VIEW IF EXISTS vw_UyeIletisim;
GO
CREATE VIEW vw_UyeIletisim
AS
SELECT Ad,
       Soyad,
       Eposta,
       N'*******' + RIGHT(Telefon, 4) AS Telefon
FROM Uyeler;
GO

SELECT * FROM vw_UyeIletisim;
-- Örnek: Ayşe Yılmaz -> *******2233  (telefonu olmayanlarda NULL)
GO


/* =====================================================================
   BÖLÜM 3: VIEW'LARI SORGULAMA
   View, tablo gibi kullanılır: WHERE, ORDER BY, GROUP BY, JOIN yazılabilir.
   ===================================================================== */

-- 3.1  WHERE + ORDER BY: 400 sayfadan uzun romanlar
SELECT KitapAdi, SayfaSayisi
FROM vw_KitapDetay
WHERE KategoriAdi = N'Roman'
  AND SayfaSayisi > 400
ORDER BY SayfaSayisi DESC;
-- Beklenen: Suç ve Ceza 687, Benim Adım Kırmızı 472, İnce Memed 436, Huzur 432

-- 3.2  Tüm sütunlar yerine seçilen sütunlar
SELECT KitapAdi, KategoriAdi
FROM vw_KitapDetay
WHERE StokAdedi >= 3;
-- Beklenen: Kürk Mantolu Madonna, Küçük Prens, Suç ve Ceza, 1984

-- 3.3  LIKE: ödünçte olan ve adı "K" ile başlayan kitaplar
SELECT UyeAdSoyad, KitapAdi
FROM vw_OduncteKitaplar
WHERE KitapAdi LIKE N'K%';
-- Beklenen: 4 satır - Küçük Prens (Ayşe), Kürk Mantolu Madonna (Zeynep, Elif),
--           Kozmos (Can)

-- 3.4  Hiç ödünç almamış üyeler (artık LEFT JOIN yazmaya gerek yok)
SELECT Ad, Soyad
FROM vw_UyeOduncDurumu
WHERE ToplamOdunc = 0;
-- Beklenen: Burak Çelik, Ece Polat

-- 3.5  Elinde 2 kitap olan üyeler
SELECT Ad, Soyad, ElindekiKitap
FROM vw_UyeOduncDurumu
WHERE ElindekiKitap >= 2;
-- Beklenen: Can Öztürk, 2

-- 3.6  View üzerinde GROUP BY: Ülkelere göre kitap sayısı
SELECT Ulke, COUNT(*) AS KitapSayisi
FROM vw_KitapYazar
GROUP BY Ulke
ORDER BY KitapSayisi DESC;
-- Beklenen: Türkiye 8, İngiltere 5, ABD 3, Fransa 1, Rusya 1, Yunanistan 1

-- 3.7  View üzerinde HAVING: 2'den fazla kitabı olan kategoriler
SELECT KategoriAdi, KitapSayisi
FROM vw_KategoriIstatistik
WHERE KitapSayisi > 2;
-- Beklenen: Roman 8, Bilim 3
-- Not: View içinde GROUP BY yapıldığı için burada HAVING yerine WHERE yeterlidir.

-- 3.8  View ile tabloyu JOIN etmek: kitap detayları + yazarlar
SELECT d.KitapAdi, d.KategoriAdi, y.Ad, y.Soyad
FROM vw_KitapDetay AS d
INNER JOIN KitapYazar AS ky ON d.KitapID  = ky.KitapID
INNER JOIN Yazarlar   AS y  ON ky.YazarID = y.YazarID
WHERE d.KategoriAdi = N'Bilim';
-- Beklenen: 4 satır (Zamanın Daha Kısa Tarihi'nin iki yazarı var)

-- 3.9  Aynı soruyu view olmadan yazsaydık:
SELECT k.KitapAdi, kt.KategoriAdi, k.SayfaSayisi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
WHERE kt.KategoriAdi = N'Roman' AND k.SayfaSayisi > 400;
-- 3.1 ile aynı sonuç; view sayesinde JOIN'i her seferinde yazmıyoruz.
GO


/* =====================================================================
   BÖLÜM 4: VIEW ÜZERİNDEN VIEW OLUŞTURMA
   Bir view, başka bir view'dan da veri alabilir.
   ===================================================================== */

-- 4.1  vw_TurkYazarKitaplari : vw_KitapYazar'dan yalnızca Türk yazarlar
DROP VIEW IF EXISTS vw_TurkYazarKitaplari;
GO
CREATE VIEW vw_TurkYazarKitaplari
AS
SELECT KitapAdi, YazarAdi
FROM vw_KitapYazar
WHERE Ulke = N'Türkiye';
GO

SELECT * FROM vw_TurkYazarKitaplari ORDER BY YazarAdi;
-- Beklenen: 8 satır


-- 4.2  vw_BuyukKategoriler : vw_KategoriIstatistik'ten kitabı olan kategoriler
DROP VIEW IF EXISTS vw_BuyukKategoriler;
GO
CREATE VIEW vw_BuyukKategoriler
AS
SELECT KategoriAdi, KitapSayisi, ToplamStok
FROM vw_KategoriIstatistik
WHERE KitapSayisi > 0;
GO

SELECT * FROM vw_BuyukKategoriler ORDER BY KitapSayisi DESC;
-- Beklenen: 8 satır (Psikoloji ve Biyografi yok)
GO


/* =====================================================================
   BÖLÜM 5: VIEW ÜZERİNDEN VERİ GÜNCELLEME ve WITH CHECK OPTION
   TEK tablodan oluşan, GROUP BY veya hesaplanan sütun içermeyen
   view'lar üzerinden INSERT / UPDATE / DELETE yapılabilir.
   Değişiklik aslında ALTTAKİ TABLOYA yapılır.

   WITH CHECK OPTION: View'ın WHERE koşuluna uymayan bir değişikliği engeller.
   ===================================================================== */

-- 5.1  vw_RomanKitaplari : Yalnızca Roman kategorisi (KategoriID = 1)
DROP VIEW IF EXISTS vw_RomanKitaplari;
GO
CREATE VIEW vw_RomanKitaplari
AS
SELECT KitapID, ISBN, KitapAdi, YayinYili, SayfaSayisi, StokAdedi, KategoriID
FROM Kitaplar
WHERE KategoriID = 1
WITH CHECK OPTION;
GO

SELECT * FROM vw_RomanKitaplari;
-- Beklenen: 8 satır

-- 5.2  View üzerinden UPDATE: Huzur'un stoğunu 1 artır
UPDATE vw_RomanKitaplari
SET StokAdedi = StokAdedi + 1
WHERE KitapAdi = N'Huzur';

-- Değişiklik TABLOYA yansıdı mı? Kontrol edelim:
SELECT KitapAdi, StokAdedi FROM Kitaplar WHERE KitapAdi = N'Huzur';
-- Beklenen: 2 (önceden 1'di)

-- Diğer örnekler etkilenmesin diye geri alalım:
UPDATE vw_RomanKitaplari
SET StokAdedi = StokAdedi - 1
WHERE KitapAdi = N'Huzur';

-- 5.3  View dışındaki kitap güncellenmez
--      Küçük Prens Çocuk kategorisinde, view'da yok. 0 satır etkilenir.
UPDATE vw_RomanKitaplari
SET StokAdedi = 10
WHERE KitapAdi = N'Küçük Prens';
-- Mesaj: (0 rows affected)

-- 5.4  WITH CHECK OPTION ihlali - aşağıdaki komut HATA verir (Msg 550).
--      Huzur'u Bilim kategorisine (2) taşımak, onu view'dan çıkarır.
--      Yorumu kaldırıp deneyin:
-- UPDATE vw_RomanKitaplari
-- SET KategoriID = 2
-- WHERE KitapAdi = N'Huzur';

-- 5.5  WITH CHECK OPTION ihlali - Roman olmayan kitap EKLENEMEZ (Msg 550):
-- INSERT INTO vw_RomanKitaplari (ISBN, KitapAdi, StokAdedi, KategoriID)
-- VALUES ('9780000000999', N'Deneme Kitap', 1, 2);

-- 5.6  Güncellenemeyen view: GROUP BY içeren view'lar değiştirilemez (Msg 4403).
-- UPDATE vw_KategoriIstatistik SET KitapSayisi = 5 WHERE KategoriAdi = N'Roman';
GO


/* =====================================================================
   BÖLÜM 6: VIEW'I DEĞİŞTİRME, İNCELEME, SİLME
   ===================================================================== */

-- 6.1  ALTER VIEW: vw_KitapDetay'a ISBN sütununu ekleyelim
--      View silinmeden yeniden tanımlanır.
ALTER VIEW vw_KitapDetay
AS
SELECT k.KitapID,
       k.ISBN,
       k.KitapAdi,
       kt.KategoriAdi,
       k.YayinYili,
       k.SayfaSayisi,
       k.StokAdedi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID;
GO

SELECT * FROM vw_KitapDetay;   -- ISBN sütunu artık görünür

-- 6.2  View'ın içindeki sorguyu görmek
EXEC sp_helptext 'vw_KitapDetay';

-- 6.3  Veritabanındaki tüm view'ları listelemek
SELECT name AS ViewAdi, create_date AS OlusturmaTarihi
FROM sys.views
ORDER BY name;

-- 6.4  View'ın sütunlarını görmek
EXEC sp_columns 'vw_UyeOduncDurumu';

-- 6.5  SIK YAPILAN HATA: View içinde ORDER BY (Msg 1033). Deneyin:
-- CREATE VIEW vw_Hatali
-- AS
-- SELECT KitapAdi FROM Kitaplar ORDER BY KitapAdi;
-- GO

-- 6.6  SIK YAPILAN HATA: Hesaplanan sütuna ad vermemek (Msg 4511). Deneyin:
-- CREATE VIEW vw_Hatali2
-- AS
-- SELECT Ad + N' ' + Soyad FROM Uyeler;
-- GO

-- 6.7  View silmek: Veriler SİLİNMEZ, yalnızca view tanımı silinir.
--      Aşağıdaki satırın yorumunu kaldırıp deneyin, sonra 2.8'i tekrar çalıştırın.
-- DROP VIEW vw_UyeIletisim;
GO


/* =====================================================================
   BÖLÜM 7: ÖĞRENCİ ALIŞTIRMALARI
   ===================================================================== */
-- V1. Yazarlar ve ülkelerini, adı-soyadı tek sütunda olacak şekilde gösteren
--     vw_YazarListesi adında bir view oluşturun.
-- V2. 2000 yılından sonra yayımlanmış kitapları kategori adıyla gösteren
--     vw_YeniKitaplar adında bir view oluşturun.
-- V3. Her yazarın kaç kitabı olduğunu gösteren vw_YazarKitapSayisi
--     view'ını oluşturun (LEFT JOIN + GROUP BY).
-- V4. vw_OduncListesi'ni kullanarak Eylül ayında yapılan ödünçleri listeleyin.
-- V5. vw_UyeOduncDurumu'nu kullanarak hiç kitap iade etmemiş ama
--     en az bir ödünç almış üyeleri bulun.
-- V6. Yalnızca Bilim kategorisindeki kitapları gösteren, WITH CHECK OPTION'lı
--     vw_BilimKitaplari view'ını oluşturun. Bu view üzerinden Kozmos'un
--     stoğunu 1 artırın, sonra geri alın.
-- V7. vw_KitapYazar view'ını ALTER VIEW ile değiştirerek kitabın yayın yılını ekleyin.
