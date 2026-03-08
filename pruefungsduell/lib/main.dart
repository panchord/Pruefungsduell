import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize databaseFactory for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const PruefungsduellApp());
}
