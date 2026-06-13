import 'package:flutter/material.dart';

class Splashscreen extends StatelessWidget {
  const Splashscreen({ super.key });

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    Orientation orientation = MediaQuery.of(context).orientation;
    var maxScreen = orientation == Orientation.portrait ? screenSize.width : screenSize.height;
    var maxSize = maxScreen * 0.4;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
          child: const Icon(Icons.location_on, size: 80, color: Colors.blue),
        ),
      ),
    );
  }
}
