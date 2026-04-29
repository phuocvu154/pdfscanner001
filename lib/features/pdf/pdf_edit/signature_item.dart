import 'dart:io';
import 'package:flutter/material.dart';

class SignatureItem {
  final String imagePath;
  final Color color;
  final DateTime createdAt;

  const SignatureItem({
    required this.imagePath,
    required this.color,
    required this.createdAt,
  });
}
