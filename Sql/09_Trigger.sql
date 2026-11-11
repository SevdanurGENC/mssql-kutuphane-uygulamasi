/* =====================================================================
   KÜTÜPHANE UYGULAMASI - TRIGGER (TETİKLEYİCİ) SENARYOLARI
   Ders slaytındaki sıra izlenmiştir:
     Bölüm 0 : Hazırlık (kayıt/log tabloları)
     Bölüm 1 : Trigger nedir? Türleri (AFTER / INSTEAD OF)
     Bölüm 2 : İlk trigger - kayıt eklenince listeleyen trigger
     Bölüm 3 : inserted / deleted sanal tablolarını görmek
     Bölüm 4 : UPDATE tetikleyicisi - değişiklikleri kayıt altına almak
     Bölüm 5 : INSERT ve UPDATE tetikleyicisi - ödünç/iade hareketleri
     Bölüm 6 : ROLLBACK + RAISERROR - iş kuralları (INSERT)
     Bölüm 7 : ROLLBACK + RAISERROR - iş kuralları (UPDATE)
     Bölüm 8 : DELETE tetikleyicisi - silineni arşivle / silmeyi engelle
     Bölüm 9 : INSTEAD OF tetikleyicisi (tablo ve view üzerinde)
     Bölüm 10: İç içe (nested) ve recursive trigger
     Bölüm 11: ALTER / DROP / Pasifleştirme - Aktifleştirme
     Bölüm 12: TEMİZLİK (tüm trigger'ları ve log tablolarını kaldırır)
     Bölüm 13: Öğrenci alıştırmaları

   Ön koşul: 01_Veri_Ekleme.sql çalıştırılmış olmalı.
   Not     : DROP ... IF EXISTS komutları SQL Server 2016 ve sonrasında çalışır.

   ÇOK ÖNEMLİ - BU BETİĞİ ÇALIŞTIRIRKEN:
   1) Trigger'lar tabloda KALICIDIR; birbirini etkileyebilir. Bu yüzden her
      senaryonun sonunda trigger PASİF hale getirilir (DISABLE TRIGGER).
   2) Hata vermesi BEKLENEN komutların arkasında GO vardır. Trigger içinde
      ROLLBACK yapılınca o batch (GO'ya kadar olan bölüm) durdurulur;
      GO sayesinde betiğin geri kalanı çalışmaya devam eder.
   3) Test için eklenen kayıtlar her senaryonun sonunda silinir.
   4) Bölüm 12 (Temizlik) tüm trigger'ları kaldırır. Diğer betikleri
      (özellikle 01_Veri_Ekleme.sql) çalıştırmadan önce mutlaka
      Bölüm 12'yi çalıştırın.
   ===================================================================== */
USE KutuphaneDB;
GO


/* =====================================================================
   BÖLÜM 0: HAZIRLIK
   Betik tekrar çalıştırılabilsin diye önce eski trigger'lar silinir.
   Ardından trigger'ların kayıt tutacağı YENİ tablolar oluşturulur.
   (Mevcut tablolara sütun eklenmez.)
   ===================================================================== */
DROP TRIGGER IF EXISTS trg_UyeEklendi;
DROP TRIGGER IF EXISTS trg_KitapGuncelleGoster;
DROP TRIGGER IF EXISTS trg_StokLog;
DROP TRIGGER IF EXISTS trg_OduncVerildi;
DROP TRIGGER IF EXISTS trg_IadeAlindi;
DROP TRIGGER IF EXISTS trg_TekKitapKurali;
DROP TRIGGER IF EXISTS trg_StokKontrol;
DROP TRIGGER IF EXISTS trg_RomanSayfaKontrol;
DROP TRIGGER IF EXISTS trg_ISBNDegismez;
DROP TRIGGER IF EXISTS trg_IadeTarihiKontrol;
DROP TRIGGER IF EXISTS trg_UyeArsiv;
DROP TRIGGER IF EXISTS trg_AcikOduncSilinmez;
DROP TRIGGER IF EXISTS trg_KategoriSilinmez;
DROP TRIGGER IF EXISTS trg_UyePasifYap;
DROP VIEW    IF EXISTS vw_KitapKategoriEkle;     -- üzerindeki trigger da silinir
DROP TABLE   IF EXISTS OduncHareketleri;         -- üzerindeki trigger da silinir
DROP TABLE   IF EXISTS StokDegisiklikLog;
DROP TABLE   IF EXISTS SilinenUyeler;
DROP TABLE   IF EXISTS PasifUyeler;
GO

-- Ödünç verme ve iade hareketlerinin kaydı
CREATE TABLE OduncHareketleri (
    HareketID    INT IDENTITY(1,1) PRIMARY KEY,
    Islem        NVARCHAR(20),
    OduncID      INT,
    UyeID        INT,
    KitapID      INT,
    IslemZamani  DATETIME DEFAULT GETDATE()
);

-- Stok değişikliklerinin kaydı (kim, ne zaman, eski/yeni değer)
CREATE TABLE StokDegisiklikLog (
    LogID               INT IDENTITY(1,1) PRIMARY KEY,
    KitapID             INT,
    EskiStok            INT,
    YeniStok            INT,
    DegistirenKullanici NVARCHAR(128) DEFAULT SUSER_SNAME(),
    DegisiklikZamani    DATETIME DEFAULT GETDATE()
);

-- Silinen üyelerin arşivi
CREATE TABLE SilinenUyeler (
    UyeID          INT,
    Ad             NVARCHAR(50),
    Soyad          NVARCHAR(50),
    Eposta         NVARCHAR(100),
    SilinmeZamani  DATETIME DEFAULT GETDATE()
);

-- Silinmek yerine pasife alınan üyeler
CREATE TABLE PasifUyeler (
    UyeID        INT PRIMARY KEY,
    PasifZamani  DATETIME DEFAULT GETDATE()
);
GO


/* =====================================================================
   BÖLÜM 1: TRIGGER NEDİR?
   Bir tabloda INSERT, UPDATE veya DELETE yapıldığında OTOMATİK olarak
   çalışan özel bir stored procedure'dür. EXEC ile çağrılmaz; olay olunca
   kendiliğinden tetiklenir. SELECT ile bağlantısı yoktur.

   NE ZAMAN KULLANILIR?
   - Değişiklikleri takip etmek (kim, ne zaman, neyi değiştirdi)
   - Karmaşık iş kurallarını uygulamak (elinde kitap varken yenisi verilmesin)
   - Silinen kayıtları arşivlemek
   - Standart dışında anlaşılır hata mesajları vermek

   TÜRLERİ:
   AFTER (FOR)  : İşlem YAPILDIKTAN SONRA çalışır. Yalnızca tablolarda.
                  Uygun değilse ROLLBACK ile işlem geri alınır.
   INSTEAD OF   : İşlemin YERİNE çalışır; asıl işlem hiç yapılmaz.
                  Tablolarda ve VIEW'larda tanımlanabilir.

   GENEL YAPI:
   CREATE TRIGGER trigger_adi
   ON tablo_adi
   AFTER | INSTEAD OF  INSERT, UPDATE, DELETE
   AS
   BEGIN
       -- SQL ifadeleri
   END

   inserted / deleted SANAL TABLOLARI:
   İşlem    | inserted            | deleted
   ---------+---------------------+--------------------
   INSERT   | eklenen satırlar    | boş
   DELETE   | boş                 | silinen satırlar
   UPDATE   | satırların YENİ hali| satırların ESKİ hali

   ÖNEMLİ: Trigger her SATIR için değil, her KOMUT için BİR KEZ çalışır.
           Tek komutla 5 satır eklenirse inserted tablosunda 5 satır olur.

   SSMS'te: Tablo > Triggers klasörü altında görünür.
   ===================================================================== */


/* =====================================================================
   BÖLÜM 2: İLK TRIGGER - KAYIT EKLENİNCE MESAJ VEREN VE LİSTELEYEN TRIGGER
   ===================================================================== */

-- 2.1  SENARYO: Yeni üye kaydedildiğinde görevliye mesaj verilsin
--      ve eklenen kayıt gösterilsin.
CREATE TRIGGER trg_UyeEklendi
ON Uyeler
AFTER INSERT
AS
BEGIN
    PRINT N'Yeni üye eklendi. Trigger çalıştı.';
    SELECT * FROM inserted;          -- yalnızca eklenen satır(lar)
END;
GO

-- Test: Tek üye ekle -> Messages sekmesinde mesaj, Results'ta eklenen satır
INSERT INTO Uyeler (Ad, Soyad, Eposta)
VALUES (N'Test', N'Üye', N'test.uye1@okul.edu.tr');
GO

-- Test: Tek komutla iki üye ekle -> Trigger BİR KEZ çalışır, inserted'da 2 satır var
INSERT INTO Uyeler (Ad, Soyad, Eposta) VALUES
(N'Test', N'İki',  N'test.uye2@okul.edu.tr'),
(N'Test', N'Üç',   N'test.uye3@okul.edu.tr');
GO

-- Temizlik ve trigger'ı pasif yapma
DELETE FROM Uyeler WHERE Eposta LIKE N'test.uye%@okul.edu.tr';
DISABLE TRIGGER trg_UyeEklendi ON Uyeler;
GO
-- Not: Trigger içinde SELECT ile sonuç döndürmek öğrenme amaçlıdır;
--      gerçek uygulamalarda önerilmez.


/* =====================================================================
   BÖLÜM 3: inserted / deleted SANAL TABLOLARINI GÖRMEK
   UPDATE işleminde eski değer deleted'a, yeni değer inserted'a gider.
   ===================================================================== */

-- 3.1  SENARYO: Kitap güncellendiğinde eski ve yeni hali yan yana görelim.
CREATE TRIGGER trg_KitapGuncelleGoster
ON Kitaplar
AFTER UPDATE
AS
BEGIN
    SELECT N'ESKİ (deleted)' AS Kaynak, KitapID, KitapAdi, StokAdedi FROM deleted;
    SELECT N'YENİ (inserted)' AS Kaynak, KitapID, KitapAdi, StokAdedi FROM inserted;
END;
GO

UPDATE Kitaplar SET StokAdedi = StokAdedi + 1 WHERE KitapID = 8;
-- Beklenen: ESKİ -> Küçük Prens 4 | YENİ -> Küçük Prens 5
GO

UPDATE Kitaplar SET StokAdedi = StokAdedi - 1 WHERE KitapID = 8;   -- geri al
-- Beklenen: ESKİ 5 | YENİ 4
GO

DISABLE TRIGGER trg_KitapGuncelleGoster ON Kitaplar;
GO


/* =====================================================================
   BÖLÜM 4: UPDATE TETİKLEYİCİSİ - DEĞİŞİKLİKLERİ KAYIT ALTINA ALMAK
   UPDATE(SutunAdi) fonksiyonu: O sütun güncellendiyse TRUE döner.
   ===================================================================== */

-- 4.1  SENARYO: Müdür, kitap stoklarını kimin ne zaman değiştirdiğini görmek istiyor.
CREATE TRIGGER trg_StokLog
ON Kitaplar
AFTER UPDATE
AS
BEGIN
    IF UPDATE(StokAdedi)                     -- yalnızca stok güncellendiyse
    BEGIN
        INSERT INTO StokDegisiklikLog (KitapID, EskiStok, YeniStok)
        SELECT i.KitapID, d.StokAdedi, i.StokAdedi
        FROM inserted AS i
        INNER JOIN deleted AS d ON i.KitapID = d.KitapID
        WHERE i.StokAdedi <> d.StokAdedi;    -- değer gerçekten değiştiyse
    END
END;
GO

-- Test 1: Tek kitabın stoğu değişti
UPDATE Kitaplar SET StokAdedi = StokAdedi + 2 WHERE KitapID = 10;   -- Suç ve Ceza 3 -> 5

-- Test 2: Tek komutla birden çok kitap (Bilim Kurgu: 1984 ve Ben, Robot)
UPDATE Kitaplar SET StokAdedi = StokAdedi + 1 WHERE KategoriID = 9;

-- Test 3: Stok değil, başka sütun güncellendi -> log'a YAZILMAZ
UPDATE Kitaplar SET KitapAdi = KitapAdi WHERE KitapID = 1;

SELECT l.LogID, k.KitapAdi, l.EskiStok, l.YeniStok,
       l.DegistirenKullanici, l.DegisiklikZamani
FROM StokDegisiklikLog AS l
INNER JOIN Kitaplar AS k ON l.KitapID = k.KitapID;
-- Beklenen: 3 satır - Suç ve Ceza 3->5, 1984 3->4, Ben, Robot 1->2
GO

-- Stokları geri alalım (bunlar da log'a yazılır)
UPDATE Kitaplar SET StokAdedi = StokAdedi - 2 WHERE KitapID = 10;
UPDATE Kitaplar SET StokAdedi = StokAdedi - 1 WHERE KategoriID = 9;

SELECT * FROM StokDegisiklikLog;    -- Beklenen: 6 satır
DISABLE TRIGGER trg_StokLog ON Kitaplar;
GO


/* =====================================================================
   BÖLÜM 5: INSERT ve UPDATE TETİKLEYİCİLERİ - ÖDÜNÇ / İADE HAREKETLERİ
   ===================================================================== */

-- 5.1  SENARYO: Her ödünç verildiğinde hareket tablosuna "Ödünç" kaydı düşülsün.
CREATE TRIGGER trg_OduncVerildi
ON Oduncler
AFTER INSERT
AS
BEGIN
    INSERT INTO OduncHareketleri (Islem, OduncID, UyeID, KitapID)
    SELECT N'Ödünç', OduncID, UyeID, KitapID
    FROM inserted;
END;
GO

-- 5.2  SENARYO: Kitap iade edildiğinde (IadeTarihi NULL'dan doluya geçince)
--      "İade" kaydı düşülsün.
CREATE TRIGGER trg_IadeAlindi
ON Oduncler
AFTER UPDATE
AS
BEGIN
    IF UPDATE(IadeTarihi)
    BEGIN
        INSERT INTO OduncHareketleri (Islem, OduncID, UyeID, KitapID)
        SELECT N'İade', i.OduncID, i.UyeID, i.KitapID
        FROM inserted AS i
        INNER JOIN deleted AS d ON i.OduncID = d.OduncID
        WHERE d.IadeTarihi IS NULL
          AND i.IadeTarihi IS NOT NULL;
    END
END;
GO

-- Test: Burak (6) Küçük Prens'i (8) alıyor, sonra iade ediyor.
INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)
VALUES (8, 6, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));

UPDATE Oduncler
SET IadeTarihi = CAST(GETDATE() AS DATE)
WHERE UyeID = 6 AND IadeTarihi IS NULL;

SELECT * FROM OduncHareketleri;
-- Beklenen: 2 satır - Ödünç (Uye 6, Kitap 8), İade (Uye 6, Kitap 8)
GO

-- Temizlik ve pasif yapma
DELETE FROM Oduncler WHERE UyeID = 6;
DISABLE TRIGGER trg_OduncVerildi ON Oduncler;
DISABLE TRIGGER trg_IadeAlindi   ON Oduncler;
GO


/* =====================================================================
   BÖLÜM 6: ROLLBACK TRANSACTION + RAISERROR - İŞ KURALLARI (INSERT)
   ROLLBACK TRANSACTION : Trigger'ı başlatan işlemi İPTAL eder.
   RAISERROR            : Kullanıcıya işlemin NEDEN iptal edildiğini bildirir.
                          RAISERROR(N'mesaj', önem_derecesi, durum)
   Önem derecesi 16 kullanıcı hatasıdır (kırmızı mesaj). Slayttaki örneklerde
   1 kullanılmıştır; 1 bilgi mesajıdır, işlemi yine ROLLBACK iptal eder.

   ROLLBACK sonrası ayrıca şu mesaj görülür; bu NORMALDİR:
   "Msg 3609: The transaction ended in the trigger. The batch has been aborted."
   ===================================================================== */

-- 6.1  SENARYO (slayttaki kütüphane örneği):
--      Bir üye, elindeki kitabı iade etmeden İKİNCİ bir kitap alamasın.
CREATE TRIGGER trg_TekKitapKurali
ON Oduncler
AFTER INSERT
AS
BEGIN
    -- Yeni ödünç alan üyelerin iade etmediği kitap sayısı 1'den fazlaysa
    IF EXISTS (SELECT o.UyeID
               FROM Oduncler AS o
               WHERE o.IadeTarihi IS NULL
                 AND o.UyeID IN (SELECT UyeID FROM inserted)
               GROUP BY o.UyeID
               HAVING COUNT(*) > 1)
    BEGIN
        RAISERROR(N'Üyenin iade etmediği bir kitap var. Yeni kitap verilemez!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Test 1: Burak'ın (6) elinde kitap yok -> Küçük Prens verilir (BAŞARILI)
INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)
VALUES (8, 6, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));
GO

-- Test 2: Burak ikinci kitabı istiyor -> ENGELLENİR (hata beklenir)
INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)
VALUES (10, 6, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));
GO

-- Test 3: Ayşe'nin (1) elinde Küçük Prens var -> ENGELLENİR (hata beklenir)
INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)
VALUES (10, 1, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));
GO

-- Kontrol: Burak'ın yalnızca 1 ödüncü olmalı
SELECT * FROM Oduncler WHERE UyeID = 6;    -- Beklenen: 1 satır (Küçük Prens)

DELETE FROM Oduncler WHERE UyeID = 6;
DISABLE TRIGGER trg_TekKitapKurali ON Oduncler;
GO


-- 6.2  SENARYO: Kitabın raftaki adedi bittiyse ödünç verilemesin.
--      (Ödünçte olan adet, stoğu geçemez.)
CREATE TRIGGER trg_StokKontrol
ON Oduncler
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT k.KitapID
               FROM Kitaplar AS k
               INNER JOIN Oduncler AS o ON k.KitapID = o.KitapID
               WHERE o.IadeTarihi IS NULL
                 AND k.KitapID IN (SELECT KitapID FROM inserted)
               GROUP BY k.KitapID, k.StokAdedi
               HAVING COUNT(*) > k.StokAdedi)
    BEGIN
        RAISERROR(N'Bu kitabın rafta adedi kalmadı!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Test 1: Kırmızı Saçlı Kadın (3) stok 1, kimsede değil -> Ece'ye (12) verilir (BAŞARILI)
INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)
VALUES (3, 12, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));
GO

-- Test 2: Aynı kitabı Burak (6) istiyor, tek adet Ece'de -> ENGELLENİR (hata beklenir)
INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)
VALUES (3, 6, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));
GO

SELECT * FROM Oduncler WHERE KitapID = 3;  -- Beklenen: 1 satır (Ece)

DELETE FROM Oduncler WHERE UyeID = 12;
DISABLE TRIGGER trg_StokKontrol ON Oduncler;
GO


-- 6.3  SENARYO (slayttaki "500 sayfadan az roman" örneğinin uyarlaması):
--      Roman kategorisine 100 sayfadan kısa kitap eklenemesin.
--      inserted, Kategoriler tablosuyla JOIN edilerek kategori adına bakılır.
CREATE TRIGGER trg_RomanSayfaKontrol
ON Kitaplar
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT 1
               FROM inserted AS i
               INNER JOIN Kategoriler AS kt ON i.KategoriID = kt.KategoriID
               WHERE kt.KategoriAdi = N'Roman'
                 AND i.SayfaSayisi < 100)
    BEGIN
        RAISERROR(N'Roman kategorisine 100 sayfadan kısa kitap eklenemez!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Test 1: 80 sayfalık roman -> ENGELLENİR (hata beklenir)
INSERT INTO Kitaplar (ISBN, KitapAdi, YayinYili, SayfaSayisi, StokAdedi, KategoriID)
VALUES ('9780000000301', N'Deneme Kısa Roman', 2020, 80, 1, 1);
GO

-- Test 2: 350 sayfalık roman -> eklenir (BAŞARILI)
INSERT INTO Kitaplar (ISBN, KitapAdi, YayinYili, SayfaSayisi, StokAdedi, KategoriID)
VALUES ('9780000000318', N'Deneme Uzun Roman', 2020, 350, 1, 1);
GO

-- Test 3: 80 sayfalık ÇOCUK kitabı -> kural yalnızca roman için, eklenir (BAŞARILI)
INSERT INTO Kitaplar (ISBN, KitapAdi, YayinYili, SayfaSayisi, StokAdedi, KategoriID)
VALUES ('9780000000325', N'Deneme Çocuk Kitabı', 2020, 80, 1, 5);
GO

SELECT KitapAdi, SayfaSayisi FROM Kitaplar WHERE ISBN LIKE '97800000003%';
-- Beklenen: Deneme Uzun Roman, Deneme Çocuk Kitabı (kısa roman YOK)

DELETE FROM Kitaplar WHERE ISBN IN ('9780000000318', '9780000000325');
DISABLE TRIGGER trg_RomanSayfaKontrol ON Kitaplar;
GO


/* =====================================================================
   BÖLÜM 7: ROLLBACK + RAISERROR - İŞ KURALLARI (UPDATE)
   ===================================================================== */

-- 7.1  SENARYO (slayttaki "cinsiyet güncellenmesin" örneğinin uyarlaması):
--      Kitabın ISBN numarası değiştirilemesin.
--      inserted (yeni) ile deleted (eski) karşılaştırılır.
CREATE TRIGGER trg_ISBNDegismez
ON Kitaplar
AFTER UPDATE
AS
BEGIN
    IF UPDATE(ISBN)
       AND EXISTS (SELECT 1
                   FROM inserted AS i
                   INNER JOIN deleted AS d ON i.KitapID = d.KitapID
                   WHERE i.ISBN <> d.ISBN)
    BEGIN
        RAISERROR(N'ISBN numarası değiştirilemez!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Test 1: ISBN değiştirme -> ENGELLENİR (hata beklenir)
UPDATE Kitaplar SET ISBN = '9789999999999' WHERE KitapID = 1;
GO

-- Test 2: Başka sütun güncelleme -> izin verilir (BAŞARILI)
UPDATE Kitaplar SET StokAdedi = StokAdedi + 1 WHERE KitapID = 1;
UPDATE Kitaplar SET StokAdedi = StokAdedi - 1 WHERE KitapID = 1;   -- geri al
GO

SELECT KitapAdi, ISBN, StokAdedi FROM Kitaplar WHERE KitapID = 1;
-- Beklenen: Kürk Mantolu Madonna | 9780000000011 | 3  (ISBN değişmedi)

DISABLE TRIGGER trg_ISBNDegismez ON Kitaplar;
GO


-- 7.2  SENARYO (slayttaki "sayfa sayısı" kuralının uyarlaması):
--      İade tarihi, ödünç tarihinden ÖNCE olamaz.
CREATE TRIGGER trg_IadeTarihiKontrol
ON Oduncler
AFTER UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE IadeTarihi < OduncTarihi)
    BEGIN
        RAISERROR(N'İade tarihi, ödünç tarihinden önce olamaz!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Test: OduncID 16 (ödünç tarihi 2026-10-08), iade tarihi 2026-09-01 -> ENGELLENİR
UPDATE Oduncler SET IadeTarihi = '2026-09-01' WHERE OduncID = 16;
GO

SELECT OduncID, OduncTarihi, IadeTarihi FROM Oduncler WHERE OduncID = 16;
-- Beklenen: IadeTarihi hâlâ NULL

DISABLE TRIGGER trg_IadeTarihiKontrol ON Oduncler;
GO


/* =====================================================================
   BÖLÜM 8: DELETE TETİKLEYİCİSİ
   Silinen kayıtlar deleted sanal tablosunda bulunur.
   ===================================================================== */

-- 8.1  SENARYO (slayttaki "silinen öğrenciler mezun tablosuna" örneği):
--      Silinen üyeler SilinenUyeler arşiv tablosuna kaydedilsin.
CREATE TRIGGER trg_UyeArsiv
ON Uyeler
AFTER DELETE
AS
BEGIN
    INSERT INTO SilinenUyeler (UyeID, Ad, Soyad, Eposta)
    SELECT UyeID, Ad, Soyad, Eposta
    FROM deleted;

    PRINT N'Silinen üye arşive kaydedildi.';
END;
GO

-- Test: Deneme üyesi ekle, sonra sil
INSERT INTO Uyeler (Ad, Soyad, Eposta) VALUES (N'Arşiv', N'Deneme', N'arsiv.deneme@okul.edu.tr');
DELETE FROM Uyeler WHERE Eposta = N'arsiv.deneme@okul.edu.tr';

SELECT * FROM SilinenUyeler;
-- Beklenen: 1 satır - Arşiv Deneme
SELECT * FROM Uyeler WHERE Eposta = N'arsiv.deneme@okul.edu.tr';
-- Beklenen: boş (asıl tablodan silindi)

DISABLE TRIGGER trg_UyeArsiv ON Uyeler;
GO


-- 8.2  SENARYO (slayttaki "10A'nın kız öğrencileri silinemesin" örneğinin uyarlaması):
--      İADE EDİLMEMİŞ ödünç kayıtları silinemesin; iade edilmiş olanlar silinebilir.
CREATE TRIGGER trg_AcikOduncSilinmez
ON Oduncler
AFTER DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM deleted WHERE IadeTarihi IS NULL)
    BEGIN
        RAISERROR(N'İade edilmemiş ödünç kayıtları silinemez!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Test 1: OduncID 16 henüz iade edilmedi -> ENGELLENİR (hata beklenir)
DELETE FROM Oduncler WHERE OduncID = 16;
GO

-- Test 2: Ayşe'nin (1) iki ödüncü var: biri iade edilmiş, biri edilmemiş.
--         Trigger KOMUT başına bir kez çalışır: biri bile uygunsuzsa
--         İKİSİ BİRDEN geri alınır (hata beklenir).
DELETE FROM Oduncler WHERE UyeID = 1;
GO

SELECT * FROM Oduncler WHERE UyeID = 1;    -- Beklenen: 2 satır, ikisi de duruyor

-- Test 3: İade edilmiş bir deneme kaydı ekleyip silelim (BAŞARILI)
INSERT INTO Oduncler (KitapID, UyeID, OduncTarihi, SonTeslimTarihi, IadeTarihi)
VALUES (8, 6, '2026-11-01', '2026-11-15', '2026-11-05');
DELETE FROM Oduncler WHERE UyeID = 6;
GO

SELECT * FROM Oduncler WHERE UyeID = 6;    -- Beklenen: boş

DISABLE TRIGGER trg_AcikOduncSilinmez ON Oduncler;
GO


/* =====================================================================
   BÖLÜM 9: INSTEAD OF TETİKLEYİCİSİ
   Asıl işlem (DELETE/INSERT/UPDATE) HİÇ YAPILMAZ; yerine trigger çalışır.
   AFTER'dan farkı: İşlem yapılıp geri alınmaz, baştan yapılmaz.
   ROLLBACK gerekmez.
   ===================================================================== */

-- 9.1  SENARYO (slayttaki "tür tablosundan hiçbir kayıt silinmesin" örneği):
--      Kategoriler tablosundan hiçbir kayıt silinemesin.
CREATE TRIGGER trg_KategoriSilinmez
ON Kategoriler
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR(N'Kategoriler silinemez! Lütfen yöneticiye başvurun.', 16, 1);
END;
GO

-- Test: Kitabı olmayan Psikoloji kategorisini silmeye çalış (hata beklenir)
DELETE FROM Kategoriler WHERE KategoriAdi = N'Psikoloji';
GO

SELECT * FROM Kategoriler WHERE KategoriAdi = N'Psikoloji';
-- Beklenen: 1 satır (silinmedi)

DISABLE TRIGGER trg_KategoriSilinmez ON Kategoriler;
GO


-- 9.2  SENARYO (slayttaki "öğrenci silinmesin, silindi alanı 1 olsun" örneği):
--      Üye silinmek istendiğinde gerçekten silinmesin, PASİF üyeler listesine alınsın.
--      Slaytta tabloya yeni sütun (ALTER TABLE) eklenmişti; burada mevcut tabloyu
--      değiştirmemek için ayrı bir PasifUyeler tablosu kullanıyoruz.
CREATE TRIGGER trg_UyePasifYap
ON Uyeler
INSTEAD OF DELETE
AS
BEGIN
    INSERT INTO PasifUyeler (UyeID)
    SELECT UyeID
    FROM deleted
    WHERE UyeID NOT IN (SELECT UyeID FROM PasifUyeler);   -- zaten pasifse ekleme

    PRINT N'Üye silinmedi, pasif listesine alındı.';
END;
GO

-- Test 1: Ece'yi (12) sil -> aslında silinmez, pasife alınır
DELETE FROM Uyeler WHERE UyeID = 12;

-- Test 2: Ayşe'yi (1) sil -> normalde ödünç kaydı olduğu için FOREIGN KEY
--         hatası verirdi; ama DELETE hiç yapılmadığı için hata da oluşmaz.
DELETE FROM Uyeler WHERE UyeID = 1;

SELECT COUNT(*) AS UyeSayisi FROM Uyeler;   -- Beklenen: 12 (kimse silinmedi)
SELECT * FROM PasifUyeler;                  -- Beklenen: UyeID 1 ve 12

-- Aktif üyeleri listeleme
SELECT Ad, Soyad
FROM Uyeler
WHERE UyeID NOT IN (SELECT UyeID FROM PasifUyeler);
-- Beklenen: 10 üye
GO

DELETE FROM PasifUyeler;                    -- deneme kayıtlarını temizle
DISABLE TRIGGER trg_UyePasifYap ON Uyeler;
GO


-- 9.3  SENARYO: VIEW üzerinde INSTEAD OF INSERT
--      Görevli kitap eklerken kategori ID'si yerine kategori ADINI yazsın.
--      İki tablodan oluşan view'a normalde INSERT yapılamaz; INSTEAD OF
--      trigger'ı veriyi doğru tabloya yerleştirir.
CREATE VIEW vw_KitapKategoriEkle
AS
SELECT k.ISBN, k.KitapAdi, k.YayinYili, k.SayfaSayisi, k.StokAdedi, kt.KategoriAdi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID;
GO

CREATE TRIGGER trg_VwKitapEkle
ON vw_KitapKategoriEkle
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO Kitaplar (ISBN, KitapAdi, YayinYili, SayfaSayisi, StokAdedi, KategoriID)
    SELECT i.ISBN, i.KitapAdi, i.YayinYili, i.SayfaSayisi, i.StokAdedi, kt.KategoriID
    FROM inserted AS i
    INNER JOIN Kategoriler AS kt ON i.KategoriAdi = kt.KategoriAdi;

    PRINT N'Kitap, kategori adına göre eklendi.';
END;
GO

-- Test: Kategori ADIYLA kitap ekle (sayfa sayısı örnek değerdir)
INSERT INTO vw_KitapKategoriEkle (ISBN, KitapAdi, YayinYili, SayfaSayisi, StokAdedi, KategoriAdi)
VALUES ('9780000000196', N'Sefiller', 1862, 1200, 2, N'Roman');

SELECT * FROM vw_KitapKategoriEkle WHERE ISBN = '9780000000196';
-- Beklenen: Sefiller | Roman

DELETE FROM Kitaplar WHERE ISBN = '9780000000196';
GO


/* =====================================================================
   BÖLÜM 10: İÇ İÇE (NESTED) VE RECURSIVE TRIGGER
   İç içe : Bir trigger başka bir tabloda işlem yapar, o tablonun trigger'ı
            da çalışır (zincirleme). Varsayılan olarak AÇIKTIR.
   Recursive: Trigger'ın kendini (doğrudan ya da dolaylı) tekrar tetiklemesi.
            Varsayılan olarak KAPALIDIR.
   - En fazla 32 seviye iç içe çalışabilir.
   - @@NESTLEVEL o anki seviyeyi gösterir.
   - Sonsuz döngüye girmemesi için mutlaka bir koşulla kontrol edilmelidir.
   ===================================================================== */

-- 10.1 SENARYO: Ödünç verilince trg_OduncVerildi, OduncHareketleri'ne kayıt ekler;
--      OduncHareketleri'ndeki trigger da çalışır (2. seviye).
CREATE TRIGGER trg_HareketSeviye
ON OduncHareketleri
AFTER INSERT
AS
BEGIN
    PRINT N'trg_HareketSeviye çalıştı. @@NESTLEVEL = ' + CAST(@@NESTLEVEL AS NVARCHAR(5));
END;
GO

ENABLE TRIGGER trg_OduncVerildi ON Oduncler;
GO

-- Test 1: Oduncler'e ekleme -> trg_OduncVerildi (1. seviye) -> trg_HareketSeviye (2. seviye)
INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)
VALUES (8, 6, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));
-- Beklenen mesaj: trg_HareketSeviye çalıştı. @@NESTLEVEL = 2

-- Test 2: OduncHareketleri'ne DOĞRUDAN ekleme -> yalnızca 1. seviye
INSERT INTO OduncHareketleri (Islem, OduncID, UyeID, KitapID)
VALUES (N'Deneme', 0, 0, 0);
-- Beklenen mesaj: trg_HareketSeviye çalıştı. @@NESTLEVEL = 1
GO

DELETE FROM Oduncler WHERE UyeID = 6;
DISABLE TRIGGER trg_OduncVerildi  ON Oduncler;
DISABLE TRIGGER trg_HareketSeviye ON OduncHareketleri;
GO

-- 10.2 AYARLAR (bilgi amaçlı; yorumu kaldırmadan önce öğretmeninize danışın)
--      Recursive trigger'ları veritabanı için açmak / kapatmak:
-- ALTER DATABASE KutuphaneDB SET RECURSIVE_TRIGGERS ON;
-- ALTER DATABASE KutuphaneDB SET RECURSIVE_TRIGGERS OFF;
--
--      İç içe tetiklenmeyi SUNUCU genelinde kapatmak (yalnızca ilk trigger çalışır):
-- EXEC sp_configure 'nested triggers', 0;
-- RECONFIGURE;
--      Tekrar açmak için 0 yerine 1 yazılır.
--
--      Recursive açıkken aynı tabloyu güncelleyen trigger'da sonsuz döngüyü önlemek:
--      IF NOT UPDATE(SutunAdi) ... veya IF @@NESTLEVEL > 1 RETURN;
GO


/* =====================================================================
   BÖLÜM 11: ALTER / DROP / PASİFLEŞTİRME - AKTİFLEŞTİRME
   ===================================================================== */

-- 11.1 Tüm trigger'ları ve durumlarını listelemek
SELECT t.name                    AS TriggerAdi,
       OBJECT_NAME(t.parent_id)  AS TabloVeyaView,
       t.is_instead_of_trigger   AS InsteadOf,
       t.is_disabled             AS Pasif
FROM sys.triggers AS t
ORDER BY TabloVeyaView, TriggerAdi;
-- Bu noktada trg_VwKitapEkle dışındakilerin hepsi Pasif = 1 olmalı.

-- 11.2 Bir tablonun trigger'larını görmek ve bir trigger'ın kodunu okumak
EXEC sp_helptrigger 'Oduncler';
EXEC sp_helptext 'trg_TekKitapKurali';
GO

-- 11.3 ALTER TRIGGER: Kural değişti - bir üye en fazla 2 kitap alabilsin.
ALTER TRIGGER trg_TekKitapKurali
ON Oduncler
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT o.UyeID
               FROM Oduncler AS o
               WHERE o.IadeTarihi IS NULL
                 AND o.UyeID IN (SELECT UyeID FROM inserted)
               GROUP BY o.UyeID
               HAVING COUNT(*) > 2)
    BEGIN
        RAISERROR(N'Bir üye aynı anda en fazla 2 kitap alabilir!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 11.4 ENABLE TRIGGER: Değiştirilen trigger'ı aktif yapıp test edelim
ENABLE TRIGGER trg_TekKitapKurali ON Oduncler;
GO

INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)        -- Burak 1. kitap: BAŞARILI
VALUES (8, 6, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));
INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)        -- Burak 2. kitap: BAŞARILI
VALUES (10, 6, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));
GO

INSERT INTO Oduncler (KitapID, UyeID, SonTeslimTarihi)        -- Burak 3. kitap: ENGELLENİR
VALUES (2, 6, DATEADD(DAY, 14, CAST(GETDATE() AS DATE)));
GO

SELECT * FROM Oduncler WHERE UyeID = 6;    -- Beklenen: 2 satır

DELETE FROM Oduncler WHERE UyeID = 6;
GO

-- 11.5 DISABLE TRIGGER: Pasif yapmanın iki yazımı (ikisi de aynı işi yapar)
DISABLE TRIGGER trg_TekKitapKurali ON Oduncler;
-- ALTER TABLE Oduncler DISABLE TRIGGER trg_TekKitapKurali;

-- Bir tablonun TÜM trigger'larını aktif / pasif yapmak
ENABLE  TRIGGER ALL ON Oduncler;
DISABLE TRIGGER ALL ON Oduncler;
-- ALTER TABLE Oduncler ENABLE  TRIGGER ALL;
-- ALTER TABLE Oduncler DISABLE TRIGGER ALL;
GO

-- 11.6 DROP TRIGGER: Trigger'ı silmek (tablo ve veriler etkilenmez)
DROP TRIGGER trg_KitapGuncelleGoster;
GO


/* =====================================================================
   BÖLÜM 12: TEMİZLİK
   Tüm trigger'lar, deneme view'ı ve log tabloları kaldırılır.
   Veritabanı bu betikten önceki haline döner.
   SSMS'te trigger'ları incelemek isterseniz, bu bölümü çalıştırmadan önce
   Tablo > Triggers klasörüne bakın.
   ===================================================================== */
DROP TRIGGER IF EXISTS trg_UyeEklendi;
DROP TRIGGER IF EXISTS trg_KitapGuncelleGoster;
DROP TRIGGER IF EXISTS trg_StokLog;
DROP TRIGGER IF EXISTS trg_OduncVerildi;
DROP TRIGGER IF EXISTS trg_IadeAlindi;
DROP TRIGGER IF EXISTS trg_TekKitapKurali;
DROP TRIGGER IF EXISTS trg_StokKontrol;
DROP TRIGGER IF EXISTS trg_RomanSayfaKontrol;
DROP TRIGGER IF EXISTS trg_ISBNDegismez;
DROP TRIGGER IF EXISTS trg_IadeTarihiKontrol;
DROP TRIGGER IF EXISTS trg_UyeArsiv;
DROP TRIGGER IF EXISTS trg_AcikOduncSilinmez;
DROP TRIGGER IF EXISTS trg_KategoriSilinmez;
DROP TRIGGER IF EXISTS trg_UyePasifYap;
DROP VIEW    IF EXISTS vw_KitapKategoriEkle;
DROP TABLE   IF EXISTS OduncHareketleri;
DROP TABLE   IF EXISTS StokDegisiklikLog;
DROP TABLE   IF EXISTS SilinenUyeler;
DROP TABLE   IF EXISTS PasifUyeler;
GO

-- Kontrol: Hiç trigger kalmamalı ve kayıt sayıları başlangıçtaki gibi olmalı
SELECT COUNT(*) AS KalanTrigger FROM sys.triggers;          -- 0
SELECT COUNT(*) AS Uye   FROM Uyeler;                       -- 12
SELECT COUNT(*) AS Kitap FROM Kitaplar;                     -- 18
SELECT COUNT(*) AS Odunc FROM Oduncler;                     -- 16
GO


/* =====================================================================
   BÖLÜM 13: ÖĞRENCİ ALIŞTIRMALARI
   Her alıştırmadan sonra trigger'ınızı pasif yapmayı ya da silmeyi unutmayın.
   ===================================================================== */
-- T1.  Kategoriler tablosuna kayıt eklendiğinde "Yeni kategori eklendi" mesajı
--      veren trg_KategoriEklendi trigger'ını yazın.
-- T2.  Yazarlar tablosunda bir yazar güncellendiğinde eski ve yeni adını
--      gösteren trigger'ı yazın (inserted / deleted).
-- T3.  Gelecek bir yılda (YayinYili > YEAR(GETDATE())) yayımlanmış kitap
--      eklenmesini engelleyen trigger'ı yazın.
-- T4.  Üyelerin e-posta adresi '@okul.edu.tr' ile bitmiyorsa kaydı engelleyen
--      trigger'ı yazın (LIKE kullanın).
-- T5.  Yazarlar tablosundan silinen yazarları SilinenYazarlar adında yeni bir
--      tabloya kaydeden trigger'ı yazın.
-- T6.  Kitaplar tablosunda stok 0'a düşürüldüğünde "Kitap tükendi, sipariş
--      verin" mesajı veren trigger'ı yazın.
-- T7.  KitapYazar tablosundan kayıt silinmesini INSTEAD OF ile engelleyin.
-- T8.  Son teslim tarihinin ödünç tarihinden 30 günden fazla sonra olmasını
--      engelleyen trigger'ı yazın (DATEDIFF kullanın).
