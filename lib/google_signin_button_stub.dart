import 'package:flutter/widgets.dart';

//non-web platforms use the imperative authenticate() flow instead, so no
//rendered button widget is needed here
Widget renderGoogleSignInButton() => const SizedBox.shrink();
