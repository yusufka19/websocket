import 'package:flutter/material.dart';
import 'dart:async';
import '../models/football_team.dart';
import '../services/websocket_service.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final String opponentName;
  final Function(bool won, int scoreChange) onGameEnd;

  const GameScreen({
    super.key,
    required this.playerName,
    required this.opponentName,
    required this.onGameEnd,
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
  final WebSocketService _webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    _webSocketService.onGameUpdate = (data) {
      print('Game update alındı: ${data['update_type']}');
      print('Data: $data');
      
      setState(() {
        switch (data['update_type']) {
          case 'team_confirmed':
            // Takım seçimi onaylandı, bekleme durumuna geç
            statusMessage = 'Takım seçildi: ${data['team']}\nRakip bekleniyor...';
            break;
          case 'team_display':
            // Takım gösterim fazı
            currentPhase = GamePhase.teamDisplay;
            selectedTeam = data['playerTeam'];
            opponentTeam = data['opponentTeam'];
            timeLeft = (data['timeLimit'] / 1000).round();
            statusMessage = 'Seçilen Takımlar:\nSen: $selectedTeam\nRakip: $opponentTeam';
            _startTimer();
            break;
          case 'game_started':
            // Oyun başladı - soru geldi
            currentPhase = GamePhase.playing;
            currentQuestion = data['question'];
            timeLeft = (data['timeLimit'] / 1000).round();
            statusMessage = 'İlk doğru cevabı veren kazanır!';
            playerAnswer = null;
            opponentAnswer = null;
            _answerController.clear();
            _startTimer();
            break;
          case 'game_finished':
            // Oyun bitti
            _handleGameFinished(data);
            break;
        }
      });
    };
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
    
    switch (currentPhase) {
      case GamePhase.teamSelection:
        if (selectedTeam == null) {
          // Rastgele takım seç
          selectedTeam = FootballTeam.teams.first.name;
          _webSocketService.selectTeam(selectedTeam!);
        }
        setState(() {
          statusMessage = 'Zaman doldu! Rakip bekleniyor...';
        });
        break;
      case GamePhase.teamDisplay:
        // Takım gösterimi bitti, oyun başlayacak
        setState(() {
          statusMessage = 'Oyun başlıyor...';
        });
        break;
      case GamePhase.playing:
        // Oyun zaman aşımı - kimse doğru cevaplayamadı
        setState(() {
          currentPhase = GamePhase.finished;
          statusMessage = 'Zaman doldu! Kimse doğru cevaplayamadı.';
          timeLeft = 5;
        });
        _startTimer();
        break;
      case GamePhase.finished:
        _endGame();
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
    setState(() {
      playerAnswer = answer.isNotEmpty ? answer : 'Zaman doldu';
      statusMessage = 'Cevap gönderildi, sonuç bekleniyor...';
    });
    
    if (answer.isNotEmpty) {
      _webSocketService.submitAnswer(answer);
    }
  }

  void _handleGameFinished(Map<String, dynamic> result) {
    print('Game finished: $result');
    
    final winner = result['winner'];
    final correctAnswer = result['correctAnswer'];
    final won = winner == widget.playerName || winner == 'Player';
    
    setState(() {
      currentPhase = GamePhase.finished;
      gameEnded = true;
      timeLeft = 5;
      
      if (winner == null || winner == 'No one') {
        statusMessage = 'Oyun Bitti!\nKimse doğru cevaplayamadı\nDoğru cevap: $correctAnswer';
      } else {
        statusMessage = 'Oyun Bitti!\n${won ? "Kazandın!" : "Kaybettin!"}\nKazanan: $winner\nDoğru cevap: $correctAnswer';
      }
    });
    
    _startTimer();
    widget.onGameEnd(won, won ? 10 : 0);
  }

  void _endGame() {
    _timer?.cancel();
    Navigator.pop(context);
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green[700]!,
              Colors.green[400]!,
            ],
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
    switch (currentPhase) {
      case GamePhase.teamSelection:
        return _buildTeamSelection();
      case GamePhase.teamDisplay:
        return _buildTeamDisplay();
      case GamePhase.playing:
        return _buildGamePlay();
      case GamePhase.finished:
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
                child: ElevatedButton(
                  onPressed: _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              gameEnded 
                ? (statusMessage.contains('Kazandın') ? Icons.celebration : Icons.sentiment_dissatisfied)
                : Icons.timer_off,
              size: 64,
              color: gameEnded 
                ? (statusMessage.contains('Kazandın') ? Colors.green : Colors.red)
                : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              statusMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _endGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }
}
