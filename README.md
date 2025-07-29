# Football Quiz App

Flutter ile geliştirilmiş gerçek zamanlı futbol bilgi yarışması uygulaması.

## Özellikler

- 🔐 **Güvenli Giriş**: Google Play ile giriş veya misafir modunda oynama
- 🎯 **Gerçek Zamanlı Eşleştirme**: WebSocket ile anlık oyuncu eşleştirme
- ⚽ **Takım Seçimi**: 10 saniyede favori takımınızı seçin
- 🏆 **Yarışma Modu**: Futbolcu bilginizi test edin ve puan kazanın
- 📊 **Puan Sistemi**: Kazanılan/kaybedilen puanları takip edin

## Nasıl Oynanır

1. **Giriş Yapın**: Google hesabınızla giriş yapın veya misafir olarak oynayın
2. **Maç Bulun**: Ana ekranda "Maç Bul" butonuna tıklayın
3. **Takım Seçin**: 10 saniye içinde bir futbol takımı seçin
4. **Yarışın**: Seçilen takımlardan futbolcu adı yazma yarışına katılın
5. **Puan Kazanın**: İlk doğru cevabı veren +10 puan alır

## Teknical Stack

- **Framework**: Flutter 3.0+
- **Language**: Dart 3.0+
- **Authentication**: Google Sign-In
- **Real-time Communication**: WebSocket
- **Local Storage**: SharedPreferences
- **UI**: Material Design 3

## Gereksinimler

- Flutter SDK (3.0.0 veya üzeri)
- Dart SDK (3.0.0 veya üzeri)
- Android Studio / VS Code
- Android SDK (API 21+)

## Kurulum

1. Repoyu klonlayın:
```bash
git clone <repo-url>
cd football_quiz_app
```

2. Dependencies'leri yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:
```bash
flutter run
```

## Yapılandırma

### Google Sign-In Setup
1. [Firebase Console](https://console.firebase.google.com/)'da yeni proje oluşturun
2. Android uygulaması ekleyin (package name: `com.example.football_quiz_app`)
3. `google-services.json` dosyasını `android/app/` klasörüne ekleyin

### WebSocket Server
- Test ortamında: `ws://localhost:8080`
- Production için server URL'ini `lib/services/websocket_service.dart` dosyasında güncelleyin

## Proje Yapısı

```
lib/
├── main.dart                 # Ana uygulama giriş noktası
├── models/
│   └── football_team.dart    # Futbol takımı veri modeli
├── screens/
│   ├── login_screen.dart     # Giriş ekranı
│   ├── home_screen.dart      # Ana sayfa
│   └── game_screen.dart      # Oyun ekranı
├── services/
│   └── websocket_service.dart # WebSocket iletişim servisi
└── widgets/                  # Yeniden kullanılabilir bileşenler
```

## Geliştirme Notları

- WebSocket bağlantısı test amaçlı simüle edilmiştir
- Gerçek üretim ortamında backend server gereklidir
- Oyun mekaniği şu anda rastgele sonuçlar üretmektedir
- Firebase yapılandırması Google Sign-In için gereklidir

## Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## İletişim

Sorularınız için: [your-email@example.com]

---

⚽ **Football Quiz** - Futbol bilginizi test edin!
