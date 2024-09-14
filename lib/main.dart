import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Corrode/src/rust/frb_generated.dart';
import 'app.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}