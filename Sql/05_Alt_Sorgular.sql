/* =====================================================================
   KÜTÜPHANE UYGULAMASI - İÇ İÇE SELECT (ALT SORGU / SUBQUERY) ÖRNEKLERİ
     Bölüm 1 : Tek değer döndüren alt sorgular  (=, >, <)
     Bölüm 2 : Birden fazla seviyeli alt sorgular
     Bölüm 3 : Çok değer döndüren alt sorgular  (IN, NOT IN)
     Bölüm 4 : EXISTS ve NOT EXISTS
     Bölüm 5 : SELECT içinde alt sorgu
     Bölüm 6 : FROM içinde alt sorgu (türetilmiş tablo)
     Bölüm 7 : HAVING içinde alt sorgu
     Bölüm 8 : İlişkili (correlated) alt sorgular
     Bölüm 9 : ANY ve ALL (bonus)
     Bölüm 10: UPDATE ve DELETE içinde alt sorgu
     Bölüm 11: Alt sorgu mu, JOIN mi? / Sık yapılan hatalar
     Bölüm 12: Öğrenci alıştırmaları

   Ön koşul: 01_Veri_Ekleme.sql çalıştırılmış olmalı.
   Her sorgunun altında, o veriyle BEKLENEN sonuç yazılıdır.

   ALT SORGU NEDİR?
   Bir SELECT'in içine parantez içinde yazılan başka bir SELECT'tir.
   SQL önce İÇTEKİ sorguyu çalıştırır, sonucunu DIŞTAKİ sorguda kullanır.

       SELECT KitapAdi FROM Kitaplar
       WHERE SayfaSayisi = (SELECT MAX(SayfaSayisi) FROM Kitaplar);
                           \_______ iç sorgu: 687 _______/

   İPUCU: Alt sorguyu önce TEK BAŞINA çalıştırın, ne döndürdüğünü görün,
          sonra dış sorguya yerleştirin.
   ===================================================================== */
USE KutuphaneDB;
GO


/* =====================================================================
   BÖLÜM 1: TEK DEĞER DÖNDÜREN ALT SORGULAR
   İç sorgu TEK bir değer (bir satır, bir sütun) döndürür.
   Bu yüzden =, >, <, >=, <=, <> ile kullanılabilir.
   Genellikle MAX, MIN, AVG, SUM, COUNT gibi fonksiyonlarla yazılır.
   ===================================================================== */

-- 1.1  SENARYO: Kütüphanenin en kalın kitabı hangisi?
--      Önce iç sorguyu tek başına çalıştırın:
SELECT MAX(SayfaSayisi) FROM Kitaplar;          -- 687

--      Sonra dış sorguya yerleştirin:
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi = (SELECT MAX(SayfaSayisi) FROM Kitaplar);
-- Beklenen: Suç ve Ceza, 687

-- 1.2  SENARYO: En ince kitap hangisi?
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi = (SELECT MIN(SayfaSayisi) FROM Kitaplar);
-- Beklenen: Küçük Prens, 112

-- 1.3  SENARYO: Kütüphanedeki en eski ve en yeni kitaplar
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili = (SELECT MIN(YayinYili) FROM Kitaplar);
-- Beklenen: Suç ve Ceza, 1866

SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili = (SELECT MAX(YayinYili) FROM Kitaplar);
-- Beklenen: Kırmızı Saçlı Kadın, 2016

-- 1.4  SENARYO: Ortalamadan kalın kitapları raflarda ayrı bir bölüme koyacağız.
SELECT AVG(SayfaSayisi) FROM Kitaplar;          -- 328

SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi > (SELECT AVG(SayfaSayisi) FROM Kitaplar)
ORDER BY SayfaSayisi DESC;
-- Beklenen: 9 kitap (Suç ve Ceza 687 ... 1984 352)

-- 1.5  SENARYO: Ortalama yayın yılından SONRA yayımlanan "yeni" kitaplar
SELECT AVG(YayinYili) FROM Kitaplar;            -- 1962  (NULL olan Devlet hesaba katılmaz)

SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili > (SELECT AVG(YayinYili) FROM Kitaplar)
ORDER BY YayinYili;
-- Beklenen: 7 kitap - Memleketimden İnsan Manzaraları (1966), Kozmos (1980),
--           Zamanın Kısa Tarihi (1988), Benim Adım Kırmızı (1998),
--           Zamanın Daha Kısa Tarihi (2005), Osmanlı'yı Yeniden Keşfetmek (2006),
--           Kırmızı Saçlı Kadın (2016)

-- 1.6  SENARYO: "Kürk Mantolu Madonna"yı seven bir üyeye aynı kategoriden
--      başka kitaplar önerelim. (Kategori ID'sini bilmiyoruz, alt sorgu bulsun.)
SELECT KitapAdi
FROM Kitaplar
WHERE KategoriID = (SELECT KategoriID FROM Kitaplar
                    WHERE KitapAdi = N'Kürk Mantolu Madonna')
  AND KitapAdi <> N'Kürk Mantolu Madonna';
-- Beklenen: 7 roman (İnce Memed, Kırmızı Saçlı Kadın, Benim Adım Kırmızı,
--           Suç ve Ceza, Hayvan Çiftliği, Saatleri Ayarlama Enstitüsü, Huzur)

-- 1.7  SENARYO: "Küçük Prens" ile aynı yıl yayımlanmış diğer kitaplar
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili = (SELECT YayinYili FROM Kitaplar WHERE KitapAdi = N'Küçük Prens')
  AND KitapAdi <> N'Küçük Prens';
-- Beklenen: Kürk Mantolu Madonna, 1943

-- 1.8  SENARYO: "1984" kitabından daha kalın kitaplar
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi > (SELECT SayfaSayisi FROM Kitaplar WHERE KitapAdi = N'1984');
-- Beklenen: 352'den kalın 8 kitap

-- 1.9  SENARYO: Kütüphaneye ilk kayıt olan üye(ler)
SELECT Ad, Soyad, KayitTarihi
FROM Uyeler
WHERE KayitTarihi = (SELECT MIN(KayitTarihi) FROM Uyeler);
-- Beklenen: Ayşe Yılmaz, Mehmet Demir (2026-09-08)
-- Not: Alt sorgu tek değer döndürür ama dış sorgu birden çok satır getirebilir.

-- 1.10 SENARYO: En son yapılan ödünç işlemi
SELECT OduncID, KitapID, UyeID, OduncTarihi
FROM Oduncler
WHERE OduncTarihi = (SELECT MAX(OduncTarihi) FROM Oduncler);
-- Beklenen: OduncID 16, KitapID 17, UyeID 4, 2026-10-08
GO


/* =====================================================================
   BÖLÜM 2: BİRDEN FAZLA SEVİYELİ ALT SORGULAR
   Bir alt sorgunun içine başka bir alt sorgu yazılabilir.
   SQL en İÇTEKİNDEN başlayarak dışarıya doğru çalışır.
   ===================================================================== */

-- 2.1  SENARYO: Roman kategorisindeki kitaplar (ID yerine kategori ADIYLA)
SELECT KitapAdi
FROM Kitaplar
WHERE KategoriID = (SELECT KategoriID FROM Kategoriler WHERE KategoriAdi = N'Roman');
-- Beklenen: 8 kitap

-- 2.2  SENARYO: Romanlar arasında, ROMAN ortalamasından kalın olanlar
--      3 seviye:  (1) Roman'ın ID'si  ->  (2) romanların ortalaması  ->  (3) liste
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE KategoriID = (SELECT KategoriID FROM Kategoriler WHERE KategoriAdi = N'Roman')
  AND SayfaSayisi > (SELECT AVG(SayfaSayisi)
                     FROM Kitaplar
                     WHERE KategoriID = (SELECT KategoriID FROM Kategoriler
                                         WHERE KategoriAdi = N'Roman'));
-- Beklenen: 5 kitap (roman ortalaması 365)
--           İnce Memed, Benim Adım Kırmızı, Suç ve Ceza,
--           Saatleri Ayarlama Enstitüsü, Huzur

-- 2.3  SENARYO: Bilim kategorisinin en kalın kitabı
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi = (SELECT MAX(SayfaSayisi)
                     FROM Kitaplar
                     WHERE KategoriID = (SELECT KategoriID FROM Kategoriler
                                         WHERE KategoriAdi = N'Bilim'))
  AND KategoriID = (SELECT KategoriID FROM Kategoriler WHERE KategoriAdi = N'Bilim');
-- Beklenen: Kozmos, 396
-- Not: Son satırdaki koşul olmasa, başka kategoride 396 sayfalık kitap
--      olsaydı o da gelirdi.
GO


/* =====================================================================
   BÖLÜM 3: ÇOK DEĞER DÖNDÜREN ALT SORGULAR (IN, NOT IN)
   İç sorgu bir LİSTE döndürür. = yerine IN veya NOT IN kullanılır.
   ===================================================================== */

-- 3.1  SENARYO: En az bir kez ödünç alınmış kitaplar
SELECT KitapID FROM Oduncler;                   -- önce listeyi görün

SELECT KitapAdi
FROM Kitaplar
WHERE KitapID IN (SELECT KitapID FROM Oduncler);
-- Beklenen: 13 kitap (aynı kitap birden çok kez ödünç alınsa da bir kez gelir)

-- 3.2  SENARYO: Hiç ödünç alınmamış kitaplar (vitrine koyup tanıtalım)
SELECT KitapAdi
FROM Kitaplar
WHERE KitapID NOT IN (SELECT KitapID FROM Oduncler);
-- Beklenen: Kırmızı Saçlı Kadın, Memleketimden İnsan Manzaraları,
--           Ben, Robot, Devlet, Huzur

-- 3.3  SENARYO: Hiç ödünç almamış üyelere hatırlatma e-postası gönderilecek
SELECT Ad, Soyad, Eposta
FROM Uyeler
WHERE UyeID NOT IN (SELECT UyeID FROM Oduncler);
-- Beklenen: Burak Çelik, Ece Polat

-- 3.4  SENARYO: En az bir kitabı iade etmiş üyeler
SELECT Ad, Soyad
FROM Uyeler
WHERE UyeID IN (SELECT UyeID FROM Oduncler WHERE IadeTarihi IS NOT NULL);
-- Beklenen: Ayşe, Mehmet, Zeynep, Elif, Selin

-- 3.5  SENARYO: Orhan Pamuk'un kitapları (2 seviye)
SELECT KitapAdi
FROM Kitaplar
WHERE KitapID IN (SELECT KitapID FROM KitapYazar
                  WHERE YazarID = (SELECT YazarID FROM Yazarlar
                                   WHERE Ad = N'Orhan' AND Soyad = N'Pamuk'));
-- Beklenen: Kırmızı Saçlı Kadın, Benim Adım Kırmızı

-- 3.6  SENARYO: Türk yazarların kitapları (2 seviye, ikisi de IN)
SELECT KitapAdi
FROM Kitaplar
WHERE KitapID IN (SELECT KitapID FROM KitapYazar
                  WHERE YazarID IN (SELECT YazarID FROM Yazarlar
                                    WHERE Ulke = N'Türkiye'));
-- Beklenen: 8 kitap

-- 3.7  SENARYO: Roman okuyan üyeler (3 seviye)
--      Roman ID'si -> roman kitapları -> o kitapları ödünç alanlar -> üyeler
SELECT Ad, Soyad
FROM Uyeler
WHERE UyeID IN (SELECT UyeID FROM Oduncler
                WHERE KitapID IN (SELECT KitapID FROM Kitaplar
                                  WHERE KategoriID = (SELECT KategoriID FROM Kategoriler
                                                      WHERE KategoriAdi = N'Roman')));
-- Beklenen: 7 üye - Ayşe, Mehmet, Zeynep, Can, Elif, Selin, Oğuz

-- 3.8  SENARYO: Hiç kitabı olmayan kategoriler (satın alma listesine eklenecek)
SELECT KategoriAdi
FROM Kategoriler
WHERE KategoriID NOT IN (SELECT KategoriID FROM Kitaplar);
-- Beklenen: Psikoloji, Biyografi

-- 3.9  SENARYO: Kitapları hiç okunmamış yazarlar (3 seviye)
SELECT Ad, Soyad
FROM Yazarlar
WHERE YazarID NOT IN (SELECT YazarID FROM KitapYazar
                      WHERE KitapID IN (SELECT KitapID FROM Oduncler));
-- Beklenen: Nazım Hikmet, Isaac Asimov, Platon

-- 3.10 DİKKAT - NOT IN ve NULL TUZAĞI
--      Senaryo: Roman ve Felsefe kitaplarıyla AYNI YILDA yayımlanmamış kitaplar.
--      Felsefe'deki "Devlet"in yayın yılı NULL. İç sorgunun listesinde NULL
--      olduğu için NOT IN hiçbir satır için DOĞRU olamaz:
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili NOT IN (SELECT YayinYili FROM Kitaplar WHERE KategoriID IN (1, 6));
-- Beklenen: SONUÇ YOK!

--      Çözüm: İç sorgudan NULL'ları çıkarın.
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili NOT IN (SELECT YayinYili FROM Kitaplar
                        WHERE KategoriID IN (1, 6) AND YayinYili IS NOT NULL);
-- Beklenen: 7 kitap - Zamanın Kısa Tarihi, Zamanın Daha Kısa Tarihi,
--           Osmanlı'yı Yeniden Keşfetmek, Memleketimden İnsan Manzaraları,
--           Doğu Ekspresinde Cinayet, Ben, Robot, Kozmos
-- KURAL: NOT IN kullanırken iç sorguda NULL olmadığından emin olun
--        ya da NOT EXISTS kullanın (Bölüm 4).
GO


/* =====================================================================
   BÖLÜM 4: EXISTS ve NOT EXISTS
   EXISTS   : İç sorgu EN AZ BİR satır döndürürse DOĞRU
   NOT EXISTS: İç sorgu HİÇ satır döndürmezse DOĞRU
   İç sorgu, dış sorgudaki satıra bağlıdır (o.UyeID = u.UyeID gibi).
   SELECT 1 yazılır, çünkü önemli olan satırın VAR olup olmadığıdır.
   NULL tuzağı yoktur.
   ===================================================================== */

-- 4.1  SENARYO: En az bir kez ödünç alınmış kitaplar (3.1'in EXISTS hali)
SELECT k.KitapAdi
FROM Kitaplar AS k
WHERE EXISTS (SELECT 1 FROM Oduncler AS o WHERE o.KitapID = k.KitapID);
-- Beklenen: 13 kitap

-- 4.2  SENARYO: Hiç ödünç almamış üyeler (3.3'ün NOT EXISTS hali)
SELECT u.Ad, u.Soyad
FROM Uyeler AS u
WHERE NOT EXISTS (SELECT 1 FROM Oduncler AS o WHERE o.UyeID = u.UyeID);
-- Beklenen: Burak Çelik, Ece Polat

-- 4.3  SENARYO: En az bir kitabı olan kategoriler
SELECT kt.KategoriAdi
FROM Kategoriler AS kt
WHERE EXISTS (SELECT 1 FROM Kitaplar AS k WHERE k.KategoriID = kt.KategoriID);
-- Beklenen: 8 kategori (Psikoloji ve Biyografi hariç)

-- 4.4  SENARYO: Eylül'de kitap alıp HÂLÂ iade etmemiş üyeler
SELECT u.Ad, u.Soyad
FROM Uyeler AS u
WHERE EXISTS (SELECT 1 FROM Oduncler AS o
              WHERE o.UyeID = u.UyeID
                AND o.OduncTarihi BETWEEN '2026-09-01' AND '2026-09-30'
                AND o.IadeTarihi IS NULL);
-- Beklenen: Ayşe, Mehmet, Zeynep, Can, Emre, Deniz

-- 4.5  SENARYO: Hiç ödünç verilmemiş Roman kitapları
SELECT k.KitapAdi
FROM Kitaplar AS k
WHERE k.KategoriID = 1
  AND NOT EXISTS (SELECT 1 FROM Oduncler AS o WHERE o.KitapID = k.KitapID);
-- Beklenen: Kırmızı Saçlı Kadın, Huzur

-- 4.6  3.10'daki NULL tuzağı NOT EXISTS ile oluşmaz:
SELECT k.KitapAdi, k.YayinYili
FROM Kitaplar AS k
WHERE NOT EXISTS (SELECT 1 FROM Kitaplar AS r
                  WHERE r.KategoriID IN (1, 6)
                    AND r.YayinYili = k.YayinYili);
-- Beklenen: 3.10'daki 7 kitap + Devlet (yılı NULL, hiçbir yılla eşleşmez)
GO


/* =====================================================================
   BÖLÜM 5: SELECT İÇİNDE ALT SORGU
   Alt sorgu bir SÜTUN gibi kullanılır. Her satır için TEK değer döndürmelidir.
   ===================================================================== */

-- 5.1  SENARYO: Her kitabın sayfa sayısını genel ortalamayla karşılaştırma
SELECT KitapAdi,
       SayfaSayisi,
       (SELECT AVG(SayfaSayisi) FROM Kitaplar)               AS Ortalama,
       SayfaSayisi - (SELECT AVG(SayfaSayisi) FROM Kitaplar) AS Fark
FROM Kitaplar
ORDER BY Fark DESC;
-- Örnek: Suç ve Ceza 687 | 328 | 359 ...  Küçük Prens 112 | 328 | -216

-- 5.2  SENARYO: Her kitabın toplam stok içindeki payı (%)
SELECT KitapAdi,
       StokAdedi,
       CAST(StokAdedi * 100.0 / (SELECT SUM(StokAdedi) FROM Kitaplar)
            AS DECIMAL(5,1)) AS StokYuzdesi
FROM Kitaplar
ORDER BY StokYuzdesi DESC;
-- Örnek: Küçük Prens 4 / 35 = 11.4

-- 5.3  SENARYO: Her kategoride kaç kitap var? (ilişkili alt sorgu)
SELECT kt.KategoriAdi,
       (SELECT COUNT(*) FROM Kitaplar AS k
        WHERE k.KategoriID = kt.KategoriID) AS KitapSayisi
FROM Kategoriler AS kt
ORDER BY KitapSayisi DESC;
-- Beklenen: 10 satır - Roman 8, Bilim 3, Bilim Kurgu 2, ... Psikoloji 0, Biyografi 0

-- 5.4  SENARYO: Üye karnesi - her üyenin toplam ve açık ödünç sayısı
SELECT u.Ad,
       u.Soyad,
       (SELECT COUNT(*) FROM Oduncler AS o
        WHERE o.UyeID = u.UyeID)                          AS ToplamOdunc,
       (SELECT COUNT(*) FROM Oduncler AS o
        WHERE o.UyeID = u.UyeID AND o.IadeTarihi IS NULL) AS ElindekiKitap
FROM Uyeler AS u
ORDER BY ToplamOdunc DESC;
-- Beklenen: 12 satır. Can 2 | 2, Burak 0 | 0 ...

-- 5.5  SENARYO: Her kitap kaç kez ödünç alındı?
SELECT k.KitapAdi,
       (SELECT COUNT(*) FROM Oduncler AS o
        WHERE o.KitapID = k.KitapID) AS OduncSayisi
FROM Kitaplar AS k
ORDER BY OduncSayisi DESC;
-- Beklenen: Kürk Mantolu Madonna 3, 1984 2, diğerleri 1 veya 0

-- 5.6  SENARYO: Her kitabın kategori adı (JOIN yerine alt sorgu)
SELECT k.KitapAdi,
       (SELECT kt.KategoriAdi FROM Kategoriler AS kt
        WHERE kt.KategoriID = k.KategoriID) AS KategoriAdi
FROM Kitaplar AS k;
-- Beklenen: 18 satır (INNER JOIN ile aynı sonuç)
GO


/* =====================================================================
   BÖLÜM 6: FROM İÇİNDE ALT SORGU (TÜRETİLMİŞ TABLO)
   Alt sorgunun sonucu geçici bir TABLO gibi kullanılır.
   KURAL: FROM'daki alt sorguya mutlaka bir takma ad verilmelidir (AS t).
   ===================================================================== */

-- 6.1  SENARYO: Bir kategoride ortalama kaç kitap var?
--      Önce kategorilerin kitap sayılarını bulup, sonra onların ortalamasını alıyoruz.
SELECT AVG(KitapSayisi * 1.0) AS KategoriBasinaOrtalama
FROM (SELECT KategoriID, COUNT(*) AS KitapSayisi
      FROM Kitaplar
      GROUP BY KategoriID) AS t;
-- Beklenen: 2.25  (18 kitap / kitabı olan 8 kategori)

-- 6.2  SENARYO: 2 kitap ödünç almış üyelerin adları
SELECT u.Ad, u.Soyad, t.OduncSayisi
FROM (SELECT UyeID, COUNT(*) AS OduncSayisi
      FROM Oduncler
      GROUP BY UyeID) AS t
INNER JOIN Uyeler AS u ON t.UyeID = u.UyeID
WHERE t.OduncSayisi = 2;
-- Beklenen: Ayşe, Mehmet, Zeynep, Can, Elif, Selin

-- 6.3  SENARYO: Kategori özetlerinden yalnızca stoğu 4 ve üzeri olanlar
SELECT kt.KategoriAdi, t.ToplamStok
FROM (SELECT KategoriID, SUM(StokAdedi) AS ToplamStok
      FROM Kitaplar
      GROUP BY KategoriID) AS t
INNER JOIN Kategoriler AS kt ON t.KategoriID = kt.KategoriID
WHERE t.ToplamStok >= 4
ORDER BY t.ToplamStok DESC;
-- Beklenen: Roman 16, Bilim 5, Çocuk 4, Bilim Kurgu 4
GO


/* =====================================================================
   BÖLÜM 7: HAVING İÇİNDE ALT SORGU
   Grupları, alt sorgudan gelen bir değerle karşılaştırırız.
   ===================================================================== */

-- 7.1  SENARYO: Ortalama sayfa sayısı, kütüphane ortalamasından yüksek kategoriler
SELECT kt.KategoriAdi, AVG(k.SayfaSayisi) AS OrtalamaSayfa
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
HAVING AVG(k.SayfaSayisi) > (SELECT AVG(SayfaSayisi) FROM Kitaplar);
-- Beklenen: Şiir 480, Felsefe 400, Roman 365  (genel ortalama 328)

-- 7.2  SENARYO: Ortalama kategoriden (2.25 kitap) daha çok kitabı olan kategoriler
SELECT kt.KategoriAdi, COUNT(*) AS KitapSayisi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi
HAVING COUNT(*) > (SELECT AVG(KitapSayisi * 1.0)
                   FROM (SELECT COUNT(*) AS KitapSayisi
                         FROM Kitaplar
                         GROUP BY KategoriID) AS t);
-- Beklenen: Roman 8, Bilim 3

-- 7.3  SENARYO: En çok ödünç alınan kitap(lar)
SELECT k.KitapAdi, COUNT(*) AS OduncSayisi
FROM Oduncler AS o
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
GROUP BY k.KitapAdi
HAVING COUNT(*) = (SELECT MAX(Sayi)
                   FROM (SELECT COUNT(*) AS Sayi
                         FROM Oduncler
                         GROUP BY KitapID) AS t);
-- Beklenen: Kürk Mantolu Madonna, 3
-- Not: TOP 1 eşitlik durumunda yalnızca birini gösterir; bu yöntem
--      aynı sayıda ödünç alınan TÜM kitapları gösterir.

-- 7.4  SENARYO: En çok ödünç alan üye(ler) - eşitlik varsa hepsi
SELECT u.Ad, u.Soyad, COUNT(*) AS OduncSayisi
FROM Oduncler AS o
INNER JOIN Uyeler AS u ON o.UyeID = u.UyeID
GROUP BY u.Ad, u.Soyad
HAVING COUNT(*) = (SELECT MAX(Sayi)
                   FROM (SELECT COUNT(*) AS Sayi
                         FROM Oduncler
                         GROUP BY UyeID) AS t);
-- Beklenen: 6 üye (2'şer ödünç) - Ayşe, Mehmet, Zeynep, Can, Elif, Selin
GO


/* =====================================================================
   BÖLÜM 8: İLİŞKİLİ (CORRELATED) ALT SORGULAR
   İç sorgu, dış sorgudaki SATIRA bağlıdır ve her satır için yeniden çalışır.
   Tablo iki kez kullanıldığı için takma adlar (k1, k2) şarttır.

   İlişkisiz : (SELECT AVG(SayfaSayisi) FROM Kitaplar)            -> tek sefer
   İlişkili  : (SELECT AVG(SayfaSayisi) FROM Kitaplar AS k2
                WHERE k2.KategoriID = k1.KategoriID)              -> her satırda
   ===================================================================== */

-- 8.1  SENARYO: KENDİ kategorisinin ortalamasından kalın kitaplar
SELECT k1.KitapAdi, k1.KategoriID, k1.SayfaSayisi
FROM Kitaplar AS k1
WHERE k1.SayfaSayisi > (SELECT AVG(k2.SayfaSayisi)
                        FROM Kitaplar AS k2
                        WHERE k2.KategoriID = k1.KategoriID)
ORDER BY k1.KategoriID;
-- Beklenen: 7 kitap
--   Roman (ort. 365): İnce Memed, Benim Adım Kırmızı, Suç ve Ceza,
--                     Saatleri Ayarlama Enstitüsü, Huzur
--   Bilim (ort. 276): Kozmos
--   Bilim Kurgu (ort. 312): 1984
-- Tek kitaplı kategorilerde kitap kendi ortalamasına EŞİT olduğu için gelmez.

-- 8.2  SENARYO: Her kategorinin EN KALIN kitabı
SELECT k1.KitapAdi, k1.KategoriID, k1.SayfaSayisi
FROM Kitaplar AS k1
WHERE k1.SayfaSayisi = (SELECT MAX(k2.SayfaSayisi)
                        FROM Kitaplar AS k2
                        WHERE k2.KategoriID = k1.KategoriID)
ORDER BY k1.KategoriID;
-- Beklenen: 8 satır - Suç ve Ceza, Kozmos, Osmanlı'yı Yeniden Keşfetmek,
--           Memleketimden İnsan Manzaraları, Küçük Prens, Devlet, 1984,
--           Doğu Ekspresinde Cinayet

-- 8.3  SENARYO: Her kategorinin EN ESKİ kitabı
SELECT k1.KitapAdi, k1.KategoriID, k1.YayinYili
FROM Kitaplar AS k1
WHERE k1.YayinYili = (SELECT MIN(k2.YayinYili)
                      FROM Kitaplar AS k2
                      WHERE k2.KategoriID = k1.KategoriID)
ORDER BY k1.KategoriID;
-- Beklenen: 7 satır. Felsefe (Devlet) YOK, çünkü yılı NULL ve
--           NULL = NULL karşılaştırması DOĞRU sayılmaz.

-- 8.4  SENARYO: Her üyenin EN SON yaptığı ödünç
SELECT o1.UyeID, o1.KitapID, o1.OduncTarihi
FROM Oduncler AS o1
WHERE o1.OduncTarihi = (SELECT MAX(o2.OduncTarihi)
                        FROM Oduncler AS o2
                        WHERE o2.UyeID = o1.UyeID)
ORDER BY o1.UyeID;
-- Beklenen: 10 satır (ödünç almış her üye için bir satır)
GO


/* =====================================================================
   BÖLÜM 9: ANY ve ALL (BONUS)
   > ALL (liste) : listedeki TÜM değerlerden büyük   ( = > MAX )
   > ANY (liste) : listedeki EN AZ BİR değerden büyük ( = > MIN )
   ===================================================================== */

-- 9.1  SENARYO: TÜM Bilim kitaplarından daha kalın kitaplar
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi > ALL (SELECT SayfaSayisi FROM Kitaplar WHERE KategoriID = 2);
-- Beklenen: 396'dan kalın 6 kitap - İnce Memed, Memleketimden İnsan Manzaraları,
--           Benim Adım Kırmızı, Suç ve Ceza, Devlet, Huzur

-- Aynı sonuç MAX ile:
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi > (SELECT MAX(SayfaSayisi) FROM Kitaplar WHERE KategoriID = 2);

-- 9.2  SENARYO: EN AZ BİR Bilim kitabından daha kalın kitaplar
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi > ANY (SELECT SayfaSayisi FROM Kitaplar WHERE KategoriID = 2);
-- Beklenen: 176'dan kalın 14 kitap
GO


/* =====================================================================
   BÖLÜM 10: UPDATE ve DELETE İÇİNDE ALT SORGU
   ===================================================================== */

-- 10.1 SENARYO: En az 2 kez ödünç alınan (popüler) kitapların stoğunu 1 artır
--      Önce hangi kitapların etkileneceğini görelim:
SELECT KitapAdi, StokAdedi
FROM Kitaplar
WHERE KitapID IN (SELECT KitapID FROM Oduncler
                  GROUP BY KitapID
                  HAVING COUNT(*) >= 2);
-- Beklenen: Kürk Mantolu Madonna 3, 1984 3

UPDATE Kitaplar
SET StokAdedi = StokAdedi + 1
WHERE KitapID IN (SELECT KitapID FROM Oduncler
                  GROUP BY KitapID
                  HAVING COUNT(*) >= 2);
-- Mesaj: (2 rows affected)  -> stoklar 4 oldu

-- Diğer örnekler etkilenmesin diye geri alalım:
UPDATE Kitaplar
SET StokAdedi = StokAdedi - 1
WHERE KitapID IN (SELECT KitapID FROM Oduncler
                  GROUP BY KitapID
                  HAVING COUNT(*) >= 2);

-- 10.2 SENARYO: Ekim'de kayıt olup hiç kitap almamış üyeleri silmek
--      ALTIN KURAL: DELETE'ten önce aynı WHERE ile SELECT çalıştırın!
SELECT Ad, Soyad, KayitTarihi
FROM Uyeler
WHERE KayitTarihi >= '2026-10-01'
  AND UyeID NOT IN (SELECT UyeID FROM Oduncler);
-- Beklenen: Burak Çelik, Ece Polat

--      Gerçekten silmek isterseniz yorumu kaldırın
--      (sonra 01_Veri_Ekleme.sql ile verileri geri yükleyebilirsiniz):
-- DELETE FROM Uyeler
-- WHERE KayitTarihi >= '2026-10-01'
--   AND UyeID NOT IN (SELECT UyeID FROM Oduncler);
GO


/* =====================================================================
   BÖLÜM 11: ALT SORGU MU, JOIN Mİ? / SIK YAPILAN HATALAR
   ===================================================================== */

-- 11.1 Aynı soru, iki çözüm: Bilim Kurgu kitapları
--      (a) Alt sorgu ile
SELECT KitapAdi
FROM Kitaplar
WHERE KategoriID = (SELECT KategoriID FROM Kategoriler WHERE KategoriAdi = N'Bilim Kurgu');

--      (b) JOIN ile
SELECT k.KitapAdi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
WHERE kt.KategoriAdi = N'Bilim Kurgu';
-- İkisi de: 1984, Ben, Robot
-- Fark: JOIN ile kategori adı SELECT'te de gösterilebilir;
--       alt sorguda yalnızca dış tablonun (Kitaplar) sütunları gösterilebilir.

-- 11.2 HATA: = ile kullanılan alt sorgu BİRDEN FAZLA değer döndürürse (Msg 512)
--      "Bilim%" deseni hem Bilim'i hem Bilim Kurgu'yu bulur. Yorumu kaldırıp deneyin:
-- SELECT KitapAdi FROM Kitaplar
-- WHERE KategoriID = (SELECT KategoriID FROM Kategoriler WHERE KategoriAdi LIKE N'Bilim%');
--      Çözüm: = yerine IN kullanın.
SELECT KitapAdi FROM Kitaplar
WHERE KategoriID IN (SELECT KategoriID FROM Kategoriler WHERE KategoriAdi LIKE N'Bilim%');
-- Beklenen: 5 kitap (Bilim 3 + Bilim Kurgu 2)

-- 11.3 HATA: FROM'daki alt sorguya takma ad vermemek (Msg 102). Deneyin:
-- SELECT * FROM (SELECT KategoriID, COUNT(*) AS Sayi FROM Kitaplar GROUP BY KategoriID);

-- 11.4 HATA: Alt sorgu içinde ORDER BY (Msg 1033). Deneyin:
-- SELECT KitapAdi FROM Kitaplar
-- WHERE KitapID IN (SELECT KitapID FROM Oduncler ORDER BY KitapID);

-- 11.5 HATA: SELECT içindeki alt sorgu birden çok satır döndürürse (Msg 512). Deneyin:
-- SELECT KitapAdi, (SELECT UyeID FROM Oduncler) AS Uye FROM Kitaplar;
GO


/* =====================================================================
   BÖLÜM 12: ÖĞRENCİ ALIŞTIRMALARI (alt sorgu kullanarak çözün)
   ===================================================================== */
-- S1.  Stoğu en fazla olan kitabı bulun.
-- S2.  "Suç ve Ceza"dan daha yeni olan ama "1984"ten daha eski olan kitapları listeleyin.
-- S3.  Ortalama stoktan fazla stoğu olan kitapları listeleyin.
-- S4.  "Ayşe Yılmaz"ın ödünç aldığı kitapların adlarını alt sorgu ile bulun.
-- S5.  İngiliz yazarların kitaplarını IN ile listeleyin.
-- S6.  Hiç ödünç alınmamış kitapları NOT EXISTS ile bulun.
-- S7.  Her yazarın kaç kitabı olduğunu SELECT içinde alt sorgu ile gösterin.
-- S8.  "Can Öztürk" ile aynı gün veya daha önce kayıt olmuş üyeleri listeleyin.
-- S9.  Her kategorinin en ince kitabını ilişkili alt sorgu ile bulun.
-- S10. Bilim Kurgu kitaplarını ödünç almış üyelerin adlarını 3 seviyeli
--      alt sorgu ile bulun.
