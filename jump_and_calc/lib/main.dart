import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

const serverUrl = 'http://10.11.116.96:5000'; //'https://robertfoerster.pythonanywhere.com';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jump&Calc',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _score = 0;
  Timer? _timer;
  String _locigalState = 'NoGame';
  int _gameId = 0;
  int _playerId = 0;
  bool _started = false;
  bool _alive = false;
  String _playerName = '';
  List<dynamic> _playersInfo = [];
  List<dynamic> _questions = [
        ["What is the capital of India?", "New Delhi", "Madrid", "Berlin", "Paris", 0],
    ];

  Future<void> startGame() async {
      final response = await http.patch(Uri.parse('$serverUrl/player/$_gameId'));
      
      if (response.statusCode == 200) {
        setState(() {
          _locigalState = 'GameStarted';
        });
      } 
  }

  Future<void> answerQuestion(_answer) async {
    try {
      final response = await http.put(Uri.parse('$serverUrl/player/$_playerId/$_answer'));
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _score = responseJson['score'];
          _alive = responseJson['alive'];
        });
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(responseJson['error']),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> getState() async {
    if (_locigalState == 'NoGame') return;
    try {
      final response = await http.get(Uri.parse('$serverUrl/game/$_gameId'));
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _started = responseJson['started'];
          _playersInfo = responseJson['players'];
        });
      }
    } catch (e) {

    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => getState());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget gameInfoBlock = Column(
      children: [
        Text('GameId: $_gameId'),
        for (var player in _playersInfo) Text('Player: ${player[1]} Score: ${player[2]} Alive: ${player[3]}'),
      ],
    );

    Widget quizBlock = Column(
      children: [
        Text(_questions[_score][0]),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                answerQuestion(0);
              },
              child: Text(_questions[_score][1]),
            ),
            ElevatedButton(
              onPressed: () {
                answerQuestion(1);
              },
              child: Text(_questions[_score][2])
            ),
            ElevatedButton(
              onPressed: () {
                answerQuestion(2);
              },
              child: Text(_questions[_score][3]),
            ),
            ElevatedButton(
              onPressed: () {
                answerQuestion(3);
              },
              child: Text(_questions[_score][4]),
            ),
          ]
        )
      ],
    );

    return Scaffold(
      body: ListView(
        children: [
          if (_locigalState == 'NoGame') MenuForm(
            onGameCreated: (gameId, playerId, playerName, questions) {
              setState(() {
                _locigalState = 'GameCreated';
                _gameId = gameId;
                _playerId = playerId;
                _playerName = playerName;
                _questions = questions;
              });
            },
            onGameJoined: (gameId, playerId, playerName, questions) {
              setState(() {
                _locigalState = 'GameJoined';
                _gameId = gameId;
                _playerId = playerId;
                _playerName = playerName;
              _questions = questions;
              });
            },
          ),
          if (_locigalState == 'GameStarted' || _locigalState == 'GameCreated' || _locigalState == 'GameJoined') gameInfoBlock,
          if (_locigalState == 'GameCreated') ElevatedButton(
            onPressed: () {
              startGame();
            },
            child: const Text('Start Game'),
          ),
          if (_locigalState == 'GameStarted') quizBlock,
        ],
      ),
    );
  }
}

class MenuForm extends StatefulWidget {
  final Function(int, int, String, dynamic) onGameCreated;
  final Function(int, int, String, dynamic) onGameJoined;

  const MenuForm({
    Key? key,
    required this.onGameCreated,
    required this.onGameJoined,
  }) : super(key: key);

  @override
  _MenuFormState createState() => _MenuFormState();
}

class _MenuFormState extends State<MenuForm> {
  final _playerNameController = TextEditingController();
  final _gameIdController = TextEditingController();
  bool _public = false;
  Timer? _timer;
  List<dynamic>_publicGames = []; 

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => getPublicGames());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerNameController.dispose();
    _gameIdController.dispose();
    super.dispose();
  }

  Future<void> getPublicGames() async {
    try {
      final response = await http.patch(Uri.parse('$serverUrl/game'));
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _publicGames = responseJson['games'];
        });
      }
    } catch (e) {

    }
  }

  Future<void> createGame(_newPlayerName, _public) async {
    try {
      final response = await http.post(Uri.parse('$serverUrl/game/$_newPlayerName/$_public'));
      final responseJson = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final _newGameId = responseJson['game_id'];
        final _newPlayerId = responseJson['player_id'];
        final _questions = responseJson['questions'];
        widget.onGameCreated(_newGameId, _newPlayerId, _newPlayerName, _questions);
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(responseJson['error']),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to create game'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
  
  Future<void> joinGame(_newGameId, _newPlayerName) async {
    try {
      final response = await http.put(Uri.parse('$serverUrl/game/$_newGameId/$_newPlayerName'));
      final responseJson = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final _newGameId = responseJson['game_id'];
        final _newPlayerId = responseJson['player_id'];
        final _questions = responseJson['questions'];
        widget.onGameJoined(_newGameId, _newPlayerId, _newPlayerName, _questions);
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(responseJson['error']),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to join game'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _playerNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Player Name',
            ),
          ),
          Row(
            children: [
              Switch(
                value: _public,
                onChanged: (value) {
                  setState(() {
                    _public = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  createGame(_playerNameController.text, _public);
                }, 
                child: const Text('Create Game'),
              )
            ],
          ),
          TextField(
            controller: _gameIdController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Game ID',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              joinGame(_gameIdController.text, _playerNameController.text);
            },
            child: const Text('Join Game'),
          ),
          if (_publicGames.isEmpty) const Text('No public games found'),
          if (_publicGames.isNotEmpty) Row(
            children: [
              for (var game in _publicGames)
                ElevatedButton(
                  onPressed: () {
                    joinGame(game[0], _playerNameController.text);
                  },
                  child: Text("${game[0].toString()} created by ${game[1]}")
                )
            ]
          )
        ]
      )
    );
  }
}
