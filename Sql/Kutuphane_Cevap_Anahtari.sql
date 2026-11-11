/* =====================================================================
   KÜTÜPHANE UYGULAMASI - CEVAP ANAHTARI (ÖĞRETMEN İÇİN)
   Önce Kutuphane_Uygulama.sql dosyasının 1-3. adımları çalıştırılmış olmalı.
   ===================================================================== */
USE KutuphaneDB;
GO

-- A1. Üyeler soyada göre A→Z
SELECT Ad, Soyad, Eposta
FROM Uyeler
ORDER BY Soyad ASC;

-- A2. 2000'den önce yayımlanan kitaplar
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili < 2000;

-- A3. Türkiye dışındaki yazarlar
SELECT Ad, Soyad, Ulke
FROM Yazarlar
WHERE Ulke <> N'Türkiye';

-- A4. Stoku 2 veya daha fazla olan kitaplar
SELECT KitapAdi, StokAdedi
FROM Kitaplar
WHERE StokAdedi >= 2;

-- B5. Orhan Pamuk'un kitapları
SELECT k.KitapAdi, k.YayinYili
FROM Kitaplar AS k
INNER JOIN KitapYazar AS ky ON k.KitapID = ky.KitapID
INNER JOIN Yazarlar   AS y  ON ky.YazarID = y.YazarID
WHERE y.Ad = N'Orhan' AND y.Soyad = N'Pamuk';

-- B6. Kitap adı, kategori adı ve yazar
SELECT k.KitapAdi, kt.KategoriAdi, y.Ad + N' ' + y.Soyad AS Yazar
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
INNER JOIN KitapYazar  AS ky ON k.KitapID = ky.KitapID
INNER JOIN Yazarlar    AS y  ON ky.YazarID = y.YazarID
ORDER BY k.KitapAdi;

-- B7. Ayşe Yılmaz'ın ödünç aldığı kitaplar
SELECT k.KitapAdi, o.OduncTarihi, o.SonTeslimTarihi, o.IadeTarihi
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
WHERE u.Ad = N'Ayşe' AND u.Soyad = N'Yılmaz'
ORDER BY o.OduncTarihi;

-- B8. Hiç ödünç verilmemiş kitaplar
-- Beklenen (ilk veride): Kırmızı Saçlı Kadın, Memleketimden İnsan Manzaraları
-- Beklenen (Kutuphane_Veri_Ekleme.sql ile): yukarıdakiler + Ben, Robot; Devlet; Huzur
SELECT k.KitapAdi
FROM Kitaplar AS k
LEFT JOIN Oduncler AS o ON k.KitapID = o.KitapID
WHERE o.OduncID IS NULL;

-- C9. Her yazarın kitap sayısı
SELECT y.Ad + N' ' + y.Soyad AS Yazar, COUNT(ky.KitapID) AS KitapSayisi
FROM Yazarlar AS y
LEFT JOIN KitapYazar AS ky ON y.YazarID = ky.YazarID
GROUP BY y.Ad, y.Soyad
ORDER BY KitapSayisi DESC;

-- C10. En çok ödünç alınan kitap (beklenen: Kürk Mantolu Madonna, 3 kez)
SELECT TOP 1 k.KitapAdi, COUNT(*) AS OduncSayisi
FROM Oduncler AS o
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
GROUP BY k.KitapAdi
ORDER BY OduncSayisi DESC;

-- D11. Yeni üye + 14 günlük ödünç kaydı (öğrenci kendi bilgilerini yazar)
INSERT INTO Uyeler (Ad, Soyad, Eposta)
VALUES (N'Öğrenci', N'Adı', N'ogrenci@okul.edu.tr');

INSERT INTO Oduncler (KitapID, UyeID, OduncTarihi, SonTeslimTarihi)
VALUES (
    (SELECT KitapID FROM Kitaplar WHERE KitapAdi = N'Küçük Prens'),
    SCOPE_IDENTITY(),                                   -- az önce eklenen üyenin ID'si
    CAST(GETDATE() AS DATE),
    DATEADD(DAY, 14, CAST(GETDATE() AS DATE))
);
-- Alternatif (daha anlaşılır): UyeID'yi SELECT ile e-postadan bulmak
-- (SELECT UyeID FROM Uyeler WHERE Eposta = N'ogrenci@okul.edu.tr')

-- D12. Elif Şahin'in e-postasını güncelleme
UPDATE Uyeler
SET Eposta = N'elif.sahin@okul.edu.tr'
WHERE Ad = N'Elif' AND Soyad = N'Şahin';

/* E. KISIT TESTİ - beklenen sonuçlar
   8.1 UNIQUE      : Aynı ISBN ikinci kez eklenemez (Msg 2627, UNIQUE KEY ihlali)
   8.2 FOREIGN KEY : KategoriID = 99 Kategoriler'de yok (Msg 547, FK_Kitaplar_Kategoriler)
   8.3 CHECK       : StokAdedi negatif olamaz (Msg 547, CHECK kısıtı)
   8.4 FOREIGN KEY : Ödünç kaydı olan üye silinemez (Msg 547, FK_Oduncler_Uyeler)
   8.5 NOT NULL    : Ad alanı boş geçilemez (Msg 515)
*/
