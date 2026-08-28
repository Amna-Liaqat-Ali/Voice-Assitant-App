import 'package:flutter/material.dart';

class Pallete {
  static const Color mainFontColor = Color.fromRGBO(19, 61, 95, 1);
  static const Color firstSuggestionBoxColor = Color.fromRGBO(165, 231, 244, 1);
  static const Color secondSuggestionBoxColor = Color.fromRGBO(
    157,
    202,
    235,
    1,
  );
  static const Color thirdSuggestionBoxColor = Color.fromRGBO(162, 238, 239, 1);
  static const Color assistantCircleColor = Color.fromRGBO(209, 243, 249, 1);
  static const Color borderColor = Color.fromRGBO(239, 234, 234, 1.0);
  static const Color blackColor = Colors.black;
  static const Color whiteColor = Colors.white;

  //dark theme variants
  static const Color darkBackgroundColor = Color.fromRGBO(18, 22, 28, 1);
  static const Color darkSurfaceColor = Color.fromRGBO(30, 35, 43, 1);
  static const Color darkFontColor = Color.fromRGBO(224, 235, 245, 1);
  static const Color darkBorderColor = Color.fromRGBO(55, 61, 70, 1);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  //page background
  static Color background(BuildContext context) =>
      isDark(context) ? darkBackgroundColor : whiteColor;

  //cards, bubbles, containers sitting on top of the background
  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurfaceColor : whiteColor;

  //primary readable text color
  static Color fontColor(BuildContext context) =>
      isDark(context) ? darkFontColor : mainFontColor;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorderColor : borderColor;
}
