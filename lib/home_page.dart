import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:snake_game/blank_pixel.dart';
import 'package:snake_game/food_pixel.dart';
import 'package:snake_game/snake_pixel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';


class HomePage extends StatefulWidget{
  final String username;

  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();

}

enum snake_Direction{UP,DOWN,LEFT,RIGHT}

class _HomePageState extends State<HomePage>{
  bool bestScoreLoaded = false;

  
  TextEditingController nameController = TextEditingController();
  Timer? gameTimer;
  int bestScore = 0;

  
  int rowSize = 10;
  int totalNumberOfSquares = 100;

  bool gameHasStarted = false;

  
  int currentScore = 0;

  
  List<int> snakePos = [
    0,
    1,
    2,
  ];

  
  var currentDirection = snake_Direction.RIGHT;

  
  int foodPos = 55;
  @override
  void initState() {
    super.initState();
    loadBestScore();
  }
  
  void startGame() {
    gameHasStarted = true;
    gameTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        
        moveSnake();

        
        if (gameOver()) {
          timer.cancel();
          gameTimer = null;

          if (currentScore > bestScore) {
            bestScore = currentScore;
            submitScore();
          }

          newGame();
        }
      });
    });
  }

  Future<void> loadBestScore() async {
    final doc = await FirebaseFirestore.instance
        .collection('scores')
        .doc(widget.username)
        .get();

    if (doc.exists) {
      bestScore = doc['score'] ?? 0;
    } else {
      bestScore = 0;
    }

    setState(() {
      bestScoreLoaded = true;
    });
  }

  Future<void> submitScore() async {
    final ref = FirebaseFirestore.instance
        .collection('scores')
        .doc(widget.username);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      int oldScore = 0;
      if (snapshot.exists) {
        oldScore = snapshot['score'] ?? 0;
      }

      if (bestScore > oldScore) {
        transaction.set(ref, {
          'name': widget.username,
          'score': bestScore,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

void newGame(){
  setState(() {
    snakePos = [
      0,
      1,
      2,
    ];
    foodPos = 55;
    currentDirection = snake_Direction.RIGHT;
    gameHasStarted = false;
    currentScore = 0;
  });
}

void eatFood() {
    currentScore++;
  
  while(snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(totalNumberOfSquares);
  }
}


void moveSnake()
{
  switch(currentDirection){
    case snake_Direction.RIGHT:{
      
      
      if(snakePos.last % rowSize == 9){
        snakePos.add(snakePos.last +1 -rowSize);
      }else{
        snakePos.add(snakePos.last +1);
      }
    }
      break;
    case snake_Direction.LEFT:{
      
      
      if(snakePos.last % rowSize == 0){
        snakePos.add(snakePos.last -1 +rowSize);
      }else{
        snakePos.add(snakePos.last -1);
      }
    }
    break;

    case snake_Direction.UP:{
      
      if(snakePos.last < rowSize){
        snakePos.add(snakePos.last - rowSize + totalNumberOfSquares);
      }else{
        snakePos.add(snakePos.last-rowSize);
      }
    }
    break;

    case snake_Direction.DOWN:{
      
      if(snakePos.last + rowSize > totalNumberOfSquares){
        snakePos.add(snakePos.last + rowSize - totalNumberOfSquares);
      }else{
        snakePos.add(snakePos.last + rowSize);
      }
    }
    break;
    default:
  }
  if(snakePos.last == foodPos){
    
    eatFood();
  }else{
    
    snakePos.removeAt(0);
  }
}



  bool gameOver(){
    
    

    
    List<int> bodySnake = snakePos.sublist(0,snakePos.length-1);

    if(bodySnake.contains(snakePos.last)){
      return true;
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Snake Master"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
          onPressed: () {
            gameTimer?.cancel();
            gameTimer = null;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
            );
          },

        ),
      ),
      body: Column(
          children: [
            
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Anlık Skor"),
                      Text(currentScore.toString(),
                      style: TextStyle(fontSize: 36),
                      ),
                    ],
                  ),
                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Rekor"),
                      Text(
                        bestScore.toString(),
                        style: TextStyle(fontSize: 36),
                      ),
                    ],
                  ),
                ],
            ),
          ),
            
            Expanded(
              flex: 3,
              child: GestureDetector(
                onVerticalDragUpdate: (details){
                  if(details.delta.dy > 0 &&
                      currentDirection !=snake_Direction.UP) {
                      currentDirection = snake_Direction.DOWN;
                    }
                  else if(details.delta.dy < 0 &&
                      currentDirection != snake_Direction.DOWN) {
                    currentDirection = snake_Direction.UP;
                  }
                },
                onHorizontalDragUpdate: (details){
                  if(details.delta.dx > 0 &&
                      currentDirection != snake_Direction.LEFT) {
                    currentDirection = snake_Direction.RIGHT;
                  }
                  else if(details.delta.dx < 0 &&
                      currentDirection != snake_Direction.RIGHT) {
                    currentDirection = snake_Direction.LEFT;
                  }
                },
                child: GridView.builder(
                  itemCount: totalNumberOfSquares,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: rowSize),
                    itemBuilder: (context,index){
                        if(snakePos.contains(index)) {
                            return const SnakePixel();
                          }
                        else if(foodPos == index) {
                          return const FoodPixel();
                          }
                        else{
                          return const BlankPixel();
                        }
                  }),
              ),
            ),
            Expanded(
              child: Container(
                child: Center(
                  child: MaterialButton(
                    child: Text('OYNA'),
                    color: (!bestScoreLoaded || gameHasStarted)
                        ? Colors.grey
                        : Colors.pink,
                    onPressed: (!bestScoreLoaded || gameHasStarted)
                        ? null
                        : startGame,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}