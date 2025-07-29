const WebSocket = require('ws');

// Railway PORT environment variable kullan, yoksa 8080
const PORT = process.env.PORT || 8080;

const wss = new WebSocket.Server({ port: PORT });

let waitingPlayers = [];
let activeGames = new Map();

console.log(`Football Quiz WebSocket server started on port ${PORT}`);

wss.on('connection', (ws) => {
    console.log('New client connected');
    
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message.toString());
            console.log('Received:', data);
            
            switch(data.type) {
                case 'find_match':
                    handleFindMatch(ws, data);
                    break;
                case 'team_selected':
                    handleTeamSelection(ws, data);
                    break;
                case 'player_answer':
                    handlePlayerAnswer(ws, data);
                    break;
                default:
                    console.log('Unknown message type:', data.type);
            }
        } catch (error) {
            console.error('Error parsing message:', error);
        }
    });
    
    ws.on('close', () => {
        console.log('Client disconnected');
        // Remove from waiting players
        waitingPlayers = waitingPlayers.filter(player => player.ws !== ws);
    });
});

function handleFindMatch(ws, data) {
    const playerNumber = waitingPlayers.length + 1; // 1 or 2
    const player = {
        ws: ws,
        id: data.playerId || Math.random().toString(36).substr(2, 9),
        name: (data.player_name || data.playerName || 'Player') + ` ${playerNumber}`
    };
    
    console.log(`Player ${player.name} (${player.id}) is looking for a match`);
    
    // Check if there's a waiting player
    if (waitingPlayers.length > 0) {
        // Match with the first waiting player
        const opponent = waitingPlayers.shift();
        console.log(`Matching ${player.name} vs ${opponent.name}`);
        startMatch(player, opponent);
    } else {
        // Add to waiting list
        waitingPlayers.push(player);
        
        // Send searching message
        ws.send(JSON.stringify({
            type: 'searching',
            message: 'Rakip aranıyor...'
        }));
        
        // For testing: automatically create a bot opponent after 5 seconds if no match found
        setTimeout(() => {
            if (waitingPlayers.includes(player)) {
                const botPlayer = {
                    ws: null, // Bot doesn't have real WebSocket
                    id: 'bot_' + Math.random().toString(36).substr(2, 6),
                    name: 'Bot Rakip'
                };
                
                // Remove player from waiting list
                waitingPlayers = waitingPlayers.filter(p => p !== player);
                
                console.log(`${player.name} matched with bot after timeout`);
                startMatch(player, botPlayer);
            }
        }, 5000); // 5 second delay for more realistic matchmaking
    }
}

function startMatch(player1, player2) {
    const gameId = Math.random().toString(36).substr(2, 9);
    
    const game = {
        id: gameId,
        player1: { ...player1, score: 0, selectedTeam: null },
        player2: { ...player2, score: 0, selectedTeam: null },
        phase: 'team_selection', // team_selection, team_display, playing, finished
        teamSelectionTimer: null,
        teamDisplayTimer: null,
        gameTimer: null,
        currentQuestion: null
    };
    
    activeGames.set(gameId, game);
    
    // Notify both players about match found
    const matchFoundData = {
        type: 'match_found',
        gameId: gameId,
        opponent: player2.name,
        phase: 'team_selection',
        timeLimit: 10000 // 10 seconds for team selection
    };
    
    player1.ws.send(JSON.stringify(matchFoundData));
    
    // Only send to player2 if it's not a bot
    if (player2.ws) {
        const matchFoundData2 = {
            type: 'match_found',
            gameId: gameId,
            opponent: player1.name,
            phase: 'team_selection',
            timeLimit: 10000
        };
        player2.ws.send(JSON.stringify(matchFoundData2));
    } else {
        // Bot will select a team after user selects (to avoid same team)
        // Bot selection is handled in handleTeamSelection function
    }
    
    console.log(`Match started: ${player1.name} vs ${player2.name} (Game: ${gameId})`);
    
    // Start team selection timer (10 seconds)
    game.teamSelectionTimer = setTimeout(() => {
        handleTeamSelectionTimeout(gameId);
    }, 10000);
}

function handleTeamSelection(ws, data) {
    const game = findGameByPlayer(ws);
    if (!game || game.phase !== 'team_selection') return;
    
    const player = getPlayerFromGame(game, ws);
    if (!player) return;
    
    player.selectedTeam = data.team;
    console.log(`${player.name} selected team: ${data.team}`);
    
    // Send team selection confirmation to the player
    ws.send(JSON.stringify({
        type: 'team_selected_confirm',
        team: data.team
    }));
    
    // If this is user's selection and opponent is bot, make bot select different team
    if (player === game.player1 && !game.player2.ws) {
        // Bot needs to select a different team
        const availableTeams = getAvailableTeams(data.team);
        game.player2.selectedTeam = availableTeams[Math.floor(Math.random() * availableTeams.length)];
        console.log(`Bot selected different team: ${game.player2.selectedTeam}`);
    }
    
    // If both players selected teams, start team display phase
    if (game.player1.selectedTeam && game.player2.selectedTeam) {
        clearTimeout(game.teamSelectionTimer);
        startTeamDisplay(game.id);
    }
}

function handleTeamSelectionTimeout(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;
    
    // Assign random teams to players who didn't select
    if (!game.player1.selectedTeam) {
        game.player1.selectedTeam = getRandomTeam();
    }
    if (!game.player2.selectedTeam) {
        // If player2 is bot and player1 already selected, choose different team
        if (!game.player2.ws && game.player1.selectedTeam) {
            const availableTeams = getAvailableTeams(game.player1.selectedTeam);
            game.player2.selectedTeam = availableTeams[Math.floor(Math.random() * availableTeams.length)];
        } else {
            game.player2.selectedTeam = getRandomTeam();
        }
    }
    
    startTeamDisplay(gameId);
}

function startTeamDisplay(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;
    
    game.phase = 'team_display';
    
    console.log(`=== TEAM DISPLAY DEBUG ===`);
    console.log(`Game ID: ${gameId}`);
    console.log(`Player1 (${game.player1.name}): ${game.player1.selectedTeam}`);
    console.log(`Player2 (${game.player2.name}): ${game.player2.selectedTeam}`);
    console.log(`Player1 WS exists: ${!!game.player1.ws}`);
    console.log(`Player2 WS exists: ${!!game.player2.ws}`);
    
    // Send team display data to both players
    const teamDisplayData = {
        type: 'team_display',
        playerTeam: game.player1.selectedTeam,
        opponentTeam: game.player2.selectedTeam,
        timeLimit: 3000 // 3 seconds to display teams
    };
    
    console.log(`Player1'e gönderilen data:`, teamDisplayData);
    game.player1.ws.send(JSON.stringify(teamDisplayData));
    
    if (game.player2.ws) {
        const teamDisplayData2 = {
            type: 'team_display',
            playerTeam: game.player2.selectedTeam,
            opponentTeam: game.player1.selectedTeam,
            timeLimit: 3000
        };
        console.log(`Player2'ye gönderilen data:`, teamDisplayData2);
        game.player2.ws.send(JSON.stringify(teamDisplayData2));
    } else {
        console.log(`Player2 bot olduğu için mesaj gönderilmiyor`);
    }
    
    console.log(`Team display started for game ${gameId}: ${game.player1.selectedTeam} vs ${game.player2.selectedTeam}`);
    console.log(`=== TEAM DISPLAY DEBUG END ===`);
    
    // Start team display timer (3 seconds)
    game.teamDisplayTimer = setTimeout(() => {
        startGamePlay(gameId);
    }, 3000);
}

function startGamePlay(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;
    
    game.phase = 'playing';
    
    const team1 = game.player1.selectedTeam;
    const team2 = game.player2.selectedTeam;
    
    // Eğer aynı takımlar seçildiyse, transfer oyuncusu bulunamaz
    if (team1 === team2) {
        console.log(`Same teams selected (${team1} vs ${team2}), ending game`);
        endGame(gameId, null, 'Same teams selected');
        return;
    }
    
    // İki takım arasında transfer geçmişi olan oyuncu bul
    const transferPlayers = findTransferPlayersBetweenTeams(team1, team2);
    
    if (transferPlayers.length === 0) {
        console.log(`No transfer players found between ${team1} and ${team2}`);
        endGame(gameId, null, 'No transfer players available');
        return;
    }
    
    // Rastgele bir transfer oyuncusu seç
    const selectedPlayer = transferPlayers[Math.floor(Math.random() * transferPlayers.length)];
    
    const question = {
        player: selectedPlayer,
        correctAnswers: transferPlayers, // Tüm transfer oyuncuları doğru cevap
        teams: [team1, team2]
    };
    
    game.currentQuestion = question;
    
    // Oyun sorusunu iki oyuncuya da gönder
    const gameData = {
        type: 'game_started',
        questionText: `Bu iki takımda da form giymiş bir oyuncu yazın:\n${team1} vs ${team2}`,
        teams: [team1, team2],
        timeLimit: 30000 // 30 seconds to answer
    };
    
    game.player1.ws.send(JSON.stringify(gameData));
    
    if (game.player2.ws) {
        game.player2.ws.send(JSON.stringify(gameData));
    } else {
        // Bot automatically answers - %70 doğru cevap verir
        setTimeout(() => {
            let botAnswer;
            if (Math.random() < 0.7) {
                // Doğru cevap ver - transfer oyuncularından birini seç
                botAnswer = transferPlayers[Math.floor(Math.random() * transferPlayers.length)];
            } else {
                // Yanlış cevap ver - random bir oyuncu ismi
                const wrongAnswers = ['Messi', 'Ronaldo', 'Neymar', 'Haaland', 'Benzema'];
                botAnswer = wrongAnswers[Math.floor(Math.random() * wrongAnswers.length)];
            }
            
            handlePlayerAnswer(null, {
                type: 'player_answer',
                answer: botAnswer
            }, true, game.player2.id);
        }, Math.random() * 25000 + 2000); // Bot answers in 2-27 seconds
    }
    
    console.log(`Game started for ${gameId}: Transfer players between ${team1} and ${team2}`);
    console.log(`Correct answers: ${transferPlayers.join(', ')}`);
    
    // Start game timer (30 seconds)
    game.gameTimer = setTimeout(() => {
        handleGameTimeout(gameId);
    }, 30000);
}

function handlePlayerAnswer(ws, data, isBot = false, botPlayerId = null) {
    console.log(`=== CEVAP KONTROL ===`);
    console.log(`Gelen cevap: "${data.answer}"`);
    
    let game;
    let player;
    
    if (isBot) {
        // Find game by bot player ID
        for (let [gameId, gameData] of activeGames) {
            if (gameData.player2.id === botPlayerId) {
                game = gameData;
                player = gameData.player2;
                break;
            }
        }
    } else {
        // İlk önce WebSocket ile dene
        game = findGameByPlayer(ws);
        if (game) {
            player = getPlayerFromGame(game, ws);
        }
        
        // Eğer bulamazsa, en son aktif oyunu al (fallback)
        if (!game && activeGames.size > 0) {
            console.log(`WebSocket ile oyun bulunamadı, fallback kullanılıyor...`);
            game = Array.from(activeGames.values())[0]; // İlk aktif oyunu al
            player = game.player1; // İlk oyuncuyu kullan
            console.log(`Fallback: Oyun ${game.id} kullanılıyor, oyuncu ${player.name}`);
        }
    }

    if (!game) {
        console.log(`UYARI: Aktif oyun bulunamadı - muhtemelen oyun zaten bitti.`);
        console.log(`Aktif oyun sayısı: ${activeGames.size}`);
        
        // Oyuncu bilgilendirmesi göndermek yerine sadece log tutuyoruz
        // Bu durum oyun bittikten sonra gelen geç cevaplar için normaldir
        return;
    }
    
    if (game.phase !== 'playing') {
        console.log(`UYARI: Oyun fazı 'playing' değil, mevcut faz: ${game.phase} - cevap göz ardı ediliyor`);
        return;
    }
    
    if (!player) {
        console.log(`HATA: Oyuncu bulunamadı, fallback player1 kullanılıyor!`);
        player = game.player1;
    }
    
    const answer = data.answer.trim();
    const correctAnswers = game.currentQuestion.correctAnswers; 
    
    console.log(`Oyuncu: ${player.name}`);
    console.log(`Temizlenmiş cevap: "${answer}"`);
    console.log(`Doğru cevaplar: [${correctAnswers.join(', ')}]`);
    
    // Cevabın doğru oyunculardan biri olup olmadığını kontrol et
    const isCorrect = correctAnswers.some(correctPlayer => {
        const playerLower = correctPlayer.toLowerCase();
        const answerLower = answer.toLowerCase();
        console.log(`Karşılaştırma: "${answerLower}" === "${playerLower}" => ${answerLower === playerLower}`);
        return answerLower === playerLower;
    });
    
    console.log(`${player.name} answered: ${answer}`);
    console.log(`Correct answers: ${correctAnswers.join(', ')}`);
    console.log(`Is correct: ${isCorrect}`);
    
    if (isCorrect) {
        // İlk doğru cevap kazanır!
        console.log(`DOĞRU CEVAP! ${player.name} kazandı!`);
        clearTimeout(game.gameTimer);
        endGame(game.id, player.id, `Correct answer: ${answer}`);
    } else {
        // Yanlış cevap - oyun timeout'a kadar devam eder
        console.log(`Wrong answer from ${player.name}, game continues...`);
        
        // Sadece cevap veren oyuncuya yanlış cevap bildirimi gönder
        const wrongAnswerData = {
            type: 'wrong_answer',
            message: 'Cevabınız yanlış! Tekrar deneyin.'
        };
        
        // Sadece cevap veren oyuncuya gönder
        if (player.ws) {
            player.ws.send(JSON.stringify(wrongAnswerData));
        }
    }
}

function handleGameTimeout(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;
    
    console.log(`Game ${gameId} timed out - no one answered correctly in 30 seconds`);
    endGame(gameId, null); // No winner
}

function endGame(gameId, winnerId, winDetails = null) {
    const game = activeGames.get(gameId);
    if (!game) return;
    
    // Clear all timers
    clearTimeout(game.teamSelectionTimer);
    clearTimeout(game.teamDisplayTimer);
    clearTimeout(game.gameTimer);
    
    // Winner name'i ID'den bul
    let winnerName = null;
    if (winnerId === game.player1.id) {
        winnerName = game.player1.name;
    } else if (winnerId === game.player2.id) {
        winnerName = game.player2.name;
    }
    
    // Player 1 için mesaj
    const isPlayer1Winner = winnerId === game.player1.id;
    // Puan hesaplama: Kazanan +10, kaybeden -10, berabere 0
    const player1Points = isPlayer1Winner ? 10 : (winnerId ? -10 : 0);
    
    const resultDataPlayer1 = {
        type: 'game_finished',
        winner: winnerName,
        won: isPlayer1Winner, // Bu oyuncunun kazanıp kazanmadığı
        points: player1Points, // Kazanılan/kaybedilen puan
        questionText: `Bu iki takımda da form giymiş bir oyuncu yazın: ${game.player1.selectedTeam} vs ${game.player2.selectedTeam}`,
        playerTeam: game.player1.selectedTeam,
        opponentTeam: game.player2.selectedTeam,
        playerName: game.player1.name,
        opponentName: game.player2.name
    };
    
    // Player 2 için mesaj
    const isPlayer2Winner = winnerId === game.player2.id;
    // Puan hesaplama: Kazanan +10, kaybeden -10, berabere 0
    const player2Points = isPlayer2Winner ? 10 : (winnerId ? -10 : 0);
    
    const resultDataPlayer2 = {
        type: 'game_finished',
        winner: winnerName,
        won: isPlayer2Winner, // Bu oyuncunun kazanıp kazanmadığı
        points: player2Points, // Kazanılan/kaybedilen puan
        questionText: `Bu iki takımda da form giymiş bir oyuncu yazın: ${game.player2.selectedTeam} vs ${game.player1.selectedTeam}`,
        playerTeam: game.player2.selectedTeam,
        opponentTeam: game.player1.selectedTeam,
        playerName: game.player2.name,
        opponentName: game.player1.name
    };
    
    // Send result to players
    game.player1.ws.send(JSON.stringify(resultDataPlayer1));
    
    if (game.player2.ws) {
        game.player2.ws.send(JSON.stringify(resultDataPlayer2));
    }
    
    console.log(`Game ${gameId} finished. Winner: ${winnerName || 'No one'} (ID: ${winnerId || 'none'})`);
    console.log(`Player1 (${game.player1.name}, ID: ${game.player1.id}) won: ${isPlayer1Winner}`);
    console.log(`Player2 (${game.player2.name}, ID: ${game.player2.id}) won: ${isPlayer2Winner}`);
    
    // Remove game from active games
    activeGames.delete(gameId);
}

// Helper functions
function findGameByPlayer(ws) {
    for (let game of activeGames.values()) {
        if (game.player1.ws === ws || game.player2.ws === ws) {
            return game;
        }
    }
    return null;
}

function getPlayerFromGame(game, ws) {
    if (game.player1.ws === ws) return game.player1;
    if (game.player2.ws === ws) return game.player2;
    return null;
}

function getRandomTeam() {
    const teams = ['Barcelona', 'Real Madrid', 'Manchester City', 'PSG', 'Bayern Munich', 'Liverpool', 'Chelsea', 'Arsenal'];
    return teams[Math.floor(Math.random() * teams.length)];
}

function getAvailableTeams(excludeTeam) {
    const allTeams = ['Barcelona', 'Real Madrid', 'Manchester City', 'PSG', 'Bayern Munich', 'Liverpool', 'Chelsea', 'Arsenal'];
    return allTeams.filter(team => team !== excludeTeam);
}

function getPlayersForTeam(teamName) {
    const teamPlayers = {
        'Barcelona': ['Lionel Messi', 'Gerard Pique', 'Sergio Busquets', 'Jordi Alba', 'Frenkie de Jong'],
        'Real Madrid': ['Cristiano Ronaldo', 'Sergio Ramos', 'Luka Modric', 'Toni Kroos', 'Karim Benzema'],
        'Manchester City': ['Kevin De Bruyne', 'Raheem Sterling', 'Sergio Aguero', 'Riyad Mahrez', 'Bernardo Silva'],
        'PSG': ['Neymar Jr', 'Kylian Mbappe', 'Angel Di Maria', 'Marco Verratti', 'Marquinhos'],
        'Bayern Munich': ['Robert Lewandowski', 'Thomas Muller', 'Manuel Neuer', 'Joshua Kimmich', 'Leon Goretzka'],
        'Liverpool': ['Mohamed Salah', 'Sadio Mane', 'Roberto Firmino', 'Virgil van Dijk', 'Jordan Henderson'],
        'Chelsea': ['Eden Hazard', 'N\'Golo Kante', 'Timo Werner', 'Mason Mount', 'Thiago Silva'],
        'Arsenal': ['Pierre-Emerick Aubameyang', 'Alexandre Lacazette', 'Bukayo Saka', 'Thomas Partey', 'Gabriel Martinelli']
    };
    
    return teamPlayers[teamName] || ['Unknown Player'];
}

function getRandomPlayerName() {
    const allPlayers = [
        'Lionel Messi', 'Cristiano Ronaldo', 'Neymar Jr', 'Kevin De Bruyne', 'Robert Lewandowski',
        'Mohamed Salah', 'Kylian Mbappe', 'Eden Hazard', 'Sergio Ramos', 'Virgil van Dijk'
    ];
    return allPlayers[Math.floor(Math.random() * allPlayers.length)];
}

// Transfer geçmişi olan oyuncular - her iki takımda da oynamış
function getTransferPlayers() {
    return {
        'Barcelona-Real Madrid': [
            'Luis Figo', 'Ronaldo Nazario', 'Michael Laudrup', 'Saul Niguez', 'Dani Alves'
        ],
        'Manchester City-Bayern Munich': [
            'Leroy Sané', 'Jerome Boateng', 'Claudio Bravo', 'Dante', 'Shay Given'
        ],
        'Liverpool-Chelsea': [
            'Fernando Torres', 'Raul Meireles', 'Joe Cole', 'Glen Johnson', 'Yossi Benayoun'
        ],
        'PSG-Arsenal': [
            'David Seaman', 'Jerome Rothen', 'Nicolas Anelka', 'Mathieu Flamini', 'Adrien Rabiot'
        ],
        'Barcelona-Manchester City': [
            'Yaya Toure', 'Eric Garcia', 'Ferran Torres', 'Claudio Bravo', 'Thierry Henry'
        ],
        'Real Madrid-Bayern Munich': [
            'James Rodriguez', 'Toni Kroos', 'Xabi Alonso', 'Arjen Robben', 'Owen Hargreaves'
        ],
        'Liverpool-Bayern Munich': [
            'Sadio Mané', 'Thiago Alcantara', 'Xherdan Shaqiri', 'Emre Can', 'Pepe Reina'
        ],
        'Chelsea-PSG': [
            'David Luiz', 'Thiago Silva', 'Jorginho', 'Marco Verratti', 'Edinson Cavani'
        ],
        'Arsenal-Barcelona': [
            'Thierry Henry', 'Alex Song', 'Cesc Fabregas', 'Alexis Sanchez', 'Hector Bellerin'
        ],
        'PSG-Bayern Munich': [
            'Kingsley Coman', 'Julian Draxler', 'Eric Maxim Choupo-Moting', 'Juan Bernat', 'Thiago Motta'
        ],
        'Barcelona-Bayern Munich': [
            'Robert Lewandowski', 'Philippe Coutinho', 'Arturo Vidal', 'Thiago Alcantara', 'Douglas Costa'
        ],
        'Liverpool-Arsenal': [
            'Alex Oxlade-Chamberlain', 'Pepe Reina', 'Luis Suarez', 'Raheem Sterling', 'Andy Carroll'
        ],
        'Liverpool-Barcelona': [
            'Luis Suarez', 'Philippe Coutinho', 'Gini Wijnaldum', 'Adriano', 'Javier Mascherano'
        ],
        'Liverpool-Manchester City': [
            'Raheem Sterling', 'James Milner', 'Mario Balotelli', 'Kolo Toure', 'Scott Carson'
        ],
        'Chelsea-Manchester City': [
            'Frank Lampard', 'Raheem Sterling', 'Cole Palmer', 'Riyad Mahrez', 'Joao Cancelo'
        ],
        'Real Madrid-Manchester City': [
            'Aymeric Laporte', 'Brahim Diaz', 'Ferran Torres', 'Julian Alvarez', 'Joao Cancelo'
        ]
    };
}

// İki takım arasında transfer geçmişi olan oyuncu bul
function findTransferPlayersBetweenTeams(team1, team2) {
    const transfers = getTransferPlayers();
    
    // Direkt kombinasyon kontrol et (team1-team2)
    let key = `${team1}-${team2}`;
    if (transfers[key]) {
        return transfers[key];
    }
    
    // Ters kombinasyon kontrol et (team2-team1)
    key = `${team2}-${team1}`;
    if (transfers[key]) {
        return transfers[key];
    }
    
    // Transfer geçmişi bulunamadı
    return [];
}

function findTransferPlayer(team1, team2) {
    const transfers = getTransferPlayers();
    
    // Direkt kombinasyon kontrol et
    let key = `${team1}-${team2}`;
    if (transfers[key]) {
        const players = transfers[key];
        return {
            player: players[Math.floor(Math.random() * players.length)],
            teams: [team1, team2]
        };
    }
    
    // Ters kombinasyon kontrol et
    key = `${team2}-${team1}`;
    if (transfers[key]) {
        const players = transfers[key];
        return {
            player: players[Math.floor(Math.random() * players.length)],
            teams: [team2, team1]
        };
    }
    
    // Eğer direkt transfer geçmişi yoksa, random bir takımdan oyuncu seç
    const randomTeam = Math.random() > 0.5 ? team1 : team2;
    const players = getPlayersForTeam(randomTeam);
    return {
        player: players[Math.floor(Math.random() * players.length)],
        teams: [randomTeam],
        isDirectTeamPlayer: true
    };
}
