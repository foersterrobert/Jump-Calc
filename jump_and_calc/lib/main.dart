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

  Future<void> answerQuestion() async {
    final response = await http.get(Uri.parse('http://jumpandcalc.com/answer_question'));
    final responseJson = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        _counter = responseJson['counter'];
      });
    } else {
      throw Exception('Failed to load question');
    }
  }

  Future<void> getState() async {
    final response = await http.get(Uri.parse('http://jumpandcalc.com/get_state'));
    final responseJson = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        _counter = responseJson['counter'];
      });
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

    Widget test = GestureDetector(
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
      appBar: AppBar(
        title: const Text("Jump&Calc"),
      ),
      body: test,
    );
  }
}
