import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

class GoogleAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const GoogleAuthButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: web.renderButton(),
      );
}
