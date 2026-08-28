import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

//renders Google's own GIS sign-in button, the only supported sign-in
//entry point on web
Widget renderGoogleSignInButton() => gsi_web.renderButton();
