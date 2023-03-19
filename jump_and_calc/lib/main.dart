import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'menuForm.dart';

const serverUrl = 'http://192.168.1.17:5000'; //'https://robertfoerster.pythonanywhere.com';

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
  Timer? fetchTimer;
  int score = 0;
  String logicalState = 'NoGame';
  int gameId = 0;
  int playerId = 0;
  String playerState = "alive";
  String playerName = '';
  List<dynamic> playersInfo = [];
  List<dynamic> questions = [];
  List scoreMap = [
    [0.0, 0.744],
    [0.13, 0.625],
    [0.26, 0.548],
    [0.39, 0.463],
    [0.52, 0.3815],
    [0.65, 0.3],
    [0.78, 0.2185],
  ];

  Future<void> startGame() async {
      final response = await http.patch(Uri.parse('$serverUrl/player/$gameId'));
      
      if (response.statusCode == 200) {
        setState(() {
          logicalState = 'GameStarted';
        });
      } 
  }

  Future<void> leaveGame() async {
    final response = await http.delete(Uri.parse('$serverUrl/game/$playerId'));
    setState(() {
      score = 0;
      logicalState = 'NoGame';
      gameId = 0;
      playerId = 0;
      playerState = "alive";
      playerName = '';
      playersInfo = [];
      questions = [
        ];
    });
    }

  Future<void> answerQuestion(_answer) async {
    try {
      final response = await http.put(Uri.parse('$serverUrl/player/$playerId/$_answer'));
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseJson['state'] == 'dead') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Game Over'),
                content: Column(
                  children: [
                    Text('Your score is ${responseJson['score']}\nCorrect answer is:'),
                    Image.memory(questions[score][responseJson['answer'] + 1])
                    ],
                  mainAxisSize: MainAxisSize.min,
                ),
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
        if (responseJson['state'] == 'won') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('You won!'),
                content: Text('Your score is ${responseJson['score']}'),
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
        setState(() {
          score = responseJson['score'];
          playerState = responseJson['state'];
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
    if (logicalState == 'NoGame') return;
    try {
      final response = await http.get(Uri.parse('$serverUrl/player/$gameId'));
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          if (responseJson['started'] == true) {
            logicalState = 'GameStarted';
          }
          playersInfo = responseJson['players'];
        });
      }
    } catch (e) {

    }
  }

  @override
  void initState() {
    super.initState();
    fetchTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) => getState());
  }

  @override
  void dispose() {
    fetchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget gameInfoBlock = Column(
      children: [
        Text('GameId: $gameId'),
        for (var player in playersInfo) Text('Player: ${player[1]} Score: ${player[2]} State: ${player[3]}'),
      ],
    );

    Widget gameLobbyBlock = Wrap(
      children: [
        for (var playerIdx = 0; playerIdx < playersInfo.length; playerIdx++) Column(
          children: [
            Text(playersInfo[playerIdx][1]),
            Image.asset('assets/images/pi_${(playerIdx % playersInfo.length) + 1}.png'),
          ]
        )
      ]
    );

    Widget gameVizBlock = Stack(
      children: [
        Image.asset('assets/images/level.png'),
        for (var playerIdx = 0; playerIdx < playersInfo.length; playerIdx++) Positioned(
            left: scoreMap[playersInfo[playerIdx][2]][0] * MediaQuery.of(context).size.width,
            top: scoreMap[playersInfo[playerIdx][2]][1] * MediaQuery.of(context).size.width * 0.646875,
            child: Image.asset('assets/images/pi_${(playerIdx % playersInfo.length) + 1}.png', width: MediaQuery.of(context).size.width * 0.08),
          ),
      ],
    );

    Widget quizBlock = Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        score < questions.length ? Image.memory(questions[score][0]) : const Text('Game Finished'),
        Wrap(
          children: [
            for (var answerIdx = 0; answerIdx < 4; answerIdx++) ElevatedButton(
              onPressed: () {answerQuestion(answerIdx);},
              child: score < questions.length ? Image.memory(questions[score][answerIdx + 1]) : const Text(''),
            ),
          ]
        )
      ],
  );

  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          if (logicalState == 'NoGame') MenuForm(
            onGameCreated: (_gameId, _playerId, _playerName, _questions) {
              setState(() {
                logicalState = 'GameCreated';
                gameId = _gameId;
                playerId = _playerId;
                playerName = _playerName;
                questions = _questions;
              });
            },
            onGameJoined: (_gameId, _playerId, _playerName, _questions) {
              setState(() {
                logicalState = 'GameJoined';
                gameId = _gameId;
                playerId = _playerId;
                playerName = _playerName;
                questions = _questions;
              });
            },
            serverUrl: serverUrl,
          ),
          if (logicalState != 'NoGame') gameInfoBlock,
          if (logicalState == 'GameCreated' || logicalState == 'GameJoined') gameLobbyBlock,
          if (logicalState == 'GameCreated') ElevatedButton(
            onPressed: () {
              startGame();
            },
            child: const Text('Start Game'),
          ),
          // if game started and alive and score < 9 show quiz
          if (logicalState == 'GameStarted' && playerState == 'alive') quizBlock,
          if (logicalState == 'GameStarted') gameVizBlock,
          if (logicalState != 'NoGame') ElevatedButton(
            onPressed: () {
              leaveGame();
            },
            child: const Text('Leave Game'),
          ),
        ],
      ),
    ) 
  );
  }
}
