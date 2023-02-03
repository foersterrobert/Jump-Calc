import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

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
  int _counter = 0;
  Timer? _timer;
  String _locigalState = 'NoGame';
  int _gameId = 0;
  int _playerId = 0;
  bool _started = false;
  String _playerName = '';
  String _playersString = '';

  Future<void> startGame() async {
      final response = await http.patch(Uri.parse('https://robertfoerster.pythonanywhere.com/game/$_gameId/$_playerName'));
      
      if (response.statusCode == 200) {
        setState(() {
          _locigalState = 'GameStarted';
        });
      } 
  }

  Future<void> answerQuestion() async {
    try {
      final response = await http.put(Uri.parse('https://robertfoerster.pythonanywhere.com/player/$_gameId/$_playerId/1'));
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _counter = responseJson['score'];
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
      final response = await http.get(Uri.parse('https://robertfoerster.pythonanywhere.com//game/$_gameId/$_playerId'));
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _started = responseJson['started'];
          _playersString = responseJson['players'];
        });
      }
    } catch (e) {
      print(e.toString());
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
        Text('Started: $_started'),
        Text('PlayerId: $_playerId'),
        Text('PlayerName: $_playerName'),
        Text('Players: $_playersString'),
      ],
    );

    Widget quizBlock = GestureDetector(
      onTap: () {
        answerQuestion();
      },
      child: Container(
        width: 200,
        height: 200,
        color: Colors.red,
        child: Center(
          child: Text(
            '$_counter',
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
      ),
    );

    return Scaffold(
      body: ListView(
        children: [
          if (_locigalState == 'NoGame') MenuForm(
            onGameCreated: (gameId, playerId, playerName) {
              setState(() {
                _locigalState = 'GameCreated';
                _gameId = gameId;
                _playerId = playerId;
                _playerName = playerName;
              });
            },
            onGameJoined: (gameId, playerId, playerName) {
              setState(() {
                _locigalState = 'GameJoined';
                _gameId = gameId;
                _playerId = playerId;
                _playerName = playerName;
              });
            },
          ),
          if (_locigalState == 'GameCreated') ElevatedButton(
            onPressed: () {
              startGame();
            },
            child: const Text('Start Game'),
          ),
          if (_locigalState == 'GameStarted') quizBlock,
          if (_locigalState == 'GameStarted' || _locigalState == 'GameCreated' || _locigalState == 'GameJoined') gameInfoBlock,
        ],
      ),
    );
  }
}

class MenuForm extends StatefulWidget {
  final Function(int, int, String) onGameCreated;
  final Function(int, int, String) onGameJoined;

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

  Future<void> createGame(_newPlayerName) async {
    try {
      final response = await http.post(Uri.parse('https://robertfoerster.pythonanywhere.com/game/0/$_newPlayerName'));
      final responseJson = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final _newGameId = responseJson['game_id'];
        final _newPlayerId = responseJson['player_id'];
        widget.onGameCreated(_newGameId, _newPlayerId, _newPlayerName);
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
      final response = await http.put(Uri.parse('https://robertfoerster.pythonanywhere.com/game/$_newGameId/$_newPlayerName'));
      final responseJson = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final _newGameId = responseJson['game_id'];
        final _newPlayerId = responseJson['player_id'];
        widget.onGameJoined(_newGameId, _newPlayerId, _newPlayerName);
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
  void dispose() {
    _playerNameController.dispose();
    _gameIdController.dispose();
    super.dispose();
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
          ElevatedButton(
            onPressed: () {
              createGame(_playerNameController.text);
            }, 
            child: const Text('Create Game'),
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
        ]
      )
    );
  }
}
