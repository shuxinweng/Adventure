import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<String> routes;

  Navbar({
    required this.currentIndex,
    required this.onTap,
    required this.routes,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.blue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: () {
              onTap(0);
              _navigateToRoute(context, routes[0]);
            },
            icon: Icon(Icons.person),
            color: currentIndex == 0 ? Colors.black : Colors.blueGrey,
          ),
          IconButton(
            onPressed: () {
              onTap(1);
              _navigateToRoute(context, routes[1]);
            },
            icon: Icon(Icons.home),
            color: currentIndex == 1 ? Colors.black : Colors.blueGrey,
          ),
          IconButton(
            onPressed: () {
              onTap(3);
              _navigateToRoute(context, routes[3]);
            },
            icon: Icon(Icons.settings),
            color: currentIndex == 3 ? Colors.black : Colors.blueGrey,
          ),
        ],
      ),
    );
  }

  void _navigateToRoute(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }
}
