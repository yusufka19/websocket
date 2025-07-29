# Football Quiz WebSocket Server

WebSocket server for real-time multiplayer football quiz game built with Flutter.

## Features

- **Real-time multiplayer matching**
- **Team selection system** 
- **Transfer player questions**
- **Bot opponents** when no real players available
- **Scoring system** (+10 points for correct answers, -10 for wrong)
- **Persistent game results**

## Tech Stack

- **Node.js** - Runtime environment
- **WebSocket (ws)** - Real-time communication
- **Railway** - Cloud deployment platform

## Local Development

```bash
# Install dependencies
npm install

# Start server
npm start
```

Server will run on `http://localhost:8080`

## Railway Deployment

This server is configured for Railway deployment with:
- Dynamic PORT environment variable
- Optimized package.json
- Production-ready WebSocket handling

## API Endpoints

### WebSocket Events

#### Client → Server
- `find_match` - Join matchmaking queue
- `team_selected` - Select team for game
- `player_answer` - Submit answer to question

#### Server → Client  
- `match_found` - Opponent found
- `team_display` - Show selected teams
- `game_started` - Question sent
- `game_finished` - Game results
- `wrong_answer` - Invalid answer notification

## Game Flow

1. **Matchmaking** - Players join queue, matched with opponent or bot
2. **Team Selection** - 10 seconds to pick football team
3. **Question Phase** - 30 seconds to answer transfer question
4. **Results** - Winner announcement and score update

## Example Questions

- "Bu iki takımda da form giymiş bir oyuncu yazın: Barcelona - Real Madrid"
- Players must name a player who played for both teams

## Deployment URL

Once deployed on Railway: `wss://your-project.up.railway.app`

## Flutter Integration

Update WebSocket URL in Flutter app:
```dart
static const String _serverUrl = 'wss://your-railway-domain.up.railway.app';
```

## Support

For issues and support, please open an issue on GitHub.
