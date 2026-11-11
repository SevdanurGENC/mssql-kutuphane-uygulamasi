/* =====================================================================
   KÜTÜPHANE UYGULAMASI - STORED PROCEDURE (SAKLI YORDAM) SENARYOLARI
   Ders slaytındaki sıra izlenmiştir:
     Bölüm 1 : Stored Procedure nedir? İsim kuralları
     Bölüm 2 : Basit stored procedure oluşturma ve EXEC ile çağırma
     Bölüm 3 : Koşullu stored procedure
     Bölüm 4 : Parametreli stored procedure (tek parametre)
     Bölüm 5 : Birden fazla parametreli stored procedure
     Bölüm 6 : Stored procedure ile veri ekleme, güncelleme, silme
     Bölüm 7 : Stored procedure'de LIKE kullanımı
     Bölüm 8 : Stored procedure güncelleme (ALTER PROC)
     Bölüm 9 : Stored procedure silme (DROP PROC)
     Bölüm 10: Ek konular - varsayılan parametre, OUTPUT, IF, TRY...CATCH
     Bölüm 11: Öğrenci alıştırmaları

   Ön koşul: Kutuphane_Veri_Ekleme.sql çalıştırılmış olmalı.
   Not     : DROP PROC IF EXISTS komutu SQL Server 2016 ve sonrasında çalışır.
             Veri ekleyen/değiştiren örneklerin sonunda veriler eski haline
             döndürülür; böylece diğer betiklerdeki beklenen sonuçlar bozulmaz.
   ===================================================================== */
USE KutuphaneDB;
GO


/* =====================================================================
   BÖLÜM 1: STORED PROCEDURE NEDİR?
   Dışarıdan parametre alabilen, içinde SQL sorgularımızı çalıştırdığımız,
   veritabanı sunucusunda SAKLANAN programlama birimleridir.

   NEDEN KULLANILIR?
   - Hız ve performans: Sunucuda saklanır, tekrar tekrar hızlı çalışır.
   - Güvenlik: Kullanıcıya tablo yerine yalnızca prosedür yetkisi verilebilir.
   - Ağ trafiği azalır: Uzun sorgu yerine yalnızca "EXEC ProsedurAdi" gönderilir.
   - Tekrar kullanım: Bir kez yazılır, her yerden çağrılır.

   İSİM KURALLARI:
   - Türkçe karakter kullanılamaz   (KitapEkle  doğru,  KitapEkleŞ  yanlış)
   - Boşluk kullanılamaz            (KitapEkle  doğru,  Kitap Ekle  yanlış)
   - Rakamla başlanamaz             (Kitap2Ekle doğru,  2KitapEkle  yanlış)
   - Ayrılmış isim kullanılamaz     (select, insert, table ...)
   - "sp_" ile başlayan isimler SQL Server'ın sistem prosedürleri için
     ayrılmıştır; kendi prosedürlerimizde kullanmıyoruz.

   GENEL YAPI:
   CREATE PROC <Prosedur_Adi> <Parametreler>
   AS
   <Sorgularimiz>

   - CREATE PROC ile CREATE PROCEDURE aynıdır.
   - Çalıştırmak için: EXEC ProsedurAdi   (EXECUTE da yazılabilir)
   - Oluşturulan prosedürler SSMS'te:
     Veritabanı > Programmability > Stored Procedures altında görünür.
   ===================================================================== */


/* =====================================================================
   BÖLÜM 2: BASİT STORED PROCEDURE
   Parametre almaz; her çalıştığında aynı sorguyu çalıştırır.
   ===================================================================== */

-- 2.1  SENARYO: Görevli, tüm kitapları tek komutla görmek istiyor.
DROP PROC IF EXISTS TumKitaplar;
GO
CREATE PROC TumKitaplar
AS
SELECT * FROM Kitaplar;
GO

EXEC TumKitaplar;
-- Beklenen: 18 satır


-- 2.2  SENARYO: Kitaplar kategori adlarıyla listelensin (JOIN'li prosedür)
DROP PROC IF EXISTS KitapListesi;
GO
CREATE PROC KitapListesi
AS
SELECT k.KitapAdi, kt.KategoriAdi, k.YayinYili, k.SayfaSayisi, k.StokAdedi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
ORDER BY kt.KategoriAdi, k.KitapAdi;
GO

EXEC KitapListesi;
-- Beklenen: 18 satır, kategoriye göre sıralı
-- Not: View'da ORDER BY kullanılamıyordu; prosedürde kullanılabilir.


-- 2.3  SENARYO: Sabah açılışta "şu an kimde hangi kitap var?" listesi
DROP PROC IF EXISTS OduncteOlanlar;
GO
CREATE PROC OduncteOlanlar
AS
SELECT u.Ad, u.Soyad, k.KitapAdi, o.OduncTarihi, o.SonTeslimTarihi
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.IadeTarihi IS NULL
ORDER BY o.SonTeslimTarihi;
GO

EXEC OduncteOlanlar;
-- Beklenen: 11 satır


-- 2.4  SENARYO: Kategori başına kitap sayısı raporu (GROUP BY'lı prosedür)
DROP PROC IF EXISTS KategoriRaporu;
GO
CREATE PROC KategoriRaporu
AS
SELECT kt.KategoriAdi, COUNT(k.KitapID) AS KitapSayisi
FROM Kategoriler AS kt
LEFT JOIN Kitaplar AS k ON kt.KategoriID = k.KategoriID
GROUP BY kt.KategoriAdi
ORDER BY KitapSayisi DESC;
GO

EXEC KategoriRaporu;
-- Beklenen: 10 satır. Roman 8, Bilim 3, ... Psikoloji 0, Biyografi 0
GO


/* =====================================================================
   BÖLÜM 3: KOŞULLU STORED PROCEDURE
   Prosedür içinde WHERE ile koşul yazılır. Koşulun değeri prosedürün
   İÇİNE YAZILMIŞTIR (sabit). Değeri dışarıdan almak için Bölüm 4'e bakın.
   ===================================================================== */

-- 3.1  SENARYO: Yalnızca Roman kategorisindeki kitaplar
DROP PROC IF EXISTS RomanKitaplari;
GO
CREATE PROC RomanKitaplari
AS
SELECT KitapAdi, YayinYili, SayfaSayisi
FROM Kitaplar
WHERE KategoriID = 1;
GO

EXEC RomanKitaplari;
-- Beklenen: 8 kitap


-- 3.2  SENARYO: Stokta yalnızca 1 adet kalan kitaplar (satın alma uyarısı)
DROP PROC IF EXISTS StokuAzOlanlar;
GO
CREATE PROC StokuAzOlanlar
AS
SELECT KitapAdi, StokAdedi
FROM Kitaplar
WHERE StokAdedi = 1;
GO

EXEC StokuAzOlanlar;
-- Beklenen: Kırmızı Saçlı Kadın, Zamanın Daha Kısa Tarihi,
--           Memleketimden İnsan Manzaraları, Ben, Robot, Devlet, Huzur


-- 3.3  SENARYO: Hiç ödünç almamış üyeler (hatırlatma listesi)
DROP PROC IF EXISTS OduncAlmayanUyeler;
GO
CREATE PROC OduncAlmayanUyeler
AS
SELECT u.Ad, u.Soyad, u.Eposta
FROM Uyeler AS u
LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
WHERE o.OduncID IS NULL;
GO

EXEC OduncAlmayanUyeler;
-- Beklenen: Burak Çelik, Ece Polat


-- 3.4  SENARYO: Teslim tarihi geçmiş kitaplar (bugüne göre)
DROP PROC IF EXISTS GecikenOdunclar;
GO
CREATE PROC GecikenOdunclar
AS
SELECT u.Ad, u.Soyad, u.Telefon, k.KitapAdi, o.SonTeslimTarihi,
       DATEDIFF(DAY, o.SonTeslimTarihi, GETDATE()) AS GecikmeGun
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.IadeTarihi IS NULL
  AND o.SonTeslimTarihi < CAST(GETDATE() AS DATE)
ORDER BY GecikmeGun DESC;
GO

EXEC GecikenOdunclar;
-- Sonuç, çalıştırdığınız güne göre değişir.
GO


/* =====================================================================
   BÖLÜM 4: PARAMETRELİ STORED PROCEDURE (TEK PARAMETRE)
   Değeri dışarıdan almak için parametre (değişken) tanımlanır.
   Parametre adları @ ile başlar ve veri tipi yazılır.

   CREATE PROC ProsedurAdi @Parametre VeriTipi
   AS
   SELECT ... WHERE Sutun = @Parametre

   Çağırma:  EXEC ProsedurAdi deger
   ===================================================================== */

-- 4.1  SENARYO: Görevli bir kategori seçince o kategorideki kitaplar listelensin.
--      (Bölüm 3.1'deki Roman prosedürünün her kategoride çalışan hali)
DROP PROC IF EXISTS KategoriyeGoreKitaplar;
GO
CREATE PROC KategoriyeGoreKitaplar @KategoriAdi NVARCHAR(50)
AS
SELECT k.KitapAdi, k.YayinYili, k.SayfaSayisi, k.StokAdedi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
WHERE kt.KategoriAdi = @KategoriAdi;
GO

EXEC KategoriyeGoreKitaplar N'Bilim';
-- Beklenen: Zamanın Kısa Tarihi, Zamanın Daha Kısa Tarihi, Kozmos

EXEC KategoriyeGoreKitaplar N'Roman';        -- 8 kitap
EXEC KategoriyeGoreKitaplar N'Psikoloji';    -- boş (kitap yok)

-- Parametre ADIYLA da gönderilebilir (daha okunaklı):
EXEC KategoriyeGoreKitaplar @KategoriAdi = N'Bilim Kurgu';
-- Beklenen: 1984, Ben, Robot


-- 4.2  SENARYO: Üye kartında, seçilen üyenin ödünç geçmişi
DROP PROC IF EXISTS UyeOduncGecmisi;
GO
CREATE PROC UyeOduncGecmisi @UyeID INT
AS
SELECT k.KitapAdi, o.OduncTarihi, o.SonTeslimTarihi, o.IadeTarihi
FROM Oduncler AS o
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.UyeID = @UyeID
ORDER BY o.OduncTarihi;
GO

EXEC UyeOduncGecmisi 1;     -- Ayşe: Kürk Mantolu Madonna, Küçük Prens
EXEC UyeOduncGecmisi 4;     -- Can: Benim Adım Kırmızı, Kozmos
EXEC UyeOduncGecmisi 6;     -- Burak: boş


-- 4.3  SENARYO: Soyadı verilen yazarın kitapları
DROP PROC IF EXISTS YazarinKitaplari;
GO
CREATE PROC YazarinKitaplari @Soyad NVARCHAR(50)
AS
SELECT y.Ad, y.Soyad, k.KitapAdi, k.YayinYili
FROM Yazarlar AS y
INNER JOIN KitapYazar AS ky ON y.YazarID  = ky.YazarID
INNER JOIN Kitaplar   AS k  ON ky.KitapID = k.KitapID
WHERE y.Soyad = @Soyad;
GO

EXEC YazarinKitaplari N'Orwell';     -- 1984, Hayvan Çiftliği
EXEC YazarinKitaplari N'Pamuk';      -- Kırmızı Saçlı Kadın, Benim Adım Kırmızı


-- 4.4  SENARYO: Ülkesi verilen yazarlar
DROP PROC IF EXISTS UlkeyeGoreYazarlar;
GO
CREATE PROC UlkeyeGoreYazarlar @Ulke NVARCHAR(50)
AS
SELECT Ad, Soyad
FROM Yazarlar
WHERE Ulke = @Ulke
ORDER BY Soyad;
GO

EXEC UlkeyeGoreYazarlar N'ABD';
-- Beklenen: Isaac Asimov, Leonard Mlodinow, Carl Sagan
GO


/* =====================================================================
   BÖLÜM 5: BİRDEN FAZLA PARAMETRELİ STORED PROCEDURE
   Parametrelerin arasına virgül konur.
   Çağırırken değerler AYNI SIRAYLA yazılır.
   ===================================================================== */

-- 5.1  SENARYO: "200 ile 300 sayfa arası bir kitap öner"
DROP PROC IF EXISTS SayfaAraligindakiKitaplar;
GO
CREATE PROC SayfaAraligindakiKitaplar
    @EnAz  INT,
    @EnCok INT
AS
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi BETWEEN @EnAz AND @EnCok
ORDER BY SayfaSayisi;
GO

EXEC SayfaAraligindakiKitaplar 200, 300;
-- Beklenen: Kırmızı Saçlı Kadın 204, Zamanın Kısa Tarihi 256,
--           Doğu Ekspresinde Cinayet 256, Ben, Robot 272,
--           Osmanlı'yı Yeniden Keşfetmek 296

-- Parametre adlarıyla gönderilirse sıra önemli değildir:
EXEC SayfaAraligindakiKitaplar @EnCok = 200, @EnAz = 100;
-- Beklenen: Küçük Prens 112, Hayvan Çiftliği 152,
--           Kürk Mantolu Madonna 160, Zamanın Daha Kısa Tarihi 176


-- 5.2  SENARYO: Aylık rapor - iki tarih arasındaki ödünçler
DROP PROC IF EXISTS TarihAraligiOdunclar;
GO
CREATE PROC TarihAraligiOdunclar
    @Baslangic DATE,
    @Bitis     DATE
AS
SELECT u.Ad, u.Soyad, k.KitapAdi, o.OduncTarihi
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE o.OduncTarihi BETWEEN @Baslangic AND @Bitis
ORDER BY o.OduncTarihi;
GO

EXEC TarihAraligiOdunclar '2026-09-01', '2026-09-30';    -- Eylül: 11 satır
EXEC TarihAraligiOdunclar '2026-10-01', '2026-10-31';    -- Ekim: 5 satır


-- 5.3  SENARYO: Belirli bir kategoride, belirli bir yıldan sonra yayımlanmış kitaplar
DROP PROC IF EXISTS KategoriVeYilaGoreKitaplar;
GO
CREATE PROC KategoriVeYilaGoreKitaplar
    @KategoriAdi NVARCHAR(50),
    @Yil         SMALLINT
AS
SELECT k.KitapAdi, k.YayinYili
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
WHERE kt.KategoriAdi = @KategoriAdi
  AND k.YayinYili > @Yil
ORDER BY k.YayinYili;
GO

EXEC KategoriVeYilaGoreKitaplar N'Roman', 1950;
-- Beklenen: İnce Memed 1955, Saatleri Ayarlama Enstitüsü 1961,
--           Benim Adım Kırmızı 1998, Kırmızı Saçlı Kadın 2016
GO


/* =====================================================================
   BÖLÜM 6: STORED PROCEDURE İLE VERİ EKLEME, GÜNCELLEME, SİLME
   Prosedürlerin fonksiyonlardan en önemli farkı: VERİYİ DEĞİŞTİREBİLİRLER.
   Bu bölümdeki örneklerin sonunda eklenen veriler silinir.
   ===================================================================== */

-- 6.1  SENARYO: Görevli yeni üye kaydını tek komutla yapsın.
--      KayitTarihi verilmez; tablodaki DEFAULT GETDATE() bugünün tarihini yazar.
DROP PROC IF EXISTS UyeEkle;
GO
CREATE PROC UyeEkle
    @Ad      NVARCHAR(50),
    @Soyad   NVARCHAR(50),
    @Eposta  NVARCHAR(100),
    @Telefon VARCHAR(15)
AS
INSERT INTO Uyeler (Ad, Soyad, Eposta, Telefon)
VALUES (@Ad, @Soyad, @Eposta, @Telefon);
GO

EXEC UyeEkle N'Ali', N'Vural', N'ali.vural@okul.edu.tr', '05551234567';

SELECT * FROM Uyeler WHERE Eposta = N'ali.vural@okul.edu.tr';
-- Beklenen: 1 satır, KayitTarihi = bugün


-- 6.2  SENARYO: Kütüphaneye yeni kitap geldi.
DROP PROC IF EXISTS KitapEkle;
GO
CREATE PROC KitapEkle
    @ISBN        CHAR(13),
    @KitapAdi    NVARCHAR(150),
    @YayinYili   SMALLINT,
    @SayfaSayisi INT,
    @StokAdedi   INT,
    @KategoriID  INT
AS
INSERT INTO Kitaplar (ISBN, KitapAdi, YayinYili, SayfaSayisi, StokAdedi, KategoriID)
VALUES (@ISBN, @KitapAdi, @YayinYili, @SayfaSayisi, @StokAdedi, @KategoriID);
GO

EXEC KitapEkle '9780000000196', N'Sefiller', 1862, 1200, 2, 1;

EXEC KategoriyeGoreKitaplar N'Roman';
-- Beklenen: Artık 9 roman (Sefiller eklendi)

-- Kısıtlar prosedürde de geçerlidir. Aşağıdakiler HATA verir, deneyin:
-- EXEC KitapEkle '9780000000196', N'Kopya', 2000, 100, 1, 1;   -- UNIQUE (aynı ISBN)
-- EXEC KitapEkle '9780000000202', N'Deneme', 2000, 100, 1, 99; -- FOREIGN KEY (kategori yok)


-- 6.3  SENARYO: Kitabın stoğu artırılacak / azaltılacak.
--      @Miktar artı ise ekler, eksi ise düşer.
DROP PROC IF EXISTS StokGuncelle;
GO
CREATE PROC StokGuncelle
    @KitapID INT,
    @Miktar  INT
AS
UPDATE Kitaplar
SET StokAdedi = StokAdedi + @Miktar
WHERE KitapID = @KitapID;
GO

EXEC StokGuncelle 8, 2;                                    -- Küçük Prens +2
SELECT KitapAdi, StokAdedi FROM Kitaplar WHERE KitapID = 8;
-- Beklenen: 6

EXEC StokGuncelle 8, -2;                                   -- geri al
SELECT KitapAdi, StokAdedi FROM Kitaplar WHERE KitapID = 8;
-- Beklenen: 4

-- CHECK kısıtı (StokAdedi >= 0) devreye girer, HATA verir. Deneyin:
-- EXEC StokGuncelle 3, -5;


-- 6.4  SENARYO: Üyenin telefon numarası değişti (e-postasına göre bul)
DROP PROC IF EXISTS UyeTelefonGuncelle;
GO
CREATE PROC UyeTelefonGuncelle
    @Eposta     NVARCHAR(100),
    @YeniTelefon VARCHAR(15)
AS
UPDATE Uyeler
SET Telefon = @YeniTelefon
WHERE Eposta = @Eposta;
GO

EXEC UyeTelefonGuncelle N'ali.vural@okul.edu.tr', '05559998877';
SELECT Ad, Soyad, Telefon FROM Uyeler WHERE Eposta = N'ali.vural@okul.edu.tr';
-- Beklenen: Ali Vural, 05559998877


-- 6.5  SENARYO: Üye kitabı iade etti.
DROP PROC IF EXISTS IadeAl;
GO
CREATE PROC IadeAl @OduncID INT
AS
UPDATE Oduncler
SET IadeTarihi = CAST(GETDATE() AS DATE)
WHERE OduncID = @OduncID
  AND IadeTarihi IS NULL;          -- zaten iade edilmişse tekrar güncellenmez
GO

EXEC IadeAl 16;                    -- Can, Kozmos'u iade etti
SELECT OduncID, IadeTarihi FROM Oduncler WHERE OduncID = 16;
-- Beklenen: IadeTarihi = bugün

EXEC IadeAl 16;                    -- ikinci kez: (0 rows affected)

-- Diğer betikler etkilenmesin diye geri alalım:
UPDATE Oduncler SET IadeTarihi = NULL WHERE OduncID = 16;


-- 6.6  SENARYO: Üyelik iptali (e-postaya göre sil)
DROP PROC IF EXISTS UyeSil;
GO
CREATE PROC UyeSil @Eposta NVARCHAR(100)
AS
DELETE FROM Uyeler
WHERE Eposta = @Eposta;
GO

EXEC UyeSil N'ali.vural@okul.edu.tr';
SELECT * FROM Uyeler WHERE Eposta = N'ali.vural@okul.edu.tr';
-- Beklenen: boş (Ali Vural silindi)

-- Ödünç kaydı olan üye silinemez (FOREIGN KEY). HATA verir, deneyin:
-- EXEC UyeSil N'ayse.yilmaz@okul.edu.tr';


-- 6.7  SENARYO: Kitap kayıttan düşülecek (ISBN'e göre sil)
DROP PROC IF EXISTS KitapSil;
GO
CREATE PROC KitapSil @ISBN CHAR(13)
AS
DELETE FROM Kitaplar
WHERE ISBN = @ISBN;
GO

EXEC KitapSil '9780000000196';     -- 6.2'de eklenen Sefiller'i siliyoruz
EXEC KategoriyeGoreKitaplar N'Roman';
-- Beklenen: Yeniden 8 roman
GO


/* =====================================================================
   BÖLÜM 7: STORED PROCEDURE'DE LIKE KULLANIMI
   Parametre, % joker karakterleriyle + operatörü kullanılarak birleştirilir:
       WHERE Sutun LIKE N'%' + @Kriter + N'%'
   ===================================================================== */

-- 7.1  SENARYO: Arama kutusu - kitap adında geçen kelimeyle ara
DROP PROC IF EXISTS KitapAra;
GO
CREATE PROC KitapAra @Kriter NVARCHAR(50)
AS
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE KitapAdi LIKE N'%' + @Kriter + N'%';
GO

EXEC KitapAra N'Kırmızı';    -- Kırmızı Saçlı Kadın, Benim Adım Kırmızı
EXEC KitapAra N'Zaman';      -- Zamanın Kısa Tarihi, Zamanın Daha Kısa Tarihi
EXEC KitapAra N'Robot';      -- Ben, Robot


-- 7.2  SENARYO: Baş harfe göre kitaplar (yalnızca SONA % konur)
DROP PROC IF EXISTS HarfleBaslayanKitaplar;
GO
CREATE PROC HarfleBaslayanKitaplar @Harf NVARCHAR(5)
AS
SELECT KitapAdi
FROM Kitaplar
WHERE KitapAdi LIKE @Harf + N'%'
ORDER BY KitapAdi;
GO

EXEC HarfleBaslayanKitaplar N'K';
-- Beklenen: 4 kitap - Kürk Mantolu Madonna, Kırmızı Saçlı Kadın, Küçük Prens, Kozmos
--           (sıralama, veritabanının harmanlama ayarına göre değişebilir)


-- 7.3  SENARYO: Üye arama (ada göre)
DROP PROC IF EXISTS UyeAra;
GO
CREATE PROC UyeAra @Kriter NVARCHAR(50)
AS
SELECT Ad, Soyad, Eposta
FROM Uyeler
WHERE Ad LIKE N'%' + @Kriter + N'%';
GO

EXEC UyeAra N'Me';
-- Beklenen: Mehmet Demir, Merve Yıldız


-- 7.4  SENARYO: Telefonun son 4 hanesiyle üye bulma
DROP PROC IF EXISTS TelefonlaUyeBul;
GO
CREATE PROC TelefonlaUyeBul @Son4 VARCHAR(4)
AS
SELECT Ad, Soyad, Telefon
FROM Uyeler
WHERE Telefon LIKE '%' + @Son4;
GO

EXEC TelefonlaUyeBul '2233';
-- Beklenen: Ayşe Yılmaz
GO


/* =====================================================================
   BÖLÜM 8: STORED PROCEDURE GÜNCELLEME (ALTER PROC)
   Prosedürü silmeden içindeki komutları değiştirmek için ALTER kullanılır.
   ===================================================================== */

-- 8.1  SENARYO: UyeAra artık ada göre değil, SOYADA göre arasın.
ALTER PROC UyeAra @Kriter NVARCHAR(50)
AS
SELECT Ad, Soyad, Eposta
FROM Uyeler
WHERE Soyad LIKE N'%' + @Kriter + N'%';
GO

EXEC UyeAra N'Yıl';
-- Beklenen: Ayşe Yılmaz, Merve Yıldız


-- 8.2  SENARYO: KitapAra hem kitap adında hem yazar soyadında arasın.
ALTER PROC KitapAra @Kriter NVARCHAR(50)
AS
SELECT k.KitapAdi, y.Ad, y.Soyad
FROM Kitaplar AS k
INNER JOIN KitapYazar AS ky ON k.KitapID  = ky.KitapID
INNER JOIN Yazarlar   AS y  ON ky.YazarID = y.YazarID
WHERE k.KitapAdi LIKE N'%' + @Kriter + N'%'
   OR y.Soyad    LIKE N'%' + @Kriter + N'%';
GO

EXEC KitapAra N'Pamuk';      -- yazar soyadından: Kırmızı Saçlı Kadın, Benim Adım Kırmızı
EXEC KitapAra N'Prens';      -- kitap adından: Küçük Prens


-- 8.3  Prosedürün kodunu görmek
EXEC sp_helptext 'KitapAra';

-- 8.4  Veritabanındaki tüm prosedürleri listelemek
SELECT name AS ProsedurAdi, create_date AS Olusturma, modify_date AS SonDegisiklik
FROM sys.procedures
ORDER BY name;
GO


/* =====================================================================
   BÖLÜM 9: STORED PROCEDURE SİLME (DROP PROC)
   ===================================================================== */

-- 9.1  Silmek için DROP PROC kullanılır. Tablodaki veriler etkilenmez.
DROP PROC TumKitaplar;

-- Silinen prosedür çağrılırsa HATA verir (Msg 2812). Deneyin:
-- EXEC TumKitaplar;

-- 9.2  Prosedür yoksa hata vermeden silmek (SQL Server 2016+)
DROP PROC IF EXISTS TumKitaplar;

-- Ders boyunca kullanmak için yeniden oluşturalım:
GO
CREATE PROC TumKitaplar
AS
SELECT * FROM Kitaplar;
GO


/* =====================================================================
   BÖLÜM 10: EK KONULAR
   ===================================================================== */

-- 10.1 VARSAYILAN DEĞERLİ PARAMETRE
--      SENARYO: "Kısa kitap öner" - sayfa sınırı verilmezse 250 kabul edilsin.
DROP PROC IF EXISTS KisaKitapOner;
GO
CREATE PROC KisaKitapOner @EnCokSayfa INT = 250
AS
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi <= @EnCokSayfa
ORDER BY SayfaSayisi;
GO

EXEC KisaKitapOner;          -- parametre yok, 250 kullanılır
-- Beklenen: Küçük Prens 112, Hayvan Çiftliği 152, Kürk Mantolu Madonna 160,
--           Zamanın Daha Kısa Tarihi 176, Kırmızı Saçlı Kadın 204

EXEC KisaKitapOner 150;      -- Küçük Prens 112


-- 10.2 OUTPUT PARAMETRESİ: Prosedürden değer geri almak
--      SENARYO: Bir üyenin toplam ve elindeki kitap sayısını değişkenlere al.
DROP PROC IF EXISTS UyeOduncSayilari;
GO
CREATE PROC UyeOduncSayilari
    @UyeID   INT,
    @Toplam  INT OUTPUT,
    @Elinde  INT OUTPUT
AS
SELECT @Toplam = COUNT(*)
FROM Oduncler
WHERE UyeID = @UyeID;

SELECT @Elinde = COUNT(*)
FROM Oduncler
WHERE UyeID = @UyeID AND IadeTarihi IS NULL;
GO

DECLARE @T INT, @E INT;
EXEC UyeOduncSayilari 4, @T OUTPUT, @E OUTPUT;
SELECT @T AS ToplamOdunc, @E AS ElindekiKitap;
-- Beklenen: 2, 2  (Can Öztürk)
GO


-- 10.3 IF ile KONTROL: Kurallı ödünç verme
--      SENARYO: Kitap verilmeden önce kontrol edilsin:
--        - Üye var mı?   - Kitap var mı?   - Rafta adedi kaldı mı?
--      Her şey uygunsa ödünç kaydı oluşturulsun. Ödünç süresi verilmezse 14 gün.
--      SET NOCOUNT ON: "(1 row affected)" mesajlarını gizler.
DROP PROC IF EXISTS OduncVer;
GO
CREATE PROC OduncVer
    @UyeID   INT,
    @KitapID INT,
    @Gun     INT = 14
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Stok INT;
    DECLARE @Oduncte INT;

    IF NOT EXISTS (SELECT 1 FROM Uyeler WHERE UyeID = @UyeID)
    BEGIN
        PRINT N'Üye bulunamadı.';
        RETURN;
    END

    SELECT @Stok = StokAdedi FROM Kitaplar WHERE KitapID = @KitapID;

    IF @Stok IS NULL
    BEGIN
        PRINT N'Kitap bulunamadı.';
        RETURN;
    END

    SELECT @Oduncte = COUNT(*)
    FROM Oduncler
    WHERE KitapID = @KitapID AND IadeTarihi IS NULL;

    IF @Stok - @Oduncte <= 0
    BEGIN
        PRINT N'Bu kitabın rafta adedi kalmadı.';
        RETURN;
    END

    INSERT INTO Oduncler (KitapID, UyeID, OduncTarihi, SonTeslimTarihi)
    VALUES (@KitapID, @UyeID, CAST(GETDATE() AS DATE),
            DATEADD(DAY, @Gun, CAST(GETDATE() AS DATE)));

    PRINT N'Ödünç verildi.';
END;
GO

-- Mesajlar SSMS'te "Messages" sekmesinde görünür.
EXEC OduncVer 99, 1;         -- Üye bulunamadı.
EXEC OduncVer 1, 99;         -- Kitap bulunamadı.
EXEC OduncVer 12, 3;         -- Ödünç verildi.  (Ece, Kırmızı Saçlı Kadın - stok 1)
EXEC OduncVer 6, 3;          -- Bu kitabın rafta adedi kalmadı.  (son adet Ece'de)
EXEC OduncVer 6, 8, 21;      -- Ödünç verildi.  (Burak, Küçük Prens, 21 gün)

EXEC UyeOduncGecmisi 12;     -- Ece'nin yeni ödüncü
EXEC UyeOduncGecmisi 6;      -- Burak'ın yeni ödüncü

-- Diğer betikler etkilenmesin diye bu iki ödüncü silelim
-- (Ece ve Burak'ın daha önce hiç ödüncü yoktu):
DELETE FROM Oduncler WHERE UyeID IN (6, 12);
GO


-- 10.4 TRY...CATCH ile HATA YAKALAMA
--      SENARYO: Stok eksiye düşecekse SQL kırmızı hata vermesin,
--      anlaşılır bir mesaj gösterilsin.
DROP PROC IF EXISTS StokGuncelleGuvenli;
GO
CREATE PROC StokGuncelleGuvenli
    @KitapID INT,
    @Miktar  INT
AS
BEGIN
    BEGIN TRY
        UPDATE Kitaplar
        SET StokAdedi = StokAdedi + @Miktar
        WHERE KitapID = @KitapID;

        PRINT N'Stok güncellendi.';
    END TRY
    BEGIN CATCH
        PRINT N'Stok güncellenemedi: stok eksiye düşemez.';
        PRINT ERROR_MESSAGE();          -- SQL'in orijinal hata mesajı
    END CATCH
END;
GO

EXEC StokGuncelleGuvenli 3, -5;    -- Stok güncellenemedi ... (stok 1'di, değişmedi)
EXEC StokGuncelleGuvenli 3, 1;     -- Stok güncellendi.
EXEC StokGuncelleGuvenli 3, -1;    -- geri al: Stok güncellendi. (yeniden 1)
GO


/* =====================================================================
   BÖLÜM 11: ÖĞRENCİ ALIŞTIRMALARI
   ===================================================================== */
-- P1.  Tüm yazarları soyadına göre sıralayan TumYazarlar prosedürünü yazın.
-- P2.  Yalnızca Türk yazarları listeleyen koşullu TurkYazarlar prosedürünü yazın.
-- P3.  Kitap ID'si verilen kitabın bilgilerini ve kategori adını getiren
--      KitapDetay @KitapID prosedürünü yazın.
-- P4.  İki yıl arasında yayımlanmış kitapları getiren
--      YilAraligindakiKitaplar @BasYil, @BitYil prosedürünü yazın.
--      EXEC YilAraligindakiKitaplar 1940, 1960  -> 7 kitap gelmeli.
-- P5.  Yeni kategori ekleyen KategoriEkle @KategoriAdi prosedürünü yazın,
--      "Gezi" kategorisini ekleyin, sonra silin.
-- P6.  Yazar adında geçen harf(ler)e göre arama yapan YazarAra @Kriter
--      prosedürünü LIKE ile yazın.
-- P7.  P6'daki prosedürü ALTER PROC ile değiştirip ülke adına göre de arasın.
-- P8.  Bir kategorideki kitap sayısını OUTPUT parametresiyle döndüren
--      KategoriKitapSayisi @KategoriID, @Sayi OUTPUT prosedürünü yazın.
-- P9.  Ödünç kaydının teslim tarihini @EkGun kadar uzatan SureUzat
--      prosedürünü yazın. İade edilmiş ödünçlerde uzatma yapılmasın (IF ile).
-- P10. P1'de yazdığınız prosedürü DROP PROC ile silin.
