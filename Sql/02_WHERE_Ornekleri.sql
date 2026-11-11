/* =====================================================================
   KÜTÜPHANE UYGULAMASI - WHERE KOŞUL ÖRNEKLERİ
   Konular: Karşılaştırma operatörleri (=, <>, >, <, >=, <=),
            BETWEEN (sayı ve tarih), LIKE (%, _, [], [^]),
            IN, IS NULL, AND / OR / NOT

   Ön koşul: 01_Veri_Ekleme.sql çalıştırılmış olmalı.
   Her sorgunun altında, o veriyle BEKLENEN sonuç yazılıdır.
   ===================================================================== */
USE KutuphaneDB;
GO


/* =====================================================================
   BÖLÜM 1: KARŞILAŞTIRMA OPERATÖRLERİ
   =    eşittir          <>  eşit değildir (!= de çalışır)
   >    büyüktür         <   küçüktür
   >=   büyük eşittir    <=  küçük eşittir
   ===================================================================== */

-- 1.1  = : Stokta yalnızca 1 adet bulunan kitaplar
SELECT KitapAdi, StokAdedi
FROM Kitaplar
WHERE StokAdedi = 1;
-- Beklenen: Kırmızı Saçlı Kadın, Zamanın Daha Kısa Tarihi,
--           Memleketimden İnsan Manzaraları, Ben, Robot, Devlet, Huzur

-- 1.2  <> : Türkiye dışındaki yazarlar
SELECT Ad, Soyad, Ulke
FROM Yazarlar
WHERE Ulke <> N'Türkiye';
-- Beklenen: 9 yazar (Hawking, Mlodinow, Saint-Exupéry, Dostoyevski, ...)

-- 1.3  > : 400 sayfadan UZUN kitaplar
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi > 400;
-- Beklenen: İnce Memed (436), Memleketimden... (480), Benim Adım Kırmızı (472),
--           Suç ve Ceza (687), Huzur (432)

-- 1.4  >= : 400 sayfa VE üzeri  ( > ile farkına dikkat! )
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi >= 400;
-- Beklenen: 1.3'tekiler + Devlet (tam 400 sayfa)

-- 1.5  < : 200 sayfadan kısa kitaplar, kısadan uzuna
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi < 200
ORDER BY SayfaSayisi;
-- Beklenen: Küçük Prens (112), Hayvan Çiftliği (152),
--           Kürk Mantolu Madonna (160), Zamanın Daha Kısa Tarihi (176)

-- 1.6  <= : 1950 ve öncesinde yayımlanan kitaplar
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili <= 1950
ORDER BY YayinYili;
-- Beklenen: Suç ve Ceza (1866) ... Ben, Robot (1950) - toplam 8 kitap
-- DİKKAT: "Devlet" kitabı listede YOK! Çünkü YayinYili NULL.
--         NULL hiçbir karşılaştırmada (=, <, > ...) DOĞRU sonuç vermez.

-- 1.7  Tarihlerle karşılaştırma: 1 Ekim 2026'dan ÖNCE
--      teslim edilmesi gereken ödünçler
SELECT OduncID, KitapID, UyeID, SonTeslimTarihi
FROM Oduncler
WHERE SonTeslimTarihi < '2026-10-01';
-- Beklenen: OduncID 1, 3, 5, 6  (tarih metni 'YYYY-AA-GG' biçiminde yazılır)

-- 1.8  İki SÜTUNU birbiriyle karşılaştırma: GEÇ iade edilen kitaplar
SELECT OduncID, SonTeslimTarihi, IadeTarihi,
       DATEDIFF(DAY, SonTeslimTarihi, IadeTarihi) AS KacGunGec
FROM Oduncler
WHERE IadeTarihi > SonTeslimTarihi;
-- Beklenen: OduncID 3 (4 gün geç)

-- 1.9  Hesaplanmış değerle karşılaştırma: ödünç süresi 14 günden UZUN olanlar
SELECT OduncID, OduncTarihi, SonTeslimTarihi
FROM Oduncler
WHERE DATEDIFF(DAY, OduncTarihi, SonTeslimTarihi) > 14;
-- Beklenen: Sonuç yok (tüm ödünçler tam 14 gün). Koşulu = 14 yapıp deneyin.
GO


/* =====================================================================
   BÖLÜM 2: BETWEEN ... AND ...
   Uç değerler DAHİLDİR:  X BETWEEN 10 AND 20  ==  X >= 10 AND X <= 20
   Küçük değer her zaman ÖNCE yazılır.
   ===================================================================== */

-- 2.1  Sayı aralığı: 1940 - 1960 arasında yayımlanan kitaplar
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili BETWEEN 1940 AND 1960
ORDER BY YayinYili;
-- Beklenen: Kürk Mantolu Madonna, Küçük Prens (1943), Hayvan Çiftliği (1945),
--           1984, Huzur (1949), Ben, Robot (1950), İnce Memed (1955)

-- 2.2  Aynı sorgu >= ve <= ile (sonuç aynıdır)
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE YayinYili >= 1940 AND YayinYili <= 1960;

-- 2.3  Tarih aralığı: 15-30 Eylül 2026 arasında yapılan ödünçler
SELECT OduncID, KitapID, UyeID, OduncTarihi
FROM Oduncler
WHERE OduncTarihi BETWEEN '2026-09-15' AND '2026-09-30'
ORDER BY OduncTarihi;
-- Beklenen: OduncID 5, 6, 7, 8, 10, 11, 2, 4, 12  (9 kayıt)
--           15 Eylül ve 30 Eylül dahil.

-- 2.4  Ekim ayında kayıt olan üyeler
SELECT Ad, Soyad, KayitTarihi
FROM Uyeler
WHERE KayitTarihi BETWEEN '2026-10-01' AND '2026-10-31';
-- Beklenen: Burak Çelik, Ece Polat

-- 2.5  Aynı soru tarih fonksiyonlarıyla (YEAR, MONTH)
SELECT Ad, Soyad, KayitTarihi
FROM Uyeler
WHERE YEAR(KayitTarihi) = 2026 AND MONTH(KayitTarihi) = 10;

-- 2.6  Bugüne göre: son 7 günde yapılan ödünçler
--      (Sonuç, sorguyu çalıştırdığınız güne göre değişir.)
SELECT OduncID, OduncTarihi
FROM Oduncler
WHERE OduncTarihi BETWEEN DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
                      AND CAST(GETDATE() AS DATE);

-- 2.7  NOT BETWEEN: 200-400 sayfa ARALIĞI DIŞINDAKİ kitaplar
SELECT KitapAdi, SayfaSayisi
FROM Kitaplar
WHERE SayfaSayisi NOT BETWEEN 200 AND 400
ORDER BY SayfaSayisi;
-- Beklenen: 200'den kısa 4 kitap + 400'den uzun 5 kitap

-- 2.8  Metinlerde BETWEEN: soyadı A ile D arasında başlayan üyeler
SELECT Ad, Soyad
FROM Uyeler
WHERE Soyad BETWEEN N'A' AND N'Dz'
ORDER BY Soyad;
-- Beklenen: Arslan, Aydın, Çelik, Demir  (alfabetik karşılaştırma yapılır;
--           Ç harfi C ile D arasında sıralanır)
-- Not: Metin aralıklarında LIKE '[A-D]%' (Bölüm 3) çoğu zaman daha anlaşılırdır.
GO


/* =====================================================================
   BÖLÜM 3: LIKE (DESEN EŞLEME)
   %      : sıfır veya daha fazla HERHANGİ karakter
   _      : TAM OLARAK BİR karakter
   [abc]  : köşeli parantez içindeki karakterlerden BİRİ
   [a-d]  : aralıktaki karakterlerden biri
   [^abc] : parantez içindekiler DIŞINDAKİ bir karakter
   ===================================================================== */

-- 3.1  ... ile BAŞLAYAN: "K" harfiyle başlayan kitaplar
SELECT KitapAdi
FROM Kitaplar
WHERE KitapAdi LIKE N'K%';
-- Beklenen: Kürk Mantolu Madonna, Kırmızı Saçlı Kadın, Küçük Prens, Kozmos

-- 3.2  ... ile BİTEN: adı "Tarihi" ile biten kitaplar
SELECT KitapAdi
FROM Kitaplar
WHERE KitapAdi LIKE N'%Tarihi';
-- Beklenen: Zamanın Kısa Tarihi, Zamanın Daha Kısa Tarihi

-- 3.3  ... İÇEREN: adında "Kırmızı" geçen kitaplar
SELECT KitapAdi
FROM Kitaplar
WHERE KitapAdi LIKE N'%Kırmızı%';
-- Beklenen: Kırmızı Saçlı Kadın, Benim Adım Kırmızı

-- 3.4  Telefonu 053 ile başlayan üyeler
SELECT Ad, Soyad, Telefon
FROM Uyeler
WHERE Telefon LIKE '053%';
-- Beklenen: Ayşe, Mehmet, Selin, Merve, Ece

-- 3.5  _ : Adı tam olarak 3 harfli üyeler
SELECT Ad, Soyad
FROM Uyeler
WHERE Ad LIKE N'___';          -- üç tane alt çizgi
-- Beklenen: Can, Ece

-- 3.6  _ ve % birlikte: soyadının İKİNCİ harfi "a" olan üyeler
SELECT Ad, Soyad
FROM Uyeler
WHERE Soyad LIKE N'_a%';
-- Beklenen: Zeynep Kaya, Elif Şahin

-- 3.7  [ ] : Adı A veya E ile başlayan üyeler
SELECT Ad, Soyad
FROM Uyeler
WHERE Ad LIKE N'[AE]%';
-- Beklenen: Ayşe, Elif, Emre, Ece

-- 3.8  [a-d] aralık: Adı A ile D arasındaki bir harfle başlayan üyeler
SELECT Ad, Soyad
FROM Uyeler
WHERE Ad LIKE N'[A-D]%';
-- Beklenen: Ayşe, Can, Burak, Deniz

-- 3.9  [^ ] : Adı A, E ve M harfleri DIŞINDA bir harfle başlayan üyeler
SELECT Ad, Soyad
FROM Uyeler
WHERE Ad LIKE N'[^AEM]%';
-- Beklenen: Zeynep, Can, Burak, Selin, Deniz, Oğuz

-- 3.10 [0-9] : Adında RAKAM geçen kitaplar
SELECT KitapAdi
FROM Kitaplar
WHERE KitapAdi LIKE N'%[0-9]%';
-- Beklenen: 1984

-- 3.11 Adında VİRGÜL geçen kitaplar
SELECT KitapAdi
FROM Kitaplar
WHERE KitapAdi LIKE N'%,%';
-- Beklenen: Ben, Robot

-- 3.12 E-posta doğrulama: okul uzantılı e-postalar
SELECT Ad, Soyad, Eposta
FROM Uyeler
WHERE Eposta LIKE N'%@okul.edu.tr';
-- Beklenen: Elif dışındaki 11 üye

-- 3.13 NOT LIKE : Okul uzantısı OLMAYAN e-postalar
SELECT Ad, Soyad, Eposta
FROM Uyeler
WHERE Eposta NOT LIKE N'%@okul.edu.tr';
-- Beklenen: SONUÇ YOK!  Elif'in e-postası NULL olduğu için o da gelmez.
-- NULL'ları da görmek için:
SELECT Ad, Soyad, Eposta
FROM Uyeler
WHERE Eposta NOT LIKE N'%@okul.edu.tr' OR Eposta IS NULL;
-- Beklenen: Elif Şahin

-- 3.14 Joker karakterin KENDİSİNİ aramak: % veya _ içeren metinler
--      Karakteri köşeli paranteze alırsanız joker olmaktan çıkar.
SELECT KitapAdi
FROM Kitaplar
WHERE KitapAdi LIKE N'%[%]%';      -- içinde gerçekten % işareti olanlar
-- Beklenen: Sonuç yok (verimizde % işareti yok, sadece yazımı gösteriyor)

-- 3.15 LIKE ile = farkı: joker yoksa LIKE, = gibi çalışır
SELECT KitapAdi FROM Kitaplar WHERE KitapAdi LIKE N'Huzur';   -- Huzur
SELECT KitapAdi FROM Kitaplar WHERE KitapAdi =    N'Huzur';   -- Huzur
GO


/* =====================================================================
   BÖLÜM 4: IN ve IS NULL
   ===================================================================== */

-- 4.1  IN : Roman, Bilim Kurgu veya Polisiye kategorisindeki kitaplar
SELECT KitapAdi, KategoriID
FROM Kitaplar
WHERE KategoriID IN (1, 9, 10);
-- Aynısı OR ile: WHERE KategoriID = 1 OR KategoriID = 9 OR KategoriID = 10

-- 4.2  NOT IN : İngiltere ve ABD dışındaki yazarlar
SELECT Ad, Soyad, Ulke
FROM Yazarlar
WHERE Ulke NOT IN (N'İngiltere', N'ABD');

-- 4.3  IS NULL : Telefonu kayıtlı OLMAYAN üyeler
SELECT Ad, Soyad
FROM Uyeler
WHERE Telefon IS NULL;
-- Beklenen: Zeynep Kaya, Deniz Aydın
-- YANLIŞ yazım: WHERE Telefon = NULL  -> hiçbir zaman sonuç vermez!

-- 4.4  IS NOT NULL : İade edilmiş ödünçler
SELECT OduncID, IadeTarihi
FROM Oduncler
WHERE IadeTarihi IS NOT NULL;
-- Beklenen: OduncID 1, 3, 6, 8, 10
GO


/* =====================================================================
   BÖLÜM 5: KOŞULLARI BİRLEŞTİRME (AND, OR, NOT ve PARANTEZ)
   Öncelik: NOT > AND > OR.  Şüphe duyduğunuzda PARANTEZ kullanın.
   ===================================================================== */

-- 5.1  AND : 1950 sonrası yayımlanmış VE 300 sayfadan uzun kitaplar
SELECT KitapAdi, YayinYili, SayfaSayisi
FROM Kitaplar
WHERE YayinYili > 1950 AND SayfaSayisi > 300;
-- Beklenen: İnce Memed, Memleketimden..., Benim Adım Kırmızı,
--           Saatleri Ayarlama Enstitüsü, Kozmos

-- 5.2  PARANTEZİN ÖNEMİ: Roman kategorisinde olan VE
--      (200 sayfadan kısa VEYA 2000 sonrası yayımlanan) kitaplar
SELECT KitapAdi, SayfaSayisi, YayinYili
FROM Kitaplar
WHERE KategoriID = 1
  AND (SayfaSayisi < 200 OR YayinYili > 2000);
-- Beklenen: Kürk Mantolu Madonna, Kırmızı Saçlı Kadın, Hayvan Çiftliği

-- Aynı sorgu PARANTEZSİZ (YANLIŞ sonuç verir - deneyip karşılaştırın):
SELECT KitapAdi, SayfaSayisi, YayinYili
FROM Kitaplar
WHERE KategoriID = 1
  AND SayfaSayisi < 200 OR YayinYili > 2000;
-- AND önce çalıştığı için Zamanın Daha Kısa Tarihi ve
-- Osmanlı'yı Yeniden Keşfetmek de (roman olmadıkları halde) gelir.

-- 5.3  LIKE + BETWEEN + karşılaştırma birlikte:
--      Adında "a" geçen, 1940-2000 arasında yayımlanmış, stoku 2+ olan kitaplar
SELECT KitapAdi, YayinYili, StokAdedi
FROM Kitaplar
WHERE KitapAdi LIKE N'%a%'
  AND YayinYili BETWEEN 1940 AND 2000
  AND StokAdedi >= 2;

-- 5.4  Tarih + LIKE: Eylül'de ödünç alıp HENÜZ iade etmemiş,
--      e-postası "e" harfiyle başlayan üyeler (WHERE ile birleştirme)
SELECT u.Ad, u.Soyad, u.Eposta, o.OduncTarihi
FROM Oduncler AS o, Uyeler AS u
WHERE o.UyeID = u.UyeID
  AND o.OduncTarihi BETWEEN '2026-09-01' AND '2026-09-30'
  AND o.IadeTarihi IS NULL
  AND u.Eposta LIKE N'e%';
-- Beklenen: Emre Koç

-- 5.5  NOT ile koşulu tersine çevirme
SELECT KitapAdi, YayinYili
FROM Kitaplar
WHERE NOT (YayinYili BETWEEN 1900 AND 2000);
-- Beklenen: Suç ve Ceza (1866), Zamanın Daha Kısa Tarihi (2005),
--           Osmanlı'yı Yeniden Keşfetmek (2006), Kırmızı Saçlı Kadın (2016)
--           (Devlet yine YOK - NULL!)
GO


/* =====================================================================
   ÖĞRENCİ ALIŞTIRMALARI (cevapları kendiniz yazın)
   ===================================================================== */
-- A1. Soyadı "n" harfiyle biten yazarları listeleyin.
-- A2. Adı 5 harfli olan üyeleri bulun.
-- A3. 1 Ekim 2026 - 13 Ekim 2026 arasında teslim tarihi olan ödünçleri listeleyin.
-- A4. 250 ile 350 sayfa arasındaki kitapları sayfa sayısına göre sıralayın.
-- A5. Adı sesli harfle (A, E, I, O, U) başlayan yazarları bulun.
-- A6. Stoku 2'den fazla OLAN ya da 1950'den önce yayımlanmış kitapları listeleyin.
-- A7. E-posta adresinde "." karakterinden önce 5 veya daha az harf olan üyeleri bulun.
--     (İpucu: '_____.%' gibi desenler deneyin; tek desen yetmeyebilir.)
