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
  String _playerName = '';

  Future<void> startGame() async {
    final response = await http.post(Uri.parse('http://localhost:5000/game/0/'));
    
    if (response.statusCode == 200) {
      setState(() {
        _locigalState = 'GameStarted';
      });
    } else {
      throw Exception('Failed to load question');
    }
  }

  Future<void> answerQuestion() async {
    final response = await http.put(Uri.parse('http://192.168.1.14:5000/player/1166/4028/1'));
    final responseJson = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        _counter = responseJson['score'];
      });
    } else {
      throw Exception('Failed to load question');
    }
  }

  Future<void> getState() async {
    final response = await http.get(Uri.parse('http://192.168.1.14:5000/game/1166/robs'));
    final responseJson = jsonDecode(response.body);

    if (response.statusCode == 200) {
      print(responseJson);
      // setState(() {
      //   _counter = responseJson['counter'];
      // });
    } else {
      throw Exception('Failed to load question');
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
    Widget quizBlock = ListView(
      children: [
        Text('$_gameId'),
        Text('$_playerId'),
        Text(_playerName),
        GestureDetector(
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
        )
      ],
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
    final response = await http.post(Uri.parse('http://localhost:5000/game/0/$_newPlayerName'));
    
    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      final _newGameId = responseJson['game_id'];
      final _newPlayerId = responseJson['player_id'];
      widget.onGameCreated(_newGameId, _newPlayerId, _newPlayerName);
    } else {
      throw Exception('Failed to create game');
    }
  }
  
  Future<void> joinGame(_newGameId, _newPlayerName) async {
    final response = await http.post(Uri.parse('http://localhost:5000/game/$_newGameId/$_newPlayerName'));
    
    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      final _newGameId = responseJson['game_id'];
      final _newPlayerId = responseJson['player_id'];
      widget.onGameJoined(_newGameId, _newPlayerId, _newPlayerName);
    } else {
      throw Exception('Failed to join game');
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
    return ListView(
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
    );
  }
}
