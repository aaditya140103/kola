import 'package:flutter/material.dart';
import 'package:kola/app/router.dart';
import 'package:kola/design_system/theme/kola_theme.dart';

class KolaApp extends StatelessWidget {
  const KolaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kola',
      debugShowCheckedModeBanner: false,
      theme: KolaTheme.light(),
      darkTheme: KolaTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: kolaRouter,
    );
  }
}
