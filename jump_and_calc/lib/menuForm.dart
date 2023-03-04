import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class MenuForm extends StatefulWidget {
  final Function(int, int, String, dynamic) onGameCreated;
  final Function(int, int, String, dynamic) onGameJoined;
  final String serverUrl;

  const MenuForm({
    Key? key,
    required this.onGameCreated,
    required this.onGameJoined,
    required this.serverUrl,
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
      final response = await http.patch(Uri.parse('${widget.serverUrl}/game'));
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
    if (_newPlayerName.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Player name cannot be empty'),
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
      return;
    }
    try {
      final response = await http.post(Uri.parse('${widget.serverUrl}/game/$_newPlayerName/$_public'));
      final responseJson = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final _newGameId = responseJson['game_id'];
        final _newPlayerId = responseJson['player_id'];
        final _questions = responseJson['questions'];
        for (var i = 0; i < _questions.length; i++) {
          for (var j = 0; j < _questions[i].length - 1; j++) {
            _questions[i][j] = base64Decode(_questions[i][j]);
          }
        }
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
    if (_newPlayerName.isEmpty ) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Player name and game ID cannot be empty'),
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
      return;
    }
    try {
      final response = await http.put(Uri.parse('${widget.serverUrl}/game/$_newGameId/$_newPlayerName'));
      final responseJson = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final _newGameId = responseJson['game_id'];
        final _newPlayerId = responseJson['player_id'];
        final _questions = responseJson['questions'];
        for (var i = 0; i < _questions.length; i++) {
          for (var j = 0; j < _questions[i].length - 1; j++) {
            _questions[i][j] = base64Decode(_questions[i][j]);
          }
        }
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
    return Column(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var game in _publicGames)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      joinGame(game[0], _playerNameController.text);
                    },
                    child: Text("${game[0].toString()} created by ${game[1]}")
                  )
                )
            ]
          )
        ]
    );
  }
}
