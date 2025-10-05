import 'package:flutter/material.dart';
import 'package:voice_assistant/pallete.dart';

class Featurebox extends StatelessWidget {
  final String headerText;
  final String descText;
  final Color color;
  const Featurebox({
    super.key,
    required this.color,
    required this.headerText,
    required this.descText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      margin: EdgeInsets.only(left: 20, right: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10).copyWith(left: 15),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                headerText,
                style: TextStyle(
                  color: Pallete.blackColor,
                  fontFamily: 'Cera Pro',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                descText,
                style: TextStyle(
                  color: Pallete.blackColor,
                  fontFamily: 'Cera Pro',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
