/* =====================================================================
   KÜTÜPHANE UYGULAMASI - JOIN YERİNE WHERE İLE TABLO BİRLEŞTİRME
   Her sorgu için önce JOIN'li hali (yorum satırı olarak), altında
   aynı sonucu veren WHERE'li hali verilmiştir.

   Kural: FROM'a tablolar virgülle yazılır, JOIN'deki ON koşulu
          WHERE'e taşınır. Birden fazla koşul AND ile bağlanır.

   ÖNEMLİ: INNER JOIN, WHERE ile birebir yazılabilir.
           LEFT JOIN ise WHERE ile yazılamaz (eski *= sözdizimi
           SQL Server'da artık desteklenmiyor). Bu yüzden LEFT JOIN'li
           sorgularda NOT EXISTS veya alt sorgu (subquery) kullanılmıştır.
   ===================================================================== */
USE KutuphaneDB;
GO


/* ---------------------------------------------------------------------
   1) Kitaplar ve yazarları (N:M, üç tablo)
   ---------------------------------------------------------------------
   JOIN'li hali:
   SELECT k.KitapAdi, y.Ad + N' ' + y.Soyad AS Yazar
   FROM Kitaplar AS k
   INNER JOIN KitapYazar AS ky ON k.KitapID = ky.KitapID
   INNER JOIN Yazarlar   AS y  ON ky.YazarID = y.YazarID;
   --------------------------------------------------------------------- */
SELECT k.KitapAdi, y.Ad + N' ' + y.Soyad AS Yazar
FROM Kitaplar AS k, KitapYazar AS ky, Yazarlar AS y
WHERE k.KitapID = ky.KitapID
  AND ky.YazarID = y.YazarID;
GO


/* ---------------------------------------------------------------------
   2) Şu an ödünçte olan kitaplar ve kimde oldukları
   ---------------------------------------------------------------------
   JOIN'li hali:
   SELECT u.Ad + N' ' + u.Soyad AS Uye, k.KitapAdi, o.SonTeslimTarihi
   FROM Oduncler AS o
   INNER JOIN Uyeler   AS u ON o.UyeID = u.UyeID
   INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
   WHERE o.IadeTarihi IS NULL;
   --------------------------------------------------------------------- */
SELECT u.Ad + N' ' + u.Soyad AS Uye, k.KitapAdi, o.SonTeslimTarihi
FROM Oduncler AS o, Uyeler AS u, Kitaplar AS k
WHERE o.UyeID = u.UyeID          -- birleştirme koşulu
  AND o.KitapID = k.KitapID      -- birleştirme koşulu
  AND o.IadeTarihi IS NULL;      -- filtre koşulu
GO


/* ---------------------------------------------------------------------
   3) Hiç ödünç almamış üyeler
   ---------------------------------------------------------------------
   JOIN'li hali (LEFT JOIN + IS NULL):
   SELECT u.Ad, u.Soyad
   FROM Uyeler AS u
   LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
   WHERE o.OduncID IS NULL;

   LEFT JOIN WHERE ile yazılamaz; iki eş değer yol:
   --------------------------------------------------------------------- */

-- 3a) NOT EXISTS ile: "Oduncler'de bu üyeye ait kayıt YOKSA getir"
SELECT u.Ad, u.Soyad
FROM Uyeler AS u
WHERE NOT EXISTS (SELECT 1
                  FROM Oduncler AS o
                  WHERE o.UyeID = u.UyeID);

-- 3b) NOT IN ile: "ID'si ödünç alanlar listesinde OLMAYAN üyeler"
SELECT Ad, Soyad
FROM Uyeler
WHERE UyeID NOT IN (SELECT UyeID FROM Oduncler);
GO


/* ---------------------------------------------------------------------
   4) Her kategoride kaç kitap var?
   ---------------------------------------------------------------------
   JOIN'li hali:
   SELECT kt.KategoriAdi, COUNT(k.KitapID) AS KitapSayisi
   FROM Kategoriler AS kt
   LEFT JOIN Kitaplar AS k ON kt.KategoriID = k.KategoriID
   GROUP BY kt.KategoriAdi
   ORDER BY KitapSayisi DESC;
   --------------------------------------------------------------------- */

-- 4a) WHERE ile (INNER JOIN mantığı): kitabı OLMAYAN kategoriler
--     (Psikoloji, Biyografi) listede GÖRÜNMEZ.
SELECT kt.KategoriAdi, COUNT(k.KitapID) AS KitapSayisi
FROM Kategoriler AS kt, Kitaplar AS k
WHERE kt.KategoriID = k.KategoriID
GROUP BY kt.KategoriAdi
ORDER BY KitapSayisi DESC;

-- 4b) LEFT JOIN ile birebir aynı sonuç (0 kitaplı kategoriler dahil):
--     SELECT içinde alt sorgu, alt sorgunun içinde WHERE.
SELECT kt.KategoriAdi,
       (SELECT COUNT(*)
        FROM Kitaplar AS k
        WHERE k.KategoriID = kt.KategoriID) AS KitapSayisi
FROM Kategoriler AS kt
ORDER BY KitapSayisi DESC;
GO


/* ---------------------------------------------------------------------
   5) 1'den fazla ödünç almış üyeler (HAVING)
   ---------------------------------------------------------------------
   JOIN'li hali:
   SELECT u.Ad, u.Soyad, COUNT(*) AS OduncSayisi
   FROM Oduncler AS o
   INNER JOIN Uyeler AS u ON o.UyeID = u.UyeID
   GROUP BY u.Ad, u.Soyad
   HAVING COUNT(*) > 1;
   --------------------------------------------------------------------- */
SELECT u.Ad, u.Soyad, COUNT(*) AS OduncSayisi
FROM Oduncler AS o, Uyeler AS u
WHERE o.UyeID = u.UyeID
GROUP BY u.Ad, u.Soyad
HAVING COUNT(*) > 1;
-- Not: WHERE gruplamadan ÖNCE satırları süzer,
--      HAVING gruplamadan SONRA grupları süzer.
GO


/* ---------------------------------------------------------------------
   6) Teslim tarihi geçmiş kitaplar ve gecikme günü
   ---------------------------------------------------------------------
   JOIN'li hali:
   SELECT u.Ad + N' ' + u.Soyad AS Uye, k.KitapAdi,
          DATEDIFF(DAY, o.SonTeslimTarihi, GETDATE()) AS GecikmeGun
   FROM Oduncler AS o
   INNER JOIN Uyeler   AS u ON o.UyeID = u.UyeID
   INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
   WHERE o.IadeTarihi IS NULL AND o.SonTeslimTarihi < CAST(GETDATE() AS DATE);
   --------------------------------------------------------------------- */
SELECT u.Ad + N' ' + u.Soyad AS Uye, k.KitapAdi,
       DATEDIFF(DAY, o.SonTeslimTarihi, GETDATE()) AS GecikmeGun
FROM Oduncler AS o, Uyeler AS u, Kitaplar AS k
WHERE o.UyeID = u.UyeID
  AND o.KitapID = k.KitapID
  AND o.IadeTarihi IS NULL
  AND o.SonTeslimTarihi < CAST(GETDATE() AS DATE)
ORDER BY GecikmeGun DESC;
GO


/* ---------------------------------------------------------------------
   DİKKAT - EN SIK YAPILAN HATA:
   Virgülle tablo yazıp WHERE'de birleştirme koşulunu UNUTMAK.
   Bu durumda her satır diğer tablonun her satırıyla eşleşir
   (Kartezyen çarpım / CROSS JOIN). Deneyin:
   --------------------------------------------------------------------- */
SELECT COUNT(*) AS SatirSayisi        -- 16 ödünç x 12 üye = 192 satır!
FROM Oduncler AS o, Uyeler AS u;
GO
