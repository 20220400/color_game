import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Define the overall theme for the app
      theme: ThemeData(
        primaryColor: Colors.black,
        accentColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
        ),
        textTheme: TextTheme(
          headline6: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  int? initialHighScore;

  HomeScreen({this.initialHighScore});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COLOR GAME'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Color Game!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rules:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'Identify the square with a different color. Tap the square to make a guess. Each correct guess increases the timer by 5 seconds.  Each incorrect guess decreases the timer by 5 seconds, but you can keep guessing! ',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      (newHighScore) {
                        // Callback function to update high score from GameScreen
                        // Set the initialHighScore in the HomeScreen
                        setState(() {
                          widget.initialHighScore = newHighScore;
                        });

                        // Create a Logger instance
                        var logger = Logger();

                        // Log the high score update
                        logger.i('Updating high score on HomeScreen: $newHighScore');
                      },
                    ),
                  ),
                );
              },
              child: const Text('Play Game'),
            ),
            if (widget.initialHighScore != null)
              Text(
                'High Score: ${widget.initialHighScore}',
                style: const TextStyle(fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final Function(int) updateHighScore;

  GameScreen(this.updateHighScore);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Color commonColor;
  late List<int> uniquePosition;
  int score = 0;
  int highScore = 0;
  late Timer timer;
  int timerDuration = 15;
  int gridRows = 2;
  int gridColumns = 2;
  int correctGuesses = 0;
  int nextGridIncrease = 1;

  @override
  void initState() {
    super.initState();
    startNewGame();
    startTimer();
    highScore = getHighScore();
  }

  @override
  Widget build(BuildContext context) {
    double containerWidth = MediaQuery.of(context).size.width * 0.725;
    double containerHeight = MediaQuery.of(context).size.height * 0.725;

    return Scaffold(
      appBar: AppBar(
        title: const Text('COLOR GAME'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Current Score: $score   ',
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                'High Score: $highScore',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Timer: $timerDuration seconds',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 2.0,
                ),
                color: Colors.black,
              ),
              width: containerWidth,
              height: containerHeight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: gridRows * gridColumns,
                itemBuilder: (context, index) {
                  int row = index ~/ gridColumns;
                  int col = index % gridColumns;
                  return ElevatedButton(
                    onPressed: () {
                      handleButtonPress(row, col);
                    },
                    style: ElevatedButton.styleFrom(
                      primary: (row == uniquePosition[0] && col == uniquePosition[1])
                          ? getUniqueColor(commonColor)
                          : commonColor,
                    ),
                    child: Container(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Start a new game by generating a new common color and unique position
  void startNewGame() {
    commonColor = getCommonColor();
    uniquePosition = getRandomPosition();
  }

  // Generate a random common color
  Color getCommonColor() {
    Random random = Random();
    int a = random.nextInt(255);
    int b = random.nextInt(255);
    int c = random.nextInt(255);
    return Color.fromARGB(255, a, b, c);
  }

  // Adjust the color for the unique position to make it stand out
  Color getUniqueColor(Color commonColor) {
    int delta = (1000 - gridRows * 2).clamp(5, 20);

    int red = (commonColor.red + delta).clamp(0, 255);
    int green = (commonColor.green + delta).clamp(0, 255);
    int blue = (commonColor.blue + delta).clamp(0, 255);

    return Color.fromARGB(255, red, green, blue);
  }

  // Get a random position for the unique square
  List<int> getRandomPosition() {
    Random random = Random();
    int randomRow = random.nextInt(gridRows);
    int randomCol = random.nextInt(gridColumns);
    return [randomRow, randomCol];
  }

  // Handle button press when a square is tapped
  void handleButtonPress(int row, int col) {
    if (row == uniquePosition[0] && col == uniquePosition[1]) {
      // Correct guess
      score++;
      correctGuesses++;
      if (correctGuesses >= nextGridIncrease) {
        gridRows++;
        gridColumns++;
        nextGridIncrease *= 2;
      }
      startNewGame();
      int timerIncrease = (30 - timerDuration).clamp(0, 5);
      timerDuration += timerIncrease;
      if (score > highScore) {
        setState(() {
          highScore = score;
        });
      }
    } else {
      // Incorrect guess
      timerDuration = (timerDuration - 5).clamp(0, timerDuration);
    }
  }

  // Start the timer to count down
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timerDuration > 0 && timerDuration <= 30) {
          timerDuration--;
        } else if (timerDuration <= 0) {
          timer.cancel();
          endGame();
        }
      });
    });
  }

  // End the game and show the result dialog
  void endGame() {
    if (score > getHighScore()) {
      saveHighScore(score);
      widget.updateHighScore(score);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your score: $score\nHigh Score: ${getHighScore()}'),
                const SizedBox(height: 10),
                const Text(
                  'Note: Returning home will not save your high score.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Back to Home"),
            ),
          ],
        );
      },
    );
  }

  // Save the high score
  void saveHighScore(int score) {
    highScore = score;
  }

  // Get the current high score
  int getHighScore() {
    return highScore;
  }

  // Reset the game to its initial state
  void resetGame() {
    setState(() {
      score = 0;
      timerDuration = 15;
      gridRows = 2;
      gridColumns = 2;
      correctGuesses = 0;
      nextGridIncrease = 1;
    });

    startNewGame();
    startTimer();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
