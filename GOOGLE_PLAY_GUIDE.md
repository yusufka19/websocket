# Football Quiz - Google Play Deployment Guide

## Gerekli Değişiklikler

### 1. WebSocket Server Deploy Etme
Bu uygulama gerçek zamanlı multiplayer oyun için WebSocket server gerektirir.

#### Server Options:
- **Heroku**: Ücretsiz hosting (sınırlı)
- **AWS EC2**: Ölçeklenebilir
- **DigitalOcean Droplets**: Uygun fiyatlı
- **Google Cloud Platform**: Flutter uyumlu

#### Server Deploy Adımları:
1. `websocket_server.js` dosyasını seçtiğiniz cloud service'e deploy edin
2. SSL sertifikası alın (wss:// için gerekli)
3. Server URL'ini `lib/services/websocket_service.dart` dosyasında güncelleyin:
   ```dart
   static const String _serverUrl = 'wss://your-domain.com:8080';
   ```

### 2. Google Play Store İçin Hazırlık

#### Gerekli Dosyalar:
- ✅ `app-release.apk` (build/app/outputs/flutter-apk/)
- ✅ App logo ve screenshots
- ✅ Privacy Policy (gerekli)
- ✅ Store listing metinleri

#### App Bundle (Önerilen):
Debug symbols sorunu çözüldükten sonra:
```bash
flutter build appbundle --release
```

### 3. Güvenlik ve Privacy

#### Internet Permission:
✅ AndroidManifest.xml'de INTERNET permission zaten mevcut

#### Privacy Policy:
WebSocket bağlantısı ve kullanıcı verileri için privacy policy oluşturmanız gerekli.

### 4. Test

#### Gerçek Cihazlarda Test:
1. Release APK'yı gerçek cihazlara yükleyin
2. Server bağlantısını test edin
3. Multiplayer işlevselliğini doğrulayın

#### Beta Testing:
Google Play Console'da internal testing grubu oluşturun.

### 5. Store Listing Önerileri

#### Başlık:
"Football Quiz - Real Time"

#### Açıklama:
"Gerçek zamanlı futbol bilgi yarışması! Dünyadaki oyuncularla eşleş, takımını seç ve transfer bilgini test et. Hızlı tempolu sorular, gerçek zamanlı puan sistemi ve rekabetçi oynanış."

#### Keywords:
- futbol
- quiz
- bilgi yarışması
- multiplayer
- gerçek zamanlı
- transfer
- takım

### 6. Monetization (İsteğe Bağlı)
- AdMob entegrasyonu
- In-app purchases
- Premium özelliktentifier

### Server Cost Estimation:
- Heroku Hobby: $7/ay
- DigitalOcean Droplet: $5/ay
- AWS t2.micro: ~$8/ay

## Son Kontrol Listesi

- [ ] Server deploy edildi ve SSL aktif
- [ ] WebSocket URL güncellendi
- [ ] App release modda build edildi
- [ ] Privacy policy hazırlandı
- [ ] Google Play Developer hesabı açıldı ($25 bir kerelik)
- [ ] Store listing tamamlandı
- [ ] Test edildi

## Destek

Teknik destek için GitHub repository'yi kullanın.
