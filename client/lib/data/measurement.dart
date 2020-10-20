import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'settings.dart';
import 'sharedPreferences.dart';

final String urlServer = "http://test.atmosphere.tools/v1/";
String token = "";

class Measurement {
  final String date;
  final int value;

  Measurement({this.date, this.value});

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      date: (json['startDate']) as String,
      value: json['samples'][0]['values'][0][0] as int,
    );
  }
}

class MyRow {
  final DateTime timeStamp;
  final int cost;
  MyRow(this.timeStamp, this.cost);
}

String minutesPssedFromLastConnection(String timeStamp) {
  DateTime currentTime = new DateTime.now();
  Duration difference = currentTime.difference(DateTime.parse(timeStamp));
  return difference.inMinutes.toString();
}

bool connectionStatus(String timeStamp, SettingsModel settings) {
  DateTime currentTime = new DateTime.now();
  Duration difference = currentTime.difference(DateTime.parse(timeStamp));
  if (difference.inMinutes <= settings.sendMeasureInterval + 5) {
    return true;
  } else
    return false;
}

int getMaxOfMeasurements(List<Measurement> measurements) {
  int max = 500;
  measurements.forEach((element) => {
        if (element.value < max) {max = element.value}
      });
  return max;
}

int getMinOfMeasurements(List<Measurement> measurements) {
  int min = 0;
  measurements.forEach((element) => {
        if (element.value > min) {min = element.value}
      });
  return min;
}

List<double> getListOfPercentage(
    List<Measurement> measurements, SettingsModel settings) {
  List<double> returnList = new List<double>();
  for (int index = 0; index < measurements.length; index++) {
    returnList.add(settings.getPercentageLevel(measurements[index].value));
  }
  return returnList;
}

List<charts.Series<MyRow, DateTime>> getList1(
    List<Measurement> measurements, SettingsModel settings) {
  final data = new List<MyRow>();
  for (int i = 0; i < measurements.length; i++) {
    data.add(new MyRow(DateTime.parse(measurements[i].date),
        settings.getPercentageLevel(measurements[i].value).floor()));
  }
  return [
    new charts.Series<MyRow, DateTime>(
      id: 'Cost',
      domainFn: (MyRow row, _) => row.timeStamp,
      measureFn: (MyRow row, _) => row.cost,
      data: data,
    ),
  ];
}

Future<List<Measurement>> getJsonData() async {
  DateTime currentTime = new DateTime.now();
  final String url = urlServer +
      "measurements?filter={\"thing\":\"tank\",\"startDate\": {\"\$gt\":\"" +
      currentTime.subtract(new Duration(days: 1)).toIso8601String() +
      "\",\"\$lt\":\"" + currentTime.toIso8601String() + "\"}}&limit=300&page=1";
  String currentTimeStr = currentTime.toIso8601String();
  print(currentTimeStr);
  var response = await http.get(
      // Encode the url
      Uri.encodeFull(url),
      headers: {
        //HttpHeaders.contentTypeHeader: "application/json",
        HttpHeaders.authorizationHeader: token
      });
  print(response.body);

  if (response.statusCode == 401) {
    response = await http.post(
      Uri.encodeFull(urlServer + "login"), 
      headers: {
      //HttpHeaders.contentTypeHeader: "application/json"
      }, 
      body: {
      'username': await getUsername(),
      'password': await getPassword()
    });
    print(response.body);
    if (response.statusCode == 200) {
      token = json.decode(response.body)['token'];
      response = await http.get(
          // Encode the url
          Uri.encodeFull(url),
          headers: {
            //HttpHeaders.contentTypeHeader: "application/json",
            HttpHeaders.authorizationHeader: token
          });
      if (response.statusCode == 200) {
        var convertDataToJson = json.decode(response.body);
        convertDataToJson = convertDataToJson['docs'];
        // If the call to the server was successful, parse the JSON.
        return compute(parseMeasurement, json.encode(convertDataToJson));
      } else {
        // If that call was not successful, throw an error.
        throw Exception('Failed to load scritp');
      }
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load scritp');
    }
    /*
    setState(() {
      var convertDataToJson = json.decode(response.body);
      //data = convertDataToJson['docs'];
    });
    return "Success";
    */
  } else if (response.statusCode == 200) {
    var convertDataToJson = json.decode(response.body);
    convertDataToJson = convertDataToJson['docs'];
    // If the call to the server was successful, parse the JSON.
    return compute(parseMeasurement, json.encode(convertDataToJson));
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load scritp');
  }
}

List<Measurement> parseMeasurement(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Measurement>((json) => Measurement.fromJson(json)).toList();
}
