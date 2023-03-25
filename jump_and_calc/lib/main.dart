import 'dart:convert';
import 'dart:math';
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
          scaffoldBackgroundColor: const Color.fromARGB(233, 233, 242, 255),
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
  Random random = Random();
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
  int? characterIdx;

  Future<void> startGame() async {
    final response = await http.patch(Uri.parse('$serverUrl/player/$gameId'));
    
    if (response.statusCode == 200) {
      setState(() {
        logicalState = 'GameStarted';
      });
    } 
  }

  Future<void> leaveGame() async {
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
    // final response = await http.delete(Uri.parse('$serverUrl/game/$playerId'));
    // if (response.statusCode == 200) {
    // }
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
    if (logicalState == 'NoGame' || logicalState == 'GameOver') return;
    try {
      final response = await http.get(Uri.parse('$serverUrl/player/$gameId'));
      final responseJson = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseJson['game_state'] == 'GameOver') {
          setState(() {
            playersInfo = responseJson['players'];
            if (responseJson['game_state'] != 'waiting') {
              logicalState = responseJson['game_state'];
            }
          });
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Game Finished'),
                content: Text(responseJson['winner'] + ' won!'),
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
    } catch (e) {
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) => getState());
    characterIdx = random.nextInt(10) + 1;
  }

  @override
  void dispose() {
    fetchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget characterBlock = Center(
      child: Column(
        children: [
          Image.asset('assets/images/pi_${characterIdx}_large.png', width: MediaQuery.of(context).size.width * 0.3, fit: BoxFit.fitWidth),
          ElevatedButton(
            onPressed:() => setState(() {
              characterIdx = random.nextInt(10) + 1;
            }),
            child: const Icon(Icons.refresh),
          )
        ],
      ),
    );

    Widget gameLobbyBlock = Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            children: [
              Column(
                children: [
                    Text(playerName),
                    Image.asset('assets/images/pi_$characterIdx.png', width: MediaQuery.of(context).size.width * 0.22),
                  ]
              ),
              for (var playerIdx = 0; playerIdx < playersInfo.length; playerIdx++)
                if (playersInfo[playerIdx][0] != playerId)
                  Column(
                    children: [
                      Text(playersInfo[playerIdx][1]),
                      Image.asset('assets/images/pi_${(playerIdx % 10) + 1}.png', width: MediaQuery.of(context).size.width * 0.22),
                    ]
                  )
            ],
            alignment: WrapAlignment.spaceEvenly,
          ),
        ),
        Text('GameId: $gameId'),
      ],
    );

    Widget gameQuizBlock = Column(
      children: [
        Stack(
        children: [
          Image.asset('assets/images/level.png'),
          for (var playerIdx = 0; playerIdx < playersInfo.length; playerIdx++) 
            if (playersInfo[playerIdx][0] != playerId)
              AnimatedPositioned(
                  left: scoreMap[playersInfo[playerIdx][2]][0] * MediaQuery.of(context).size.width,
                  top: playersInfo[playerIdx][3] != "dead" ? scoreMap[playersInfo[playerIdx][2]][1] * MediaQuery.of(context).size.width * 0.646875 : scoreMap[0][1] * MediaQuery.of(context).size.width * 0.646875,
                  child: Image.asset(
                    playersInfo[playerIdx][3] != "dead" ? 'assets/images/pi_${(playerIdx % 10) + 1}.png' : 'assets/images/pi_X_${(playerIdx % 10) + 1}.png',
                    width: MediaQuery.of(context).size.width * 0.1),
                  duration: const Duration(milliseconds: 500),
                ),
          AnimatedPositioned(
                left: scoreMap[score][0] * MediaQuery.of(context).size.width,
                top: playerState != "dead" ? scoreMap[score][1] * MediaQuery.of(context).size.width * 0.646875 - MediaQuery.of(context).size.width * 0.07 : scoreMap[0][1] * MediaQuery.of(context).size.width * 0.646875 - MediaQuery.of(context).size.width * 0.07,
                child: Column(
                  children: [
                    Text(playerName),
                    Image.asset(
                      playerState != "dead" ? 'assets/images/pi_$characterIdx.png' : 'assets/images/pi_X_$characterIdx.png', 
                      width: MediaQuery.of(context).size.width * 0.1),
                  ]
                ),
                duration: const Duration(milliseconds: 500),
              )
            ]
          ),
          if (playerState == 'alive' && logicalState == 'GameStarted')
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                score < questions.length ? Image.memory(questions[score][0]) : const Text('Game Finished'),
                Wrap(
                  children: [
                    for (var answerIdx = 0; answerIdx < 4; answerIdx++) ElevatedButton(
                      onPressed: () {answerQuestion(answerIdx);},
                      child: score < questions.length ? Image.memory(questions[score][answerIdx + 1]) : const Text(''),
                    ),
                  ],
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 5,
                )
              ],
            ),
      ],
    );

  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Center(
            child: Image.asset('assets/images/logo.png', width: MediaQuery.of(context).size.width * 0.8),
          ),
          if (logicalState == 'NoGame') characterBlock,
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
          if (logicalState == 'GameCreated' || logicalState == 'GameJoined') gameLobbyBlock,
          if (logicalState == 'GameCreated') ElevatedButton(
            onPressed: () {
              startGame();
            },
            child: const Text('Start Game'),
          ),
          if (logicalState == 'GameStarted' || logicalState == 'GameOver') gameQuizBlock,
          if (logicalState != 'NoGame') ElevatedButton(
            onPressed: () {
              leaveGame();
            },
            child: const Text('Leave Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
            ),
          ),
        ],
      ),
    ) 
  );
  }
}
