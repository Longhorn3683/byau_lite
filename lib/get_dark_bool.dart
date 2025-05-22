import 'package:flutter/material.dart';

bool isDarkMode(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return true;
  } else {
    return false;
  }
}
