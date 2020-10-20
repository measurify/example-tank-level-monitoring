import 'package:flutter/material.dart';
import 'package:iTank/data/sharedPreferences.dart';
import 'loginPage.dart';
import 'homePage.dart';

class RootPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _RootPageState();
}

class _RootPageState extends State<RootPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.accentColor,
      body: Form(
        child: FutureBuilder<bool>(
            future: isLogged(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Text("${snapshot.error}");
              else if (snapshot.hasData) {
                return (snapshot.data ? new HomePage() : new LoginScreen());
              } else {
                //return Center(child: CircularProgressIndicator());
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.asset(
                      'assets/images/icon-orange.png',
                      filterQuality: FilterQuality.high,
                      height: 30,
                    ),
                  ),
                );
              }
            }),
      ),
    );
  }
}
