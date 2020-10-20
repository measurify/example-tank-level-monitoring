import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:iTank/pages/rootPage.dart';
import 'settingsPage.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:iTank/data/measurement.dart';
import 'package:iTank/data/settings.dart';
import 'package:iTank/data/sharedPreferences.dart';

final double borderRadius = 20.0;

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => new HomePageState();

  //HomePage({Key key, @required settings}) : super(key: key);
}

class HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Measurement> measurements;
  SettingsModel settings;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Color(0xffE5E5E5),
      appBar: buildAppBar(),
      body: RefreshIndicator(
        backgroundColor: Colors.white,
        semanticsLabel: "Updateing...",
        key: _refreshIndicatorKey,
        onRefresh: _resetPressed,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: FutureBuilder(
            future: getJsonScript(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return Text("${snapshot.error}");
              else if (snapshot.hasData) {
                settings = snapshot.data;
                return Form(
                  key: _formKey,
                  child: FutureBuilder<List<Measurement>>(
                      future: getJsonData(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError)
                          return Text("${snapshot.error}");
                        else if (snapshot.hasData) {
                          measurements = snapshot.data;
                          return buildPortraitLayout();
                        } else {
                          return Container(
                            height: MediaQuery.of(context).size.height - 100.0,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      }),
                );
              } else {
                return Container(
                  height: MediaQuery.of(context).size.height - 100.0,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    final title = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Image.asset(
              'assets/images/icon-orange.png',
              filterQuality: FilterQuality.high,
              height: 30,
            ),
          ),
          Text("iTank"),
          SizedBox(width: 18),
        ],
      ),
    );

    return AppBar(
      title: title,
      leading: new IconButton(
          icon: const Icon(Icons.exit_to_app),
          tooltip: 'Show Snackbar',
          onPressed: () {
            logOut();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RootPage(),
              ),
            );
          }),
      actions: <Widget>[
        new IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Show Snackbar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                ),
              );
            })
      ],
    );
  }

  Container buildPortraitLayout() {
    return Container(
      //height: MediaQuery.of(context).size.height - 100.0,
      color: Color(0xffE5E5E5),
      child: Center(
          child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            height: 250,
            child: Row(
              //mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(right: 8.0, left: 8.0, top: 8.0),
                    child: currentLevelItem(
                        "Livello Vasca",
                        measurements[0].value,
                        minutesPssedFromLastConnection(measurements[0].date) +
                            " Minuti fa"),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    //mainAxisAlignment: MainAxisAlignment.spaceAround,
                    //mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                          child: textItems(
                              "Massimo",
                              (settings.getPercentageLevel(
                                          getMaxOfMeasurements(measurements)))
                                      .floor()
                                      .toString() +
                                  " %"),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                          child: textItems(
                              "Minimo",
                              (settings.getPercentageLevel(
                                          getMinOfMeasurements(measurements)))
                                      .floor()
                                      .toString() +
                                  " %"),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 8.0, top: 8.0, right: 8.0, bottom: 50.0),
            child: graphItem("Grafico misurazioni", "Ultime 24 ore"),
          ),
        ],
      )),
    );
  }

  Material textItems(String title, String subtitle) {
    return Material(
      color: Colors.white,
      elevation: 14.0,
      borderRadius: BorderRadius.circular(borderRadius),
      //shadowColor: Color(0x802196F3),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      title,
                      textScaleFactor: 1.5,
                      style: TextStyle(
                        //fontSize: 25.0,

                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(1.0),
                    child: Text(
                      "Ultime 24 ore",
                      textScaleFactor: 1,
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 6.0),
                    child: Text(
                      subtitle,
                      textScaleFactor: 1.8,
                      style: TextStyle(
                        //fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Material currentLevelItem(
      String title, int dataPercent, String lastDataUpdate) {
    return Material(
      color: Colors.white,
      //elevation: 14.0,
      borderRadius: BorderRadius.circular(borderRadius),
      shadowColor: Color(0x802196F3),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  title,
                  textScaleFactor: 1.8,
                  style: TextStyle(
                    //fontSize: 25.0,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: CircularPercentIndicator(
                  radius: 125.0,
                  lineWidth: 18.0,
                  animation: true,
                  percent:
                      settings.getPercentageLevel(measurements[0].value) / 100,
                  animateFromLastPercent: true,
                  center: Text(
                    settings
                            .getPercentageLevel(measurements[0].value)
                            .floor()
                            .toString() +
                        " %",
                    textScaleFactor: 1.8,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ), //fontSize: 28.0
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: Colors.blue,
                ),
              ),
              Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        lastDataUpdate,
                        textScaleFactor: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blueGrey,
                        ),
                      ),
                      buildConnectionStatus(),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Material graphItem(String title, String subtitle) {
    return Material(
      color: Colors.white,
      elevation: 14.0,
      borderRadius: BorderRadius.circular(borderRadius),
      shadowColor: Color(0x802196F3),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          title,
                          textScaleFactor: 1.4,
                          style: TextStyle(
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(1.0),
                        child: Text(
                          subtitle,
                          textScaleFactor: 0.8,
                          style: TextStyle(
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: Container(
                            height: 200.0,
                            width: 350.0,
                            child: new charts.TimeSeriesChart(
                                getList1(measurements, settings),
                                animate: true,
                                flipVerticalAxis: false,
                                // Customize the gridlines to use a dash pattern.
                                primaryMeasureAxis: new charts.NumericAxisSpec(
                                    renderSpec: charts.GridlineRendererSpec(
                                        lineStyle: charts.LineStyleSpec(
                                  dashPattern: [4, 4],
                                ))))),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Text buildConnectionStatus() {
    if (connectionStatus(measurements[0].date, settings)) {
      return Text(
        " (Online)",
        textScaleFactor: 1,
        style: TextStyle(
          color: Colors.green,
        ),
      );
    } else {
      return Text(
        " (Offline)",
        textScaleFactor: 1,
        style: TextStyle(
          color: Colors.red,
        ),
      );
    }
  }

  Future<Null> _resetPressed() async {
    print('refreshing stocks...');
    return getJsonData().then((_measurements) {
      setState(() => measurements = _measurements);
    });
  }
}
