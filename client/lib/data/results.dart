import 'package:flutter/material.dart';
import 'settings.dart';

void showResults(BuildContext context, SettingsModel model) {
  showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Updated Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildResultsRow('Intervallo di misura', model.measuringLevelInterval.toString() + " min"),
              _buildResultsRow('Intervallo invio dati', model.sendMeasureInterval.toString() + " min"),
              _buildResultsRow('Agg. parametri', model.updatingScriptInterval.toString() + " h"),
              _buildResultsRow('Distanza massima', model.maxHeight.toString() + " cm"),
              _buildResultsRow('Distanza minima', model.minHeight.toString() + " cm"),
              _buildResultsRow('Cellulare', model.phone),
              _buildResultsRow('1° Soglia', model.allertLevel1.toString() + " %"),
              _buildResultsRow('2° Soglia', model.allertLevel2.toString() + " %"),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Widget _buildResultsRow(String name, dynamic value, {bool linebreak: false}) {
  return Column(
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '$name:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _buildValueInline(value, linebreak),
        ],
      ),
      _buildValueOnOwnRow(value, linebreak),
      Container(height: 12.0),
    ],
  );
}

Widget _buildValueInline(dynamic value, bool linebreak) {
  return (linebreak) ? Container() : Text(value.toString());
}

Widget _buildValueOnOwnRow(dynamic value, bool linebreak) {
  return (linebreak) ? Text(value.toString()) : Container();
}
