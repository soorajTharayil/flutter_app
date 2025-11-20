import 'package:flutter/material.dart';

class EfeedorLogo extends StatefulWidget {
  const EfeedorLogo({Key? key}) : super(key: key);

  @override
  State<EfeedorLogo> createState() => _EfeedorLogoState();
}

class _EfeedorLogoState extends State<EfeedorLogo> with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: false);

    _animationController.addListener(() {
      _scrollController.jumpTo(
        (_animationController.value * 100) % 100,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, MediaQuery.of(context).size.height / 20, 0, 0),
      alignment: Alignment.topCenter,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "E",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
          SizedBox(
            width: 200,
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              children: const [
                Center(
                  child: Text(
                    "feedor     feedor     feedor     feedor",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
