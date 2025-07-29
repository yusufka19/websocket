class FootballTeam {
  final String name;
  final String flag;
  final List<String> players;

  const FootballTeam({
    required this.name,
    required this.flag,
    required this.players,
  });

  static const List<FootballTeam> teams = [
    FootballTeam(
      name: 'Barcelona',
      flag: '🔵🔴',
      players: [
        'Lewandowski',
        'Pedri',
        'Gavi',
        'Ter Stegen',
        'Araujo',
        'De Jong',
        'Raphinha',
        'Ferran Torres',
        'Ansu Fati',
        'Sergi Roberto',
      ],
    ),
    FootballTeam(
      name: 'Real Madrid',
      flag: '⚪',
      players: [
        'Benzema',
        'Vinicius Jr',
        'Modric',
        'Kroos',
        'Courtois',
        'Alaba',
        'Militao',
        'Rodrygo',
        'Valverde',
        'Tchouameni',
      ],
    ),
    FootballTeam(
      name: 'Manchester City',
      flag: '🔵',
      players: [
        'Haaland',
        'De Bruyne',
        'Bernardo Silva',
        'Mahrez',
        'Ederson',
        'Walker',
        'Stones',
        'Gundogan',
        'Grealish',
        'Rodri',
      ],
    ),
    FootballTeam(
      name: 'Paris Saint-Germain',
      flag: '🔴🔵',
      players: [
        'Messi',
        'Mbappe',
        'Neymar',
        'Verratti',
        'Marquinhos',
        'Donnarumma',
        'Hakimi',
        'Ramos',
        'Vitinha',
        'Mukiele',
      ],
    ),
    FootballTeam(
      name: 'Bayern Munich',
      flag: '🔴⚪',
      players: [
        'Neuer',
        'Muller',
        'Sane',
        'Kimmich',
        'Goretzka',
        'Davies',
        'Upamecano',
        'Gnabry',
        'Coman',
        'Mane',
      ],
    ),
    FootballTeam(
      name: 'Liverpool',
      flag: '🔴',
      players: [
        'Salah',
        'Van Dijk',
        'Alisson',
        'Mane',
        'Firmino',
        'Henderson',
        'Alexander-Arnold',
        'Robertson',
        'Thiago',
        'Fabinho',
      ],
    ),
    FootballTeam(
      name: 'Chelsea',
      flag: '🔵',
      players: [
        'Mount',
        'James',
        'Silva',
        'Kante',
        'Kepa',
        'Sterling',
        'Havertz',
        'Chilwell',
        'Kovacic',
        'Pulisic',
      ],
    ),
    FootballTeam(
      name: 'Arsenal',
      flag: '🔴⚪',
      players: [
        'Saka',
        'Odegaard',
        'Martinelli',
        'Partey',
        'Ramsdale',
        'Gabriel',
        'White',
        'Xhaka',
        'Jesus',
        'Saliba',
      ],
    ),
  ];

  static List<String> getAllPlayers() {
    List<String> allPlayers = [];
    for (final team in teams) {
      allPlayers.addAll(team.players);
    }
    return allPlayers;
  }

  static FootballTeam? getTeamByPlayer(String playerName) {
    for (final team in teams) {
      if (team.players.any((player) => 
          player.toLowerCase().contains(playerName.toLowerCase()))) {
        return team;
      }
    }
    return null;
  }

  static bool isValidPlayer(String playerName, String teamName) {
    final team = teams.firstWhere(
      (t) => t.name == teamName,
      orElse: () => const FootballTeam(name: '', flag: '', players: []),
    );
    
    return team.players.any((player) => 
        player.toLowerCase().contains(playerName.toLowerCase()));
  }
}
