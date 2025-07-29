import 'package:flutter/material.dart';
import 'dart:async';
import '../models/football_team.dart';
import '../services/websocket_service.dart';
import 'home_screen.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final String opponentName;
  final Function(bool won, int scoreChange) onGameEnd;
  final WebSocketService webSocketService;
  final String userName;
  final String userEmail;
  final bool isGuest;

  const GameScreen({
    super.key,
    required this.playerName,
    required this.opponentName,
    required this.onGameEnd,
    required this.webSocketService,
    required this.userName,
    required this.userEmail,
    required this.isGuest,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum GamePhase { teamSelection, teamDisplay, playing, finished }

class _GameScreenState extends State<GameScreen> {
  GamePhase currentPhase = GamePhase.teamSelection;
  int timeLeft = 10;
  Timer? _timer;
  
  String? selectedTeam;
  String? opponentTeam;
  String? currentQuestion;
  String? playerAnswer;
  String? opponentAnswer;
  bool gameEnded = false;
  String statusMessage = 'Takım seçin';
  
  final TextEditingController _answerController = TextEditingController();
  late final WebSocketService _webSocketService;

  @override
  void initState() {
    super.initState();
    print('GameScreen başlatılıyor...');
    _webSocketService = widget.webSocketService;
    _setupWebSocketListeners(); // Callback'leri ayarla
    _startTimer();
  }

  void _setupWebSocketListeners() {
    print('WebSocket listeners kuruluyor...');
    
    // Yeni callback atama yöntemi
    _webSocketService.setCallbacks(
      onMatchFound: (opponentName) {
        print('Match found callback - rakip: $opponentName');
        // Match found işlemi zaten home_screen'de yapılıyor
      },
      onGameUpdate: (data) {
        print('=== GAME SCREEN ===');
        print('Game update alındı: ${data['update_type']}');
        print('Data: $data');
        print('Mevcut phase: $currentPhase');
        
        setState(() {
          switch (data['update_type']) {
            case 'team_confirmed':
              print('Team confirmed işleniyor...');
              // Takım seçimi onaylandı, bekleme durumuna geç
              statusMessage = 'Takım seçildi: ${data['team']}\nRakip bekleniyor...';
              break;
            case 'team_display':
              print('Team display işleniyor...');
              // Takım gösterim fazı
              currentPhase = GamePhase.teamDisplay;
              selectedTeam = data['playerTeam'];
              opponentTeam = data['opponentTeam'];
              timeLeft = (data['timeLimit'] / 1000).round();
              statusMessage = 'Seçilen Takımlar:\nSen: $selectedTeam\nRakip: $opponentTeam';
              _startTimer();
              print('Phase değişti: $currentPhase');
              break;
            case 'game_started':
              print('GAME_STARTED - Game Screen\'de işleniyor');
              print('Eski phase: $currentPhase');
              // Oyun başladı - futbolcu tahmin etme fazı
              currentPhase = GamePhase.playing;
              currentQuestion = data['questionText'];
              timeLeft = (data['timeLimit'] / 1000).round();
              statusMessage = 'Her iki takımda da oynamış futbolcu yazın!';
              playerAnswer = null;
              opponentAnswer = null;
              _answerController.clear();
              _startTimer();
              print('Yeni phase: $currentPhase');
              print('Question: $currentQuestion');
              break;
            case 'game_finished':
              print('Game finished işleniyor...');
              print('Mevcut phase ÖNCE: $currentPhase');
              // Oyun bitti
              _handleGameFinished(data);
              print('Mevcut phase SONRA: $currentPhase');
              break;
            case 'wrong_answer':
              print('Yanlış cevap bildirimi alındı');
              // Yanlış cevap bildirimi - kullanıcıya göster
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(data['message'] ?? 'Cevabınız yanlış! Tekrar deneyin.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
              // Input field'ı temizle
              _answerController.clear();
              break;
            default:
              print('Bilinmeyen update_type: ${data['update_type']}');
          }
        });
        print('setState tamamlandı. Yeni phase: $currentPhase');
      },
    );
    print('WebSocket listeners kuruldu.');
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
      });
      
      if (timeLeft <= 0) {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    _timer?.cancel();
    print('_handleTimeUp çağrıldı, mevcut phase: $currentPhase');
    
    switch (currentPhase) {
      case GamePhase.teamSelection:
        print('Takım seçim süresi doldu');
        if (selectedTeam == null) {
          // Rastgele takım seç
          selectedTeam = FootballTeam.teams.first.name;
          _webSocketService.selectTeam(selectedTeam!);
          print('Rastgele takım seçildi: $selectedTeam');
        }
        setState(() {
          statusMessage = 'Zaman doldu! Rakip bekleniyor...';
        });
        // Kısa bir süre sonra oyuna geçiş yapmaya zorla
        Timer(Duration(seconds: 2), () {
          if (currentPhase == GamePhase.teamSelection) {
            print('Zorla oyuna geçiş yapılıyor...');
            setState(() {
              currentPhase = GamePhase.playing;
              currentQuestion = 'Her iki takımda da oynamış futbolcu yazın!';
              timeLeft = 30;
              statusMessage = 'Her iki takımda da oynamış futbolcu yazın!';
            });
            _startTimer();
          }
        });
        break;
      case GamePhase.teamDisplay:
        print('Takım gösterim süresi doldu');
        // Takım gösterimi bitti, oyuna geçiş yap
        setState(() {
          currentPhase = GamePhase.playing;
          currentQuestion = 'Her iki takımda da oynamış futbolcu yazın!';
          timeLeft = 30;
          statusMessage = 'Her iki takımda da oynamış futbolcu yazın!';
        });
        _startTimer();
        print('Oyun fazına geçildi');
        break;
      case GamePhase.playing:
        print('Oyun süresi doldu');
        // Oyun zaman aşımı - kimse doğru cevaplayamadı
        setState(() {
          currentPhase = GamePhase.finished;
          statusMessage = 'Zaman doldu! Kimse doğru cevaplayamadı.';
          // Timer artık başlatılmıyor - oyuncu istediği kadar kalabilir
        });
        break;
      case GamePhase.finished:
        print('Oyun bitiriliyor - WebSocket bağlantısı kapatılıyor');
        // WebSocket bağlantısını kapat ama navigation yapmadan kalsın
        _timer?.cancel();
        _webSocketService.disconnect();
        print('WebSocket bağlantısı kapandı - oyuncu kazandınız/kaybettiniz ekranında kalıyor');
        break;
    }
  }

  void _selectTeam(String teamName) {
    setState(() {
      selectedTeam = teamName;
      statusMessage = 'Takım seçiliyor...';
    });
    _webSocketService.selectTeam(teamName);
  }

  void _submitAnswer() {
    final answer = _answerController.text.trim();
    print('=== CEVAP GÖNDERİLİYOR ===');
    print('Cevap: $answer');
    print('Mevcut phase: $currentPhase');
    
    setState(() {
      playerAnswer = answer.isNotEmpty ? answer : 'Zaman doldu';
      statusMessage = 'Cevap gönderildi, sonuç bekleniyor...';
    });
    
    if (answer.isNotEmpty) {
      _webSocketService.submitAnswer(answer);
      // Cevap verildi, zamanı durdur
      _timer?.cancel();
      print('Timer durduruldu - cevap gönderildi');
    }
    print('=== CEVAP GÖNDERİM BİTTİ ===');
  }

  void _handleGameFinished(Map<String, dynamic> result) {
    print('=== _handleGameFinished BAŞLADI ===');
    print('Game finished: $result');
    print('Mevcut currentPhase: $currentPhase');
    print('Timer aktif mi: ${_timer?.isActive}');
    print('Widget mounted: $mounted');
    
    // Widget unmounted ise işlemi durdur
    if (!mounted) {
      print('UYARI: Widget unmounted, işlem durduruluyor');
      return;
    }
    
    // Önce timer'ı durdur
    _timer?.cancel();
    print('Timer durduruldu');
    
    final winner = result['winner'];
    final won = result['won'] ?? false; // Server'dan gelen won bilgisini kullan
    final points = result['points'] ?? 0; // Puan bilgisi
    
    print('Winner: $winner, Won: $won');
    print('Points: $points');
    
    // UI güncellemeyi frame callback ile zorla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('PostFrameCallback içinde setState çağrılıyor');
        setState(() {
          print('setState BAŞLADI - phase değiştiriliyor');
          currentPhase = GamePhase.finished;
          gameEnded = true;
          // Timer kaldırıldı - oyuncu istediği kadar bekleyebilir
          
          if (winner == null || winner == 'No one') {
            statusMessage = '⏰ SÜRE DOLDU! ⏰\nKimse doğru cevaplayamadı\nPuan: $points';
          } else if (won) {
            // Kullanıcı kazandı - hemen göster
            statusMessage = '🎉 TEBRİKLER! 🎉\nKAZANDINIZ!\nPuan: +$points';
          } else {
            // Kullanıcı kaybetti - hemen göster
            statusMessage = '😞 KAYBETTİNİZ! 😞\nRAKİP KAZANDI!\nPuan: $points';
          }
          print('setState BİTTİ - yeni phase: $currentPhase');
          print('Status message: $statusMessage');
        });
        
        // Timer kaldırıldı - oyuncu manuel olarak "Ana Menüye Dön" butonunu kullanacak
        widget.onGameEnd(won, points);
        print('UI güncelleme tamamlandı');
      } else {
        print('UYARI: PostFrameCallback içinde widget unmounted');
      }
    });
    
    print('=== _handleGameFinished BİTTİ ===');
  }

  void _navigateToHome() {
    print('Ana sayfaya yönlendiriliyor...');
    
    // Ana sayfaya dön - stack'i temizle ve HomeScreen'e yönlendir
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomeScreen(
        userName: widget.userName,
        userEmail: widget.userEmail,
        isGuest: widget.isGuest,
      )),
      (Route<dynamic> route) => false, // Tüm önceki route'ları temizle
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _webSocketService.disconnect();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.playerName} vs ${widget.opponentName}'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/football_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Zamanlayıcı
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$timeLeft',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: timeLeft <= 5 ? Colors.red : Colors.green[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Status mesajı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Faz-based content
                Expanded(
                  child: _buildPhaseContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent() {
    print('=== _buildPhaseContent ÇAĞRILDI ===');
    print('currentPhase: $currentPhase');
    
    switch (currentPhase) {
      case GamePhase.teamSelection:
        print('Team selection UI gösteriliyor');
        return _buildTeamSelection();
      case GamePhase.teamDisplay:
        print('Team display UI gösteriliyor');
        return _buildTeamDisplay();
      case GamePhase.playing:
        print('Game play UI gösteriliyor');
        return _buildGamePlay();
      case GamePhase.finished:
        print('Game finished UI gösteriliyor');
        return _buildGameFinished();
    }
  }

  Widget _buildTeamSelection() {
    return Column(
      children: [
        const Text(
          'Takımını Seç',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: FootballTeam.teams.length,
            itemBuilder: (context, index) {
              final team = FootballTeam.teams[index];
              final isSelected = selectedTeam == team.name;
              
              return GestureDetector(
                onTap: () => _selectTeam(team.name),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.orange[700]! : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      team.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Seçilen Takımlar',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          _buildTeamCard('Sen', selectedTeam ?? '', Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'VS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildTeamCard('Rakip', opponentTeam ?? '', Colors.red),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String label, String teamName, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            teamName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamePlay() {
    return Column(
      children: [
        // Soru
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            currentQuestion ?? 'Soru yükleniyor...',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        
        // Cevap input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  hintText: 'Cevabınızı yazın...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: const TextStyle(fontSize: 16),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green[600]!, Colors.green[800]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.green[400]!,
                      width: 1,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cevabı Gönder',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Cevap durumu
        if (playerAnswer != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Senin cevabın: $playerAnswer',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGameFinished() {
    print('=== _buildGameFinished ÇAĞRILDI ===');
    print('statusMessage: "$statusMessage"');
    
    // Kazanan/kaybeden durumunu kontrol et
    bool isWinner = statusMessage.contains('TEBRİKLER') || statusMessage.contains('KAZANDINIZ');
    bool isLoser = statusMessage.contains('MAKALESİNİZ') || statusMessage.contains('RAKİP KAZANDI');
    
    print('isWinner: $isWinner, isLoser: $isLoser');
    
    Color backgroundColor;
    Color iconColor;
    IconData icon;
    
    if (isWinner) {
      backgroundColor = Colors.green.withOpacity(0.95);
      iconColor = Colors.green[700]!;
      icon = Icons.celebration;
    } else if (isLoser) {
      backgroundColor = Colors.red.withOpacity(0.95);
      iconColor = Colors.red[700]!;
      icon = Icons.sentiment_dissatisfied;
    } else {
      backgroundColor = Colors.white.withOpacity(0.95);
      iconColor = Colors.orange;
      icon = Icons.timer_off;
    }
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWinner ? Colors.green[700]! : 
                   isLoser ? Colors.red[700]! : Colors.orange,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              statusMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isWinner ? Colors.white :
                       isLoser ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isWinner ? [Colors.green[700]!, Colors.green[900]!] :
                         isLoser ? [Colors.red[600]!, Colors.red[800]!] : 
                         [Colors.green[600]!, Colors.green[800]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: (isWinner ? Colors.green : 
                           isLoser ? Colors.red : Colors.green).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(-2, -2),
                  ),
                ],
                border: Border.all(
                  color: isWinner ? Colors.green[400]! :
                         isLoser ? Colors.red[400]! : Colors.green[400]!,
                  width: 1,
                ),
              ),
              child: ElevatedButton(
                onPressed: _navigateToHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Ana Menüye Dön',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
