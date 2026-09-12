import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kola/app/kola_app.dart';
import 'package:pdfrx/pdfrx.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pdfrxFlutterInitialize();
  runApp(const ProviderScope(child: KolaApp()));
}
