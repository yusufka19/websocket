<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Football Quiz App - Flutter Project

Bu proje Flutter kullanılarak geliştirilmiş bir futbol bilgi yarışması uygulamasıdır.

## Proje Özellikleri

- **Giriş Sistemi**: Google Sign-In entegrasyonu ve misafir girişi
- **Eşleştirme Sistemi**: WebSocket tabanlı gerçek zamanlı oyuncu eşleştirme
- **Oyun Mekaniği**: 
  - 10 saniye takım seçimi
  - Futbolcu tahmin etme yarışması
  - Puan sistemi (+10/-10)
- **Responsive Design**: Material Design 3 kullanımı

## Teknolojiler

- Flutter 3.0+
- Dart 3.0+
- WebSocket bağlantıları
- Google Sign-In
- SharedPreferences
- Material Design 3

## Kod Yapısı

- `lib/screens/`: Ekran bileşenleri
- `lib/services/`: Servis katmanı (WebSocket, vb.)
- `lib/models/`: Veri modelleri
- `lib/widgets/`: Yeniden kullanılabilir widget'lar

## Geliştirme Notları

- WebSocket server adresi test için localhost:8080 olarak ayarlanmıştır
- Gerçek üretim ortamında server IP'si güncellenmelidir
- Google Sign-In için Firebase yapılandırması gereklidir
- Oyun simülasyonu test amaçlı rastgele sonuçlar üretir

## Code Style

- Material Design guidelines takip edin
- Flutter best practices uygulayın
- Async/await pattern kullanın
- Proper error handling uygulayın
- Widget composition tercih edin
