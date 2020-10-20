// example viewmodel for the form
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'sharedPreferences.dart';

String token='';
final String urlGet = "http://test.atmosphere.tools/v1/scripts/water-level-script";
final String urlLogin = "http://test.atmosphere.tools/v1/login";

class SettingsModel {
  int sendMeasureInterval;
  int updatingScriptInterval;
  int measuringLevelInterval;

  int maxHeight;
  int minHeight;

  int allertLevel1;
  int allertLevel2;

  String server;
  String username = "example@gmail.com";
  String password = "123456";
  int phone;

  SettingsModel({
    this.maxHeight,
    this.minHeight,
    this.updatingScriptInterval,
    this.measuringLevelInterval,
    this.sendMeasureInterval,
    this.server,
    this.password,
    this.username,
    this.allertLevel1,
    this.allertLevel2,
    this.phone,
  });

  double getPercentageLevel(int currentLevel) {
    double percentageLevel =
        (100 / (minHeight - maxHeight)) * (currentLevel - maxHeight);
    if (0 < percentageLevel && percentageLevel < 100)
      return percentageLevel;
    else if (percentageLevel >= 100) {
      return 100.0;
    } else {
      return 0.0;
    }
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      maxHeight: int.parse(json['maxHeight']),
      minHeight: int.parse(json['minHeight']),
      measuringLevelInterval:
          (int.parse(json['measuringInterval']) / 60).floor(),
      sendMeasureInterval: (int.parse(json['postingInterval']) / 60).floor(),
      updatingScriptInterval:
          (int.parse(json['updatingScriptInterval']) / 60 / 60).floor(),
      phone: int.parse(json['phoneNumber']),
      allertLevel1: int.parse(json['allertLevel1']),
      allertLevel2: int.parse(json['allertLevel2']),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': getJsonString(),
      };

  String getJsonString() {
    return "{\"postingInterval\":\"" +
        (sendMeasureInterval * 60).toString() +
        "\",\"measuringInterval\":\"" +
        (measuringLevelInterval * 60).toString() +
        "\",\"updatingScriptInterval\":\"" +
        (updatingScriptInterval * 60 * 60).toString() +
        "\",\"minHeight\":\"" +
        minHeight.toString() +
        "\",\"maxHeight\":\"" +
        maxHeight.toString() +
        "\",\"phoneNumber\":\"" +
        phone.toString() +
        "\",\"allertLevel1\":\"" +
        allertLevel1.toString() +
        "\",\"allertLevel2\":\"" +
        allertLevel2.toString() +
        "\"}";
  }
}

Future<SettingsModel> getJsonScript() async {
  print(token);
  print(urlGet);
  var response = await http.get(
      // Encode the url
      Uri.encodeFull(urlGet),
      headers: {
        HttpHeaders.contentTypeHeader: "application/json",
        HttpHeaders.authorizationHeader: token
      });
  if (response.statusCode == 401) {
    response = await http.post(Uri.encodeFull(urlLogin),
        //headers: {"Content-Type": "application/json"},
        body: {'username': await getUsername(), 'password': await getPassword()});
    if (response.statusCode == 200) {
      token = json.decode(response.body)['token'];
      response = await http.get(
          // Encode the url
          Uri.encodeFull(urlGet),
          headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.authorizationHeader: token
          });
      if (response.statusCode == 200) {
        var convertDataToJson = json.decode(response.body);
        String code = json.encode(convertDataToJson['code']);
        code = code.substring(1, code.length - 1);
        code = code.replaceAll("\\", "");
        // If the call to the server was successful, parse the JSON.
        return SettingsModel.fromJson(json.decode(code));
      } else {
        // If that call was not successful, throw an error.
        throw Exception('Failed to load scritp');
      }
    } else {
      throw Exception('Login failed');
    }
  } else if (response.statusCode == 200) {
    var convertDataToJson = json.decode(response.body);
    String code = json.encode(convertDataToJson['code']);
    code = code.substring(1, code.length - 1);
    code = code.replaceAll("\\", "");
    return SettingsModel.fromJson(json.decode(code));
  } else {
    throw Exception('Failed to load scritp');
  }
}

Future<bool> putJsonscript(String stringJson) async {
  var response = await http.put(
      // Encode the url
      Uri.encodeFull(urlGet),
      body: stringJson,
      headers: {
        HttpHeaders.contentTypeHeader: "application/json",
        HttpHeaders.authorizationHeader: token
      });
  if (response.statusCode == 401) {
    response = await http.post(Uri.encodeFull(urlLogin),
        headers: {"Accept": "application/json"},
        body: {'username': await getUsername(), 'password': await getPassword()});
    if (response.statusCode == 200) {
      token = json.decode(response.body)['token'];
      response = await http.put(
          // Encode the url
          Uri.encodeFull(urlGet),
          body: stringJson,
          headers: {
            HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.authorizationHeader: token
          });
      if (response.statusCode == 200) {
        // If the call to the server was successful, parse the JSON.
        return true;
      } else {
        // If that call was not successful, throw an error.
        throw Exception('Failed to load scritp');
      }
    } else {
      throw Exception('Login failed');
    }
  } else if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception('Failed to load scritp');
  }
}
