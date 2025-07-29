# Railway Deployment Guide

## Railway'e WebSocket Server Deploy Etme

### 1. Railway Hesabı
1. [railway.app](https://railway.app) adresine gidin
2. GitHub hesabınızla giriş yapın
3. Ücretsiz plan ile başlayabilirsiniz

### 2. Proje Hazırlığı
Bu dosyalar Railway deployment için hazır:
- ✅ `package.json` - Dependencies ve scripts
- ✅ `websocket_server.js` - PORT environment variable desteği
- ✅ `.gitignore` - Railway ve Node.js için optimize edilmiş

### 3. GitHub Repository Oluşturma
```bash
# Bu klasörde terminal açın
git init
git add .
git commit -m "Initial commit for Railway deployment"

# GitHub'da yeni repository oluşturun ve bağlayın
git remote add origin https://github.com/KULLANICI_ADI/football-quiz-server.git
git branch -M main
git push -u origin main
```

### 4. Railway'de Deploy
1. Railway dashboard'da "New Project" tıklayın
2. "Deploy from GitHub repo" seçin
3. Repository'nizi seçin
4. Railway otomatik olarak Node.js projesi algılayacak
5. Deploy işlemi başlayacak

### 5. Domain Alıma
1. Deploy bittikten sonra project settings'e gidin
2. "Domains" sekmesine tıklayın
3. "Generate Domain" butonu ile ücretsiz .railway.app domain alın
4. Domain şu şekilde olacak: `your-project-name.up.railway.app`

### 6. Flutter Uygulamasını Güncelleme
Deploy edilen domain'i kullanarak Flutter uygulamasında WebSocket URL'ini güncelleyin:

```dart
// lib/services/websocket_service.dart dosyasında
static const String _serverUrl = 'wss://your-project-name.up.railway.app';
```

**Not**: Railway otomatik olarak HTTPS/WSS sağlar, bu yüzden `wss://` kullanın.

### 7. Test
1. Flutter uygulamasını yeniden build edin: `flutter build apk --release`
2. Gerçek cihazda test edin
3. İki farklı cihazda eşleşme test edin

### 8. Railway Monitoring
- Railway dashboard'da logs, metrics ve resource usage görebilirsiniz
- Ücretsiz plan ile aylık $5 değerinde usage hakkınız var
- WebSocket server çok az resource kullanır

### 9. Production Tips
- Environment variables ekleyebilirsiniz
- Custom domain bağlayabilirsiniz
- Auto-scaling varsayılan olarak aktif
- Database eklemek isterseniz Railway PostgreSQL sağlar

## Costs
- **Ücretsiz Tier**: $5/ay credit (WebSocket server için yeterli)
- **Paid Plan**: $5/ay minimum, sadece kullandığınız kadar ödeme

## Support
Railway çok iyi dokümantasyona sahip: https://docs.railway.app
