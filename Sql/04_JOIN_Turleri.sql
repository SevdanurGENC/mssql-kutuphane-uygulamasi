/* =====================================================================
   KÜTÜPHANE UYGULAMASI - JOIN TÜRLERİ (SADE SÜRÜM)
     Bölüm 1: INNER JOIN
     Bölüm 2: OUTER JOIN nedir?
     Bölüm 3: LEFT (OUTER) JOIN
     Bölüm 4: RIGHT (OUTER) JOIN
     Bölüm 5: FULL (OUTER) JOIN
     Bölüm 6: CROSS JOIN
     Bölüm 7: SELF JOIN
     Bölüm 8: Karşılaştırma ve alıştırmalar

   Ön koşul: 01_Veri_Ekleme.sql çalıştırılmış olmalı.
   Her sorgunun altında, o veriyle BEKLENEN sonuç yazılıdır.

   ÖZET:
   INNER JOIN : Yalnızca İKİ tabloda da eşleşen satırlar
   LEFT JOIN  : Soldaki tablonun TÜMÜ + sağdan eşleşenler (yoksa NULL)
   RIGHT JOIN : Sağdaki tablonun TÜMÜ + soldan eşleşenler (yoksa NULL)
   FULL JOIN  : İki tablonun TÜMÜ; eşleşmeyen taraf NULL
   CROSS JOIN : Her satır diğer tablonun HER satırıyla (Kartezyen çarpım)
   SELF JOIN  : Tablonun KENDİSİYLE birleştirilmesi (farklı takma adlarla)
   ===================================================================== */
USE KutuphaneDB;
GO


/* =====================================================================
   BÖLÜM 1: INNER JOIN
   Yalnızca iki tabloda da EŞLEŞEN satırlar gelir.
   "INNER" kelimesi isteğe bağlıdır: JOIN = INNER JOIN
   ===================================================================== */

-- 1.1  İki tablo: Kitaplar ve kategori adları
SELECT k.KitapAdi, kt.KategoriAdi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
ORDER BY kt.KategoriAdi, k.KitapAdi;
-- Beklenen: 18 satır. Kitabı olmayan Psikoloji ve Biyografi GELMEZ.

-- 1.2  Üç tablo (N:M): Kitaplar ve yazarları
SELECT k.KitapAdi, y.Ad, y.Soyad
FROM Kitaplar AS k
INNER JOIN KitapYazar AS ky ON k.KitapID  = ky.KitapID
INNER JOIN Yazarlar   AS y  ON ky.YazarID = y.YazarID
ORDER BY k.KitapAdi;
-- Beklenen: 19 satır (Zamanın Daha Kısa Tarihi iki kez, iki yazarıyla)

-- 1.3  Ödünç listesi: kim, hangi kitabı, ne zaman aldı?
SELECT u.Ad, u.Soyad, k.KitapAdi, o.OduncTarihi, o.IadeTarihi
FROM Oduncler AS o
INNER JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
INNER JOIN Kitaplar AS k ON o.KitapID = k.KitapID
ORDER BY o.OduncTarihi;
-- Beklenen: 16 satır

-- 1.4  INNER JOIN + WHERE: Roman kategorisinde şu an ödünçte olan kitaplar
SELECT u.Ad, u.Soyad, k.KitapAdi, o.SonTeslimTarihi
FROM Oduncler AS o
INNER JOIN Uyeler      AS u  ON o.UyeID      = u.UyeID
INNER JOIN Kitaplar    AS k  ON o.KitapID    = k.KitapID
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
WHERE kt.KategoriAdi = N'Roman'
  AND o.IadeTarihi IS NULL;
-- Beklenen: Zeynep - Kürk Mantolu Madonna, Can - Benim Adım Kırmızı,
--           Elif - Kürk Mantolu Madonna, Oğuz - Saatleri Ayarlama Enstitüsü,
--           Selin - Hayvan Çiftliği

-- 1.5  INNER JOIN + WHERE: Türk yazarların kitapları
SELECT y.Ad, y.Soyad, k.KitapAdi
FROM Yazarlar AS y
INNER JOIN KitapYazar AS ky ON y.YazarID  = ky.YazarID
INNER JOIN Kitaplar   AS k  ON ky.KitapID = k.KitapID
WHERE y.Ulke = N'Türkiye'
ORDER BY y.Soyad;
-- Beklenen: 8 satır

-- 1.6  INNER JOIN + GROUP BY: Her kategoride kaç kitap var?
SELECT kt.KategoriAdi, COUNT(*) AS KitapSayisi
FROM Kitaplar AS k
INNER JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
GROUP BY kt.KategoriAdi;
-- Beklenen: 8 kategori (Psikoloji ve Biyografi YOK)
GO


/* =====================================================================
   BÖLÜM 2: OUTER JOIN NEDİR?
   OUTER JOIN, eşleşmeyen satırları da getiren JOIN'lerin genel adıdır.
   Üç türü vardır: LEFT OUTER, RIGHT OUTER, FULL OUTER.
   "OUTER" kelimesi isteğe bağlıdır:
       LEFT OUTER JOIN  =  LEFT JOIN
       RIGHT OUTER JOIN =  RIGHT JOIN
       FULL OUTER JOIN  =  FULL JOIN
   Eşleşmeyen taraftaki sütunlar NULL olarak gelir.
   ===================================================================== */

-- 2.1  Aynı sorgu iki yazımla - sonuçlar AYNIDIR
SELECT kt.KategoriAdi, k.KitapAdi
FROM Kategoriler AS kt
LEFT OUTER JOIN Kitaplar AS k ON kt.KategoriID = k.KategoriID;

SELECT kt.KategoriAdi, k.KitapAdi
FROM Kategoriler AS kt
LEFT JOIN Kitaplar AS k ON kt.KategoriID = k.KategoriID;
-- Beklenen: 20 satır (18 kitap + kitabı olmayan Psikoloji ve Biyografi, NULL ile)
GO


/* =====================================================================
   BÖLÜM 3: LEFT (OUTER) JOIN
   Soldaki (FROM'daki) tablonun TÜM satırları gelir.
   Sağda eşleşme yoksa sağın sütunları NULL olur.
   ===================================================================== */

-- 3.1  Tüm üyeler ve aldıkları ödünçler
SELECT u.Ad, u.Soyad, o.OduncID, o.OduncTarihi
FROM Uyeler AS u
LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
ORDER BY u.UyeID;
-- Beklenen: 18 satır; Burak ve Ece'nin ödünç sütunları NULL

-- 3.2  LEFT JOIN + IS NULL: Hiç ödünç almamış üyeler
SELECT u.Ad, u.Soyad
FROM Uyeler AS u
LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
WHERE o.OduncID IS NULL;
-- Beklenen: Burak Çelik, Ece Polat

-- 3.3  LEFT JOIN + IS NULL: HİÇ ödünç verilmemiş kitaplar
SELECT k.KitapAdi
FROM Kitaplar AS k
LEFT JOIN Oduncler AS o ON k.KitapID = o.KitapID
WHERE o.OduncID IS NULL;
-- Beklenen: Kırmızı Saçlı Kadın, Memleketimden İnsan Manzaraları,
--           Ben, Robot, Devlet, Huzur

-- 3.4  LEFT JOIN + IS NULL: Kitabı olmayan kategoriler
SELECT kt.KategoriAdi
FROM Kategoriler AS kt
LEFT JOIN Kitaplar AS k ON kt.KategoriID = k.KategoriID
WHERE k.KitapID IS NULL;
-- Beklenen: Psikoloji, Biyografi

-- 3.5  LEFT JOIN + GROUP BY: Tüm kategoriler ve kitap sayıları (0 olanlar dahil)
SELECT kt.KategoriAdi, COUNT(k.KitapID) AS KitapSayisi
FROM Kategoriler AS kt
LEFT JOIN Kitaplar AS k ON kt.KategoriID = k.KategoriID
GROUP BY kt.KategoriAdi
ORDER BY KitapSayisi DESC;
-- Beklenen: ... Psikoloji 0, Biyografi 0
-- DİKKAT: COUNT(*) yazsaydık NULL satırı da sayılır, 0 yerine 1 görünürdü!

-- 3.6  LEFT JOIN + GROUP BY: Tüm üyeler ve ödünç sayıları
SELECT u.Ad, u.Soyad, COUNT(o.OduncID) AS OduncSayisi
FROM Uyeler AS u
LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
GROUP BY u.Ad, u.Soyad
ORDER BY OduncSayisi DESC;
-- Beklenen: 12 üye; Burak ve Ece 0

-- 3.7  ISNULL ile NULL yerine anlamlı metin yazmak
SELECT k.KitapAdi, ISNULL(u.Ad, N'Rafta') AS KimdeOdunc
FROM Kitaplar AS k
LEFT JOIN Oduncler AS o ON k.KitapID = o.KitapID AND o.IadeTarihi IS NULL
LEFT JOIN Uyeler   AS u ON o.UyeID   = u.UyeID
ORDER BY k.KitapAdi;
-- Ödünçte olmayan kitaplar için 'Rafta' yazar.

-- 3.8  ÇOK ÖNEMLİ: Koşulu ON'a mı, WHERE'e mi yazmalı?
--      (a) Koşul ON'da: TÜM üyeler gelir; Ekim'de ödünç almayanlar NULL
SELECT u.Ad, o.OduncTarihi
FROM Uyeler AS u
LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
                       AND o.OduncTarihi >= '2026-10-01'
ORDER BY u.UyeID;
-- Beklenen: 12 satır (5'i dolu: Can, Elif, Selin, Merve, Oğuz; 7'si NULL)

--      (b) Koşul WHERE'de: NULL satırlar elenir, sonuç INNER JOIN gibi olur!
SELECT u.Ad, o.OduncTarihi
FROM Uyeler AS u
LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID
WHERE o.OduncTarihi >= '2026-10-01'
ORDER BY u.UyeID;
-- Beklenen: Sadece 5 satır
GO


/* =====================================================================
   BÖLÜM 4: RIGHT (OUTER) JOIN
   Sağdaki (JOIN'den sonraki) tablonun TÜM satırları gelir.
   A RIGHT JOIN B  ==  B LEFT JOIN A
   ===================================================================== */

-- 4.1  Kitaplar RIGHT JOIN Kategoriler: tüm kategoriler gelir
SELECT kt.KategoriAdi, k.KitapAdi
FROM Kitaplar AS k
RIGHT JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
ORDER BY kt.KategoriAdi;
-- Beklenen: 20 satır; Psikoloji ve Biyografi'de KitapAdi NULL
-- Bölüm 2.1'deki LEFT JOIN ile AYNI sonuç (tablolar yer değiştirdi)

-- 4.2  Oduncler RIGHT JOIN Uyeler: tüm üyeler
SELECT u.Ad, u.Soyad, o.OduncID, o.OduncTarihi
FROM Oduncler AS o
RIGHT JOIN Uyeler AS u ON o.UyeID = u.UyeID
ORDER BY u.UyeID;
-- Beklenen: 18 satır (16 ödünç + Burak ve Ece NULL ile)

-- 4.3  RIGHT JOIN + IS NULL: Hiç ödünç almamış üyeler
SELECT u.Ad, u.Soyad
FROM Oduncler AS o
RIGHT JOIN Uyeler AS u ON o.UyeID = u.UyeID
WHERE o.OduncID IS NULL;
-- Beklenen: Burak Çelik, Ece Polat  (3.2 ile aynı sonuç)

-- 4.4  RIGHT JOIN + IS NULL: Kitabı olmayan kategoriler
SELECT kt.KategoriAdi
FROM Kitaplar AS k
RIGHT JOIN Kategoriler AS kt ON k.KategoriID = kt.KategoriID
WHERE k.KitapID IS NULL;
-- Beklenen: Psikoloji, Biyografi  (3.4 ile aynı sonuç)

-- 4.5  Yön önemlidir: Kategoriler RIGHT JOIN Kitaplar
--      Bu kez TÜM KİTAPLAR korunur; her kitabın kategorisi olduğu için
--      sonuç INNER JOIN ile aynıdır (18 satır, NULL yok).
SELECT kt.KategoriAdi, k.KitapAdi
FROM Kategoriler AS kt
RIGHT JOIN Kitaplar AS k ON k.KategoriID = kt.KategoriID;
GO


/* =====================================================================
   BÖLÜM 5: FULL (OUTER) JOIN
   İKİ tablonun da TÜM satırları gelir.
   Eşleşen satırlar yan yana; eşleşmeyenlerde karşı taraf NULL.
   = LEFT JOIN + RIGHT JOIN sonuçlarının birleşimi
   ===================================================================== */

-- 5.1  Kategoriler FULL JOIN Kitaplar
SELECT kt.KategoriAdi, k.KitapAdi
FROM Kategoriler AS kt
FULL JOIN Kitaplar AS k ON kt.KategoriID = k.KategoriID;
-- Beklenen: 20 satır. Kitapsız kategoriler NULL ile gelir.
-- Her kitabın bir kategorisi olduğu için kategorisiz kitap yoktur;
-- bu yüzden sonuç LEFT JOIN ile aynıdır.

-- 5.2  Uyeler FULL JOIN Oduncler
SELECT u.Ad, u.Soyad, o.OduncID
FROM Uyeler AS u
FULL JOIN Oduncler AS o ON u.UyeID = o.UyeID;
-- Beklenen: 18 satır (16 ödünç + ödünç almamış Burak ve Ece)

-- 5.3  İKİ TARAFTA DA eşleşmeyen satır olan örnek:
--      Öğrencilerin istek listesi ile kütüphane rafını karşılaştırma.
--      İstek listesi için geçici bir tablo değişkeni kullanıyoruz
--      (kalıcı tablolar değişmez).
DECLARE @IstekListesi TABLE (IstenenKitap NVARCHAR(150));
INSERT INTO @IstekListesi VALUES
(N'Küçük Prens'), (N'Suç ve Ceza'), (N'1984'), (N'Sefiller'), (N'Simyacı');

-- (a) Tüm satırlar
SELECT i.IstenenKitap, k.KitapAdi AS RaftakiKitap
FROM @IstekListesi AS i
FULL JOIN Kitaplar AS k ON i.IstenenKitap = k.KitapAdi;
-- Beklenen: 20 satır
--   Sol dolu, sağ dolu : Küçük Prens, Suç ve Ceza, 1984 (istendi ve rafta)
--   Sol dolu, sağ NULL : Sefiller, Simyacı              (istendi, rafta YOK)
--   Sol NULL, sağ dolu : diğer 15 kitap                 (rafta, istenmedi)

-- (b) Sadece rafta OLMAYAN istenen kitaplar (satın alınacaklar)
SELECT i.IstenenKitap
FROM @IstekListesi AS i
FULL JOIN Kitaplar AS k ON i.IstenenKitap = k.KitapAdi
WHERE k.KitapID IS NULL;
-- Beklenen: Sefiller, Simyacı

-- (c) Sadece eşleşmeyenler (iki taraftan da)
SELECT i.IstenenKitap, k.KitapAdi
FROM @IstekListesi AS i
FULL JOIN Kitaplar AS k ON i.IstenenKitap = k.KitapAdi
WHERE i.IstenenKitap IS NULL OR k.KitapID IS NULL;
-- Beklenen: 17 satır (2 istenen ama rafta olmayan + 15 rafta ama istenmeyen)
GO


/* =====================================================================
   BÖLÜM 6: CROSS JOIN
   ON koşulu YOKTUR. Soldaki her satır sağdaki HER satırla eşleşir.
   Sonuç satır sayısı = sol satır sayısı x sağ satır sayısı
   ===================================================================== */

-- 6.1  Kaç satır oluşur? 10 kategori x 12 üye
SELECT COUNT(*) AS SatirSayisi
FROM Kategoriler
CROSS JOIN Uyeler;
-- Beklenen: 120

-- 6.2  Tüm eşleşmeleri görmek
SELECT u.Ad, kt.KategoriAdi
FROM Uyeler AS u
CROSS JOIN Kategoriler AS kt
ORDER BY u.Ad, kt.KategoriAdi;
-- Beklenen: 120 satır (her üye 10 kez, her seferinde farklı kategoriyle)

-- 6.3  Anket formu: Ekim'de kaydolan yeni üyelere her kategori sorulacak
SELECT u.Ad, u.Soyad, kt.KategoriAdi
FROM Uyeler AS u
CROSS JOIN Kategoriler AS kt
WHERE u.KayitTarihi >= '2026-10-01'
ORDER BY u.Ad, kt.KategoriAdi;
-- Beklenen: 2 üye (Burak, Ece) x 10 kategori = 20 satır

-- 6.4  Kitap önerisi: Yeni üyelere tüm Bilim Kurgu kitaplarını öner
SELECT u.Ad, k.KitapAdi AS OnerilenKitap
FROM Uyeler AS u
CROSS JOIN Kitaplar AS k
WHERE u.KayitTarihi >= '2026-10-01'
  AND k.KategoriID = 9
ORDER BY u.Ad;
-- Beklenen: 2 üye x 2 kitap (1984, Ben, Robot) = 4 satır

-- 6.5  Fransız yazar ile tüm kategorilerin eşleşmesi
SELECT y.Ad, y.Soyad, kt.KategoriAdi
FROM Yazarlar AS y
CROSS JOIN Kategoriler AS kt
WHERE y.Ulke = N'Fransa';
-- Beklenen: 1 yazar x 10 kategori = 10 satır

-- 6.6  CROSS JOIN = virgüllü FROM (WHERE'siz)
SELECT COUNT(*) FROM Kategoriler CROSS JOIN Uyeler;   -- 120
SELECT COUNT(*) FROM Kategoriler, Uyeler;             -- 120
GO


/* =====================================================================
   BÖLÜM 7: SELF JOIN
   Bir tabloyu KENDİSİYLE birleştirmek. Özel bir anahtar kelime yoktur;
   INNER veya LEFT JOIN kullanılır. Tablo iki FARKLI takma adla yazılır.
   ===================================================================== */

-- 7.1  Aynı gün kayıt olmuş üye çiftleri
--      u1.UyeID < u2.UyeID: bir üyenin kendisiyle eşleşmesini ve
--      (Ayşe-Mehmet / Mehmet-Ayşe) tekrarını önler.
SELECT u1.Ad AS Uye1, u2.Ad AS Uye2, u1.KayitTarihi
FROM Uyeler AS u1
INNER JOIN Uyeler AS u2 ON u1.KayitTarihi = u2.KayitTarihi
                       AND u1.UyeID < u2.UyeID;
-- Beklenen: Ayşe - Mehmet (2026-09-08)

-- 7.2  < koşulu OLMADAN ne olur?
SELECT u1.Ad AS Uye1, u2.Ad AS Uye2, u1.KayitTarihi
FROM Uyeler AS u1
INNER JOIN Uyeler AS u2 ON u1.KayitTarihi = u2.KayitTarihi
ORDER BY u1.UyeID;
-- Beklenen: 14 satır! Her üye kendisiyle eşleşir (12) +
--           Ayşe-Mehmet ve Mehmet-Ayşe (2). Bu yüzden < kullanıyoruz.

-- 7.3  Aynı ülkeden olan yazar çiftleri
SELECT y1.Ad AS Yazar1, y2.Ad AS Yazar2, y1.Ulke
FROM Yazarlar AS y1
INNER JOIN Yazarlar AS y2 ON y1.Ulke = y2.Ulke
                         AND y1.YazarID < y2.YazarID
ORDER BY y1.Ulke;
-- Beklenen: 21 çift (ABD 3, İngiltere 3, Türkiye 15)

-- 7.4  Aynı yıl yayımlanmış kitap çiftleri
SELECT k1.KitapAdi AS Kitap1, k2.KitapAdi AS Kitap2, k1.YayinYili
FROM Kitaplar AS k1
INNER JOIN Kitaplar AS k2 ON k1.YayinYili = k2.YayinYili
                         AND k1.KitapID < k2.KitapID;
-- Beklenen: Kürk Mantolu Madonna - Küçük Prens (1943)
--           1984 - Huzur (1949)

-- 7.5  Aynı kategorideki kitap çiftleri (sadece Bilim)
SELECT k1.KitapAdi AS Kitap1, k2.KitapAdi AS Kitap2
FROM Kitaplar AS k1
INNER JOIN Kitaplar AS k2 ON k1.KategoriID = k2.KategoriID
                         AND k1.KitapID < k2.KitapID
WHERE k1.KategoriID = 2;
-- Beklenen: 3 çift (Zamanın Kısa Tarihi, Zamanın Daha Kısa Tarihi, Kozmos)

-- 7.6  Aynı kitabı ödünç almış üye çiftleri (Oduncler kendisiyle)
SELECT o1.KitapID, o1.UyeID AS Uye1, o2.UyeID AS Uye2
FROM Oduncler AS o1
INNER JOIN Oduncler AS o2 ON o1.KitapID = o2.KitapID
                         AND o1.UyeID   < o2.UyeID;
-- Beklenen: Kitap 1: (1,3), (1,5), (3,5);  Kitap 11: (8,10)

-- 7.7  Aynı sorgu isimlerle (SELF JOIN + diğer tablolarla INNER JOIN)
SELECT k.KitapAdi, u1.Ad AS Uye1, u2.Ad AS Uye2
FROM Oduncler AS o1
INNER JOIN Oduncler AS o2 ON o1.KitapID = o2.KitapID
                         AND o1.UyeID   < o2.UyeID
INNER JOIN Uyeler   AS u1 ON o1.UyeID   = u1.UyeID
INNER JOIN Uyeler   AS u2 ON o2.UyeID   = u2.UyeID
INNER JOIN Kitaplar AS k  ON o1.KitapID = k.KitapID;
-- Beklenen: Kürk Mantolu Madonna: Ayşe-Zeynep, Ayşe-Elif, Zeynep-Elif
--           1984: Emre-Merve

-- 7.8  Aynı üyenin iki farklı ödüncü: önce hangisi, sonra hangisi?
SELECT o1.UyeID, o1.OduncTarihi AS IlkOdunc, o2.OduncTarihi AS SonrakiOdunc
FROM Oduncler AS o1
INNER JOIN Oduncler AS o2 ON o1.UyeID = o2.UyeID
                         AND o1.OduncTarihi < o2.OduncTarihi
ORDER BY o1.UyeID;
-- Beklenen: 6 satır (2 ödünç almış 6 üye: 1, 2, 3, 4, 5, 7)
GO


/* =====================================================================
   BÖLÜM 8: KARŞILAŞTIRMA - AYNI İKİ TABLO, FARKLI JOIN'LER
   Uyeler (12 satır) ve Oduncler (16 satır). Her sorguyu çalıştırıp
   satır sayılarını karşılaştırın.
   ===================================================================== */
SELECT COUNT(*) AS InnerJoin
FROM Uyeler AS u INNER JOIN Oduncler AS o ON u.UyeID = o.UyeID;
-- 16 (sadece eşleşenler)

SELECT COUNT(*) AS LeftJoin
FROM Uyeler AS u LEFT JOIN Oduncler AS o ON u.UyeID = o.UyeID;
-- 18 (16 + hiç ödünç almayan 2 üye)

SELECT COUNT(*) AS RightJoin
FROM Uyeler AS u RIGHT JOIN Oduncler AS o ON u.UyeID = o.UyeID;
-- 16 (her ödüncün bir üyesi var, ek satır yok)

SELECT COUNT(*) AS FullJoin
FROM Uyeler AS u FULL JOIN Oduncler AS o ON u.UyeID = o.UyeID;
-- 18 (LEFT ile aynı, çünkü sağda eşleşmeyen yok)

SELECT COUNT(*) AS CrossJoin
FROM Uyeler AS u CROSS JOIN Oduncler AS o;
-- 192 (12 x 16)
GO


/* =====================================================================
   ÖĞRENCİ ALIŞTIRMALARI (cevapları kendiniz yazın)
   ===================================================================== */
-- J1. (INNER) Her ödünç kaydı için üyenin adını, kitabın adını ve kategorisini listeleyin.
-- J2. (INNER) İngiliz yazarların kitaplarını listeleyin.
-- J3. (LEFT)  Tüm yazarları ve yazdıkları kitapları listeleyin.
-- J4. (LEFT)  Hiç ödünç alınmamış kitapların adlarını ve kategorilerini bulun.
-- J5. (RIGHT) J4'ü RIGHT JOIN ile yeniden yazın.
-- J6. (FULL)  Yazarlar ve KitapYazar tablolarını FULL JOIN ile birleştirin;
--             kaç satır geldiğini tahmin edip kontrol edin.
-- J7. (CROSS) Polisiye kitapları ile tüm üyeleri CROSS JOIN ile eşleştirin.
-- J8. (SELF)  Aynı kategoride olan Roman çiftlerini listeleyin.
-- J9. (SELF)  İngiltere'den olan yazar çiftlerini listeleyin.
-- J10. (SELF) Stok adedi aynı olan kitap çiftlerini listeleyin.
