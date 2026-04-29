import 'package:flutter/material.dart';

class SignaturePoint {
  final Offset point;
  final bool isBreak;

  SignaturePoint(this.point) : isBreak = false;
  SignaturePoint.breakPoint()
      : point = Offset.zero,
        isBreak = true;
}
