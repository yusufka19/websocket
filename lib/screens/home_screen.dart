import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final bool isGuest;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.isGuest,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int userScore = 0;
  bool isSearchingMatch = false;
  WebSocketService? _webSocketService;

  @override
  void initState() {
    super.initState();
    _loadUserScore();
    _webSocketService = WebSocketService();
  }

  Future<void> _loadUserScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userScore = prefs.getInt('user_score') ?? 0;
    });
  }

  Future<void> _saveUserScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_score', score);
    setState(() {
      userScore = score;
    });
  }

  void _findMatch() {
    setState(() {
      isSearchingMatch = true;
    });

    // WebSocket bağlantısı başlat
    _webSocketService?.connect();
    _webSocketService?.onMatchFound = (opponentName) {
      setState(() {
        isSearchingMatch = false;
      });
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(
            playerName: widget.userName,
            opponentName: opponentName,
            onGameEnd: (won, scoreChange) {
              _saveUserScore(userScore + scoreChange);
            },
            webSocketService: _webSocketService!,
            userName: widget.userName,
            userEmail: widget.userEmail,
            isGuest: widget.isGuest,
          ),
        ),
      );
    };

    _webSocketService?.findMatch(widget.userName);

    // Test için 3 saniye sonra eşleşme simülasyonu
    Future.delayed(const Duration(seconds: 3), () {
      if (isSearchingMatch) {
        _webSocketService?.onMatchFound?.call('Test Rakip');
      }
    });
  }

  void _cancelSearch() {
    setState(() {
      isSearchingMatch = false;
    });
    _webSocketService?.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Football Quiz'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Sol taraftaki geri butonunu kaldır
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
              tooltip: 'Giriş ekranına dön',
            ),
          ],
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
                // Kullanıcı Bilgileri Kartı
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // App Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!widget.isGuest) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.userEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$userScore Puan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Maç Bul Butonu
                Expanded(
                  child: Center(
                    child: isSearchingMatch
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 4,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Rakip aranıyor...',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.transparent, Colors.white.withOpacity(0.1)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(-1, -1),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: OutlinedButton(
                                  onPressed: _cancelSearch,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('İptal Et'),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white, Colors.grey[100]!],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 15,
                                  offset: const Offset(-4, -4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _findMatch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.green[700],
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: const CircleBorder(),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 48,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Maç Bul',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ), // SafeArea closing
      ), // body Container closing
    ), // Scaffold closing
    ); // PopScope closing
  }

  @override
  void dispose() {
    _webSocketService?.disconnect();
    super.dispose();
  }
}
