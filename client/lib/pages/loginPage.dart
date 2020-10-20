import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:iTank/pages/homePage.dart';
import 'package:http/http.dart' as http;
import 'package:iTank/data/sharedPreferences.dart';

final String urlGet =
    "http://test.atmosphere.tools/v1/scripts/water-level-script";
final String urlLogin = "http://test.atmosphere.tools/v1/login";

class LoginScreen extends StatelessWidget {
  static const routeName = '/auth';

  Duration get loginTime => Duration(milliseconds: timeDilation.ceil() * 2250);

  Future<String> _authUser(LoginData loginData) async {
    var response = await http.post(Uri.encodeFull(urlLogin),
        headers: {"Accept": "application/json"},
        body: {'username': loginData.name, 'password': loginData.password});
    if (response.statusCode == 200) {
      await saveCredential(loginData.name, loginData.password);
      return null;
      //return null;
    } else {
      return 'Username or password not exists';
    }
  }

  /*
  Future<String> _recoverPassword(String name) {
    print('Name: $name');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(name)) {
        return 'Username not exists';
      }
      return null;
    });
  }

  
  Future<String> _loginUser(LoginData data) {
    return Future.delayed(loginTime).then((_) {
      if (!mockUsers.containsKey(data.name)) {
        return 'Username not exists';
      }
      if (mockUsers[data.name] != data.password) {
        return 'Password does not match';
      }
      return null;
    });
  }

  Future<String> _recoverPassword(String name) {
    return Future.delayed(loginTime).then((_) {
      if (!mockUsers.containsKey(name)) {
        return 'Username not exists';
      }
      return null;
    });
  }
 */
  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'iTank',
      logo: 'assets/images/icon-orange.png',
      logoTag: 'near.huscarl.loginsample.logo',
      titleTag: 'near.huscarl.loginsample.title',
      messages: LoginMessages(
        usernameHint: 'Username',
        passwordHint: 'Password',
      ),
      theme: LoginTheme(
        titleStyle: TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontFamily: 'SourceSansPro',
          fontWeight: FontWeight.bold,
          letterSpacing: 6,
        ),
      ),
      emailValidator: (value) {
        if (value.isEmpty) {
          return "Email is empty";
        }
        return null;
      },
      passwordValidator: (value) {
        if (value.isEmpty) {
          return 'Password is empty';
        }
        return null;
      },
      /*
      onLogin: (loginData) {
        print('Login info');
        print('Name: ${loginData.name}');
        print('Password: ${loginData.password}');
        return _loginUser(loginData);
      },
      onSignup: (loginData) {
        print('Signup info');
        print('Name: ${loginData.name}');
        print('Password: ${loginData.password}');
        return _loginUser(loginData);
      },
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(FadePageRoute(
          builder: (context) => DashboardScreen(),
        ));
      },
      onRecoverPassword: (name) {
        print('Recover password info');
        print('Name: $name');
        return _recoverPassword(name);
        // Show new password dialog
      },
      */
      onLogin: (loginData) {
        return _authUser(loginData);
      },
      onSignup: null,
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => HomePage(),
        ));
      },
      onRecoverPassword: null,
      showDebugButtons: false,
    );
  }
}
