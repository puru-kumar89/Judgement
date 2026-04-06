import 'package:flutter/material.dart';

double hPad(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 360) return 12;
  if (w < 420) return 16;
  return 20;
}

double titleSize(BuildContext context, {double large = 34}) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 360) return large - 6;
  if (w < 420) return large - 3;
  return large;
}
