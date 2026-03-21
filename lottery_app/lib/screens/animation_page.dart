import 'package:flutter/material.dart';
import 'result_page.dart';
import 'dart:math';

// ④ 抽選演出画面
class LotteryAnimationPage extends StatefulWidget {
  final String resultName;
  const LotteryAnimationPage({super.key, required this.resultName});

  @override
  State<LotteryAnimationPage> createState() => _LotteryAnimationPageState();
}

class _LotteryAnimationPageState extends State<LotteryAnimationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ResultPage(resultName: widget.resultName)),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.rotationY(_animation.value * pi),
              alignment: Alignment.center,
              child: Container(
                width: 200,
                height: 300,
                decoration: BoxDecoration(
                  color: _animation.value < 0.5 ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _animation.value < 0.5
                      ? const Text(
                          '一番くじ',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Transform(
                          transform: Matrix4.rotationY(pi),
                          alignment: Alignment.center,
                          child: Text(
                            widget.resultName,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}