import os

def agac_yapisini_yazdir(baslangic_dizini=".", on_ek="", yoksayilacak_klasorler=None, dosya=None):
    if yoksayilacak_klasorler is None:
        # Projelerde kalabalık yaratan, derleme veya versiyon kontrol klasörlerini atlıyoruz
        yoksayilacak_klasorler = {'.git', '.dart_tool', 'build', '__pycache__', 'venv', '.idea', 'node_modules'}

    try:
        icerikler = sorted(os.listdir(baslangic_dizini))
    except PermissionError:
        yazi = on_ek + "└── [Erişim Reddedildi]\n"
        if dosya:
            dosya.write(yazi)
        return

    # Yoksayılacak klasörleri listeden çıkar
    icerikler = [icerik for icerik in icerikler if icerik not in yoksayilacak_klasorler]
    eleman_sayisi = len(icerikler)

    for indeks, icerik in enumerate(icerikler):
        yol = os.path.join(baslangic_dizini, icerik)
        son_eleman_mi = (indeks == eleman_sayisi - 1)

        # Ağaç dallarını belirle
        baglayici = "└── " if son_eleman_mi else "├── "
        
        # Eğer klasörse isminin sonuna '/' ekle
        gosterilecek_isim = icerik + "/" if os.path.isdir(yol) else icerik
        
        yazi = on_ek + baglayici + gosterilecek_isim + "\n"
        if dosya:
            dosya.write(yazi)

        # Klasörün içine gir ve özyinelemeli (recursive) olarak devam et
        if os.path.isdir(yol):
            uzanti = "    " if son_eleman_mi else "│   "
            agac_yapisini_yazdir(yol, on_ek + uzanti, yoksayilacak_klasorler, dosya)

if __name__ == "__main__":
    cikti_dosya_adi = "file_tree.txt"
    
    # Dosyayı yazma modunda ('w') ve utf-8 formatında açıyoruz
    with open(cikti_dosya_adi, "w", encoding="utf-8") as f:
        baslik = f"Mevcut Dizin: {os.path.abspath('.')}\n\n"
        f.write(baslik)
        
        agac_yapisini_yazdir(dosya=f)
        
    print(f"İşlem tamam! Proje ağacı başarıyla '{cikti_dosya_adi}' dosyasına kaydedildi.")