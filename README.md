# CLI-Deleter

Bash ile yazılmış, terminal üzerinden dosyaları kolayca seçip toplu halde silmenizi sağlayan etkileşimli bir arayüz aracıdır.

## Özellikler

- **Görsel Seçim:** Dosyaları Boşluk tuşu ile işaretleyip toplu silme.
- **Renkli Liste:** Klasör, script ve arşiv dosyaları için farklı renkler.
- **Hızlı Navigasyon:** Ok tuşları ile dizinler arası geçiş (Sağ: Gir, Sol: Çık).
- **Güvenlik:** Kritik sistem dizinlerinin silinmesini engelleyen koruma.
- **Hafif:** Sadece Bash kullanır, ek kütüphane gerektirmez.

## Kontroller

- **Ok Tuşları**: Gezinme ve dizinlere giriş/çıkış.
- **Boşluk (Space)**: Dosyayı silmek için işaretle / kaldır.
- **Enter / Sağ Ok**: Seçili klasörün içine gir.
- **Sol Ok / Backspace**: Bir üst dizine çık.
- **D**: İşaretli dosyaları sil (Onay istenir).
- **Q**: Programdan çık.

## Kurulum

1. Dosyaya çalışma izni verin:
```bash
chmod +x deleter.sh
```
Her yerden çalıştırmak için sistem yoluna kopyalayın:
Bash

```bash
sudo cp deleter.sh /usr/local/bin/deleter
```
## Kullanım

Terminalde komutu yazmanız yeterlidir:
```bash
sudo cp deleter.sh /usr/local/bin/deleter
```
