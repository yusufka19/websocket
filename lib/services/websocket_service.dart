import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Function(String)? onMatchFound;
  Function(Map<String, dynamic>)? onGameUpdate;
  
  // Message buffer for messages received before callbacks are set
  List<Map<String, dynamic>> _messageBuffer = [];
  bool _callbacksReady = false;
  
  // Railway deployment sonrası bu URL güncellenecek
  // Test için localhost kullanıyoruz
  // static const String _serverUrl = 'ws://10.0.2.2:8080';
  
  // Production URL - Railway deployed WebSocket server
  static const String _serverUrl = 'wss://websocket-production-85df.up.railway.app';
  
  void setCallbacks({
    Function(String)? onMatchFound,
    Function(Map<String, dynamic>)? onGameUpdate,
  }) {
    print('=== CALLBACKS AYARLANIYOR ===');
    this.onMatchFound = onMatchFound;
    this.onGameUpdate = onGameUpdate;
    print('onMatchFound null mu: ${this.onMatchFound == null}');
    print('onGameUpdate null mu: ${this.onGameUpdate == null}');
    print('Buffer\'da ${_messageBuffer.length} mesaj var');
    
    // Process buffered messages immediately
    if (_messageBuffer.isNotEmpty) {
      print('Buffer\'dan mesajlar işleniyor...');
      List<Map<String, dynamic>> messagesToProcess = List.from(_messageBuffer);
      _messageBuffer.clear();
      
      for (var message in messagesToProcess) {
        print('Buffer\'dan mesaj işleniyor: ${message['type']}');
        _processMessage(message);
      }
    }
    
    _callbacksReady = true;
    print('=== CALLBACKS AYARLANDI ===');
  }
  
  void connect() {
    try {
      _channel = IOWebSocketChannel.connect(_serverUrl);
      _listen();
    } catch (e) {
      print('WebSocket bağlantı hatası: $e');
      // Test ortamında bağlantı hatası olabilir
    }
  }
  
  void _listen() {
    _channel?.stream.listen(
      (data) {
        try {
          final message = jsonDecode(data);
          _handleMessage(message);
        } catch (e) {
          print('Mesaj parse hatası: $e');
        }
      },
      onError: (error) {
        print('WebSocket hatası: $error');
      },
      onDone: () {
        print('WebSocket bağlantısı kapandı');
      },
    );
  }
  
  void _handleMessage(Map<String, dynamic> message) {
    print('WebSocket mesajı alındı: ${message['type']}');
    print('Mesaj içeriği: $message');
    print('_callbacksReady: $_callbacksReady');
    
    // If callbacks are not ready, buffer the message
    if (!_callbacksReady) {
      print('Callback\'ler hazır değil, mesaj buffer\'a ekleniyor');
      _messageBuffer.add(message);
      print('Buffer\'a eklendikten sonra toplam: ${_messageBuffer.length}');
      return;
    }
    
    print('Callback\'ler hazır, mesaj direkt işleniyor');
    _processMessage(message);
  }
  
  void _processMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'match_found':
        print('MATCH_FOUND işleniyor - onMatchFound null mu: ${onMatchFound == null}');
        onMatchFound?.call(message['opponent'] ?? 'Bilinmeyen Rakip');
        break;
      case 'team_selected_confirm':
        // Takım seçimi onaylandı
        onGameUpdate?.call({
          'update_type': 'team_confirmed',
          'team': message['team']
        });
        break;
      case 'team_display':
        // Takım gösterim fazı
        print('TEAM_DISPLAY işleniyor - onGameUpdate null mu: ${onGameUpdate == null}');
        onGameUpdate?.call({
          'update_type': 'team_display',
          'playerTeam': message['playerTeam'],
          'opponentTeam': message['opponentTeam'],
          'timeLimit': message['timeLimit']
        });
        break;
      case 'game_started':
        // Oyun başladı - soru geldi
        print('GAME_STARTED - WebSocket servisinde işleniyor');
        print('onGameUpdate callback null mu: ${onGameUpdate == null}');
        onGameUpdate?.call({
          'update_type': 'game_started',
          'questionText': message['questionText'],
          'teams': message['teams'],
          'timeLimit': message['timeLimit']
        });
        print('GAME_STARTED - callback çağrıldı');
        break;
      case 'game_finished':
        // Oyun bitti
        print('GAME_FINISHED - WebSocket servisinde işleniyor');
        print('Winner: ${message['winner']}');
        print('Won: ${message['won']}');
        print('onGameUpdate callback null mu: ${onGameUpdate == null}');
        onGameUpdate?.call({
          'update_type': 'game_finished',
          'winner': message['winner'],
          'won': message['won'],
          'points': message['points'], // Puan bilgisi ekle
          'questionText': message['questionText'],
          'playerTeam': message['playerTeam'],
          'opponentTeam': message['opponentTeam']
        });
        print('GAME_FINISHED - callback çağrıldı');
        break;
      case 'wrong_answer':
        // Yanlış cevap bildirimi
        print('WRONG_ANSWER - WebSocket servisinde işleniyor');
        onGameUpdate?.call({
          'update_type': 'wrong_answer',
          'message': message['message']
        });
        print('WRONG_ANSWER - callback çağrıldı');
        break;
      default:
        print('Bilinmeyen mesaj tipi: ${message['type']}');
        // Diğer mesajları da game_update olarak işle
        onGameUpdate?.call(message);
    }
  }
  
  void findMatch(String playerName) {
    final message = {
      'type': 'find_match',
      'player_name': playerName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _sendMessage(message);
  }
  
  void selectTeam(String teamName) {
    final message = {
      'type': 'team_selected',
      'team': teamName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _sendMessage(message);
  }
  
  void submitAnswer(String answer) {
    final message = {
      'type': 'player_answer',
      'answer': answer,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _sendMessage(message);
  }
  
  void _sendMessage(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
    }
  }
  
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
