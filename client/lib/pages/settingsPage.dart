import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:card_settings/card_settings.dart';
import 'package:iTank/data/settings.dart';
import 'package:iTank/data/results.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key}) : super(key: key);

  @override
  SettingsPageState createState() => new SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  Future<SettingsModel> startSettings;
  SettingsModel settings;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _autoValidate = false;
  bool _showMaterialIOS = true;
  TextAlign _textAlign = TextAlign.center;


  @override
  void initState() {
    super.initState();
    startSettings = getJsonScript();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: new Text("Settings"),
          actions: <Widget>[
            /*Container(
              child: Platform.isIOS
                  ? IconButton(
                      icon: Icon(Icons.swap_calls),
                      onPressed: () {
                        setState(() {
                          _showMaterialIOS = !_showMaterialIOS;
                        });
                      },
                    )
                  : null,
            ),*/
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _savePressed,
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetPressed,
            ),
          ],
        ),
        body: Form(
            key: _formKey,
            child: FutureBuilder<SettingsModel>(
                future: startSettings,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    print(snapshot.data.allertLevel2);
                    settings = snapshot.data;
                    return _buildPortraitLayout();
                  } else if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }
                  return Center(child: CircularProgressIndicator());
                })));
  }

  CardSettings _buildPortraitLayout() {
    return CardSettings.sectioned(
        showMaterialIOS: _showMaterialIOS,
        children: <CardSettingsSection>[
          CardSettingsSection(
            showMaterialIOS: _showMaterialIOS,
            header: CardSettingsHeader(
              label: 'Sensore',
              showMaterialIOS: _showMaterialIOS,
            ),
            children: <Widget>[
              buildCardSettingsNumberPickerMeasureInterval(),
              buildCardSettingsNumberPickerSendingInterval(),
              buildCardSettingsNumberPickerUpdateInterval(),
            ],
          ),
          CardSettingsSection(
            showMaterialIOS: _showMaterialIOS,
            header: CardSettingsHeader(
              label: 'Parametri vasca',
              showMaterialIOS: _showMaterialIOS,
            ),
            children: <Widget>[
              buildCardSettingsIntMaxheight(),
              buildCardSettingsIntMinheight(),
            ],
          ),
          CardSettingsSection(
            showMaterialIOS: _showMaterialIOS,
            header: CardSettingsHeader(
              label: 'Notifiche SMS',
              showMaterialIOS: _showMaterialIOS,
            ),
            children: <Widget>[
              buildCardSettingsPhone(),
              buildCardSettingsNumberPickerAllertLevel1(),
              buildCardSettingsNumberPickerAllertLevel2(),
            ],
          ),
        ]);
  }

  CardSettingsNumberPicker buildCardSettingsNumberPickerMeasureInterval() {
    return CardSettingsNumberPicker(
      showMaterialIOS: _showMaterialIOS,
      label: 'Intervallo di misura',
      labelAlign: TextAlign.start,
      contentAlign: _textAlign,
      initialValue: settings.measuringLevelInterval,
      min: 1,
      max: 10,
      validator: (value) {
        if (value == null) return 'Value is required.';
        if (value > 10) return 'Non valid!';
        if (value < 1) return 'Non valid!';
        return null;
      },
      onSaved: (value) => settings.measuringLevelInterval = value,
      onChanged: (value) {
        setState(() {
          settings.measuringLevelInterval = value;
        });
        showSnackBar('MeasuringLevelInterval', value);
      },
    );
  }

  CardSettingsNumberPicker buildCardSettingsNumberPickerSendingInterval() {
    return CardSettingsNumberPicker(
      showMaterialIOS: _showMaterialIOS,
      label: 'Intervallo invio dati',
      labelAlign: TextAlign.left,
      contentAlign: _textAlign,
      initialValue: settings.sendMeasureInterval,
      min: 5,
      max: 60,
      validator: (value) {
        if (value == null) return 'Value is required.';
        if (value > 60) return 'Non valid!';
        if (value < 1) return 'Non valid!';
        return null;
      },
      onSaved: (value) => settings.sendMeasureInterval,
      onChanged: (value) {
        setState(() {
          settings.sendMeasureInterval = value;
        });
        showSnackBar('MeasuringLevelInterval', value);
      },
    );
  }

  CardSettingsNumberPicker buildCardSettingsNumberPickerUpdateInterval() {
    return CardSettingsNumberPicker(
      showMaterialIOS: _showMaterialIOS,
      label: 'Agg. parametri',
      labelAlign: TextAlign.justify,
      contentAlign: _textAlign,
      initialValue: settings.updatingScriptInterval,
      min: 1,
      max: 24,
      validator: (value) {
        if (value == null) return 'Value is required.';
        if (value > 24) return 'Non valid!';
        if (value < 1) return 'Non valid!';
        return null;
      },
      onSaved: (value) => settings.updatingScriptInterval = value,
      onChanged: (value) {
        setState(() {
          settings.updatingScriptInterval = value;
        });
        showSnackBar('MeasuringLevelInterval', value);
      },
    );
  }

  CardSettingsNumberPicker buildCardSettingsNumberPickerAllertLevel1() {
    return CardSettingsNumberPicker(
      showMaterialIOS: _showMaterialIOS,
      label: 'Livello soglia 1',
      labelAlign: TextAlign.justify,
      contentAlign: _textAlign,
      initialValue: settings.allertLevel1,
      min: 10,
      max: 90,
      validator: (value) {
        if (value == null) return 'Value is required.';
        if (value > 90) return 'No grown-ups allwed!';
        if (value < 10) return 'No Toddlers allowed!';
        return null;
      },
      onSaved: (value) => settings.allertLevel1 = value,
      onChanged: (value) {
        setState(() {
          settings.allertLevel1 = value;
        });
        showSnackBar('MeasuringLevelInterval', value);
      },
    );
  }

  CardSettingsNumberPicker buildCardSettingsNumberPickerAllertLevel2() {
    return CardSettingsNumberPicker(
      showMaterialIOS: _showMaterialIOS,
      label: 'Livello soglia 2',
      labelAlign: TextAlign.justify,
      contentAlign: _textAlign,
      initialValue: settings.allertLevel2,
      min: 10,
      max: 90,
      validator: (value) {
        if (value == null) return 'Value is required.';
        if (value > 90) return 'No grown-ups allwed!';
        if (value < 10) return 'No Toddlers allowed!';
        return null;
      },
      onSaved: (value) => settings.allertLevel2 = value,
      onChanged: (value) {
        setState(() {
          settings.allertLevel2 = value;
        });
        showSnackBar('MeasuringLevelInterval', value);
      },
    );
  }

  CardSettingsInt buildCardSettingsIntMaxheight() {
    return CardSettingsInt(
      showMaterialIOS: _showMaterialIOS,
      label: 'Distanza massima',
      unitLabel: 'cm',
      contentAlign: _textAlign,
      initialValue: settings.maxHeight,
      autovalidate: _autoValidate,
      validator: (value) {
        if (value > 500) return 'Too big distance';
        if (value < 10) return 'Too small distance';
        if (value == null) return 'Insert a value';
        return null;
      },
      onSaved: (value) => settings.maxHeight = value,
      onChanged: (value) {
        setState(() {
          settings.maxHeight = value;
        });
        showSnackBar('Weight', value);
      },
    );
  }

  CardSettingsInt buildCardSettingsIntMinheight() {
    return CardSettingsInt(
      showMaterialIOS: _showMaterialIOS,
      label: 'Distanza minima',
      unitLabel: 'cm',
      contentAlign: _textAlign,
      initialValue: settings.minHeight,
      autovalidate: _autoValidate,
      validator: (value) {
        if (value > 500) return 'Too big distance';
        if (value < 10) return 'Too small distance';
        if (value == null) return 'Insert a value';
        return null;
      },
      onSaved: (value) => settings.minHeight = value,
      onChanged: (value) {
        setState(() {
          settings.minHeight = value;
        });
        showSnackBar('Weight', value);
      },
    );
  }

  CardSettingsPhone buildCardSettingsPhone() {
    return CardSettingsPhone(
      showMaterialIOS: _showMaterialIOS,
      label: 'Num. telefono',
      initialValue: settings.phone,
      autovalidate: _autoValidate,
      validator: (value) {
        if (value == null || value == 0) return 'Insert a number';
        if (value.toString().length != 10) return 'Invalid number';
        return null;
      },
      onSaved: (value) => settings.phone = value,
      onChanged: (value) {
        setState(() {
          settings.phone = value;
        });
        showSnackBar('Phone', value);
      },
    );
  }

  CardSettingsPassword buildCardSettingsPassword() {
    return CardSettingsPassword(
      showMaterialIOS: _showMaterialIOS,
      icon: Icon(Icons.lock),
      initialValue: settings.password,
      autovalidate: _autoValidate,
      validator: (value) {
        if (value == null) return 'Password is required.';
        if (value.length <= 6) return 'Must be more than 6 characters.';
        return null;
      },
      onSaved: (value) => settings.password = value,
      onChanged: (value) {
        setState(() {
          settings.password = value;
        });
        showSnackBar('Password', value);
      },
    );
  }

  CardSettingsEmail buildCardSettingsEmail() {
    return CardSettingsEmail(
      showMaterialIOS: _showMaterialIOS,
      icon: Icon(Icons.person),
      initialValue: settings.username,
      autovalidate: _autoValidate,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email is required.';
        return null;
      },
      onSaved: (value) => settings.username = value,
      onChanged: (value) {
        setState(() {
          settings.username = value;
        });
        showSnackBar('Email', value);
      },
    );
  }

  void showSnackBar(String label, dynamic value) {
    // ignore: deprecated_member_use
    _scaffoldKey.currentState.removeCurrentSnackBar();
    // ignore: deprecated_member_use
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        duration: Duration(seconds: 2),
        content: Text(label + ' = ' + value.toString()),
      ),
    );
  }

  void _resetPressed() {
    _formKey.currentState.reset();
  }

  Future _savePressed() async {
    final form = _formKey.currentState;

    if (form.validate()) {
      bool settingsUpdated =
          await putJsonscript(json.encode(settings.toJson()));
      if (settingsUpdated) {
        form.save();
        showResults(context, settings);
      }
    } else {
      setState(() => _autoValidate = true);
    }
  }
}
