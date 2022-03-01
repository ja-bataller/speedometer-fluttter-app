// PACKAGES USED IN THIS MOBILE APP
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

// SEPARATED FUNCTION - SOURCE CODE
import 'package:speedometer/home.dart';

// MAIN FUNCTION
void main() {
  runApp(NoPermissionApp(hasCheckedPermissions: false));
  WidgetsFlutterBinding.ensureInitialized();

  // GEOLOCATION PERMISSION
  Geolocator.checkPermission().then(
    (LocationPermission permission) {
      // IF THE USER DENIES THE PERMISSION FOR THE LOCATION - THE APP MUST BE RE-INSTALLED
      if (permission == LocationPermission.deniedForever)
        runApp(NoPermissionApp(hasCheckedPermissions: true));
      else // Run app and ask for permissions.
        runApp(SpeedometerApp());
    },
  );
}

class SpeedometerApp extends StatefulWidget {
  @override
  _SpeedometerAppState createState() => _SpeedometerAppState();
}

class _SpeedometerAppState extends State<SpeedometerApp> {
  SharedPreferences sharedPreferences;

  // UNIT OPTIONS
  final List<String> units = const <String>['m/s', 'km/h', 'miles/h'];
  String currentSelectedUnit = 'm/s';

  // SAVE SELECTED UNIT TO PERSISTENT STORAGE, AND UPDATE STATE
  void unitSelectorFunction(String newUnit) {
    if (sharedPreferences != null) sharedPreferences.setString('unit', newUnit);
    setState(() => currentSelectedUnit = newUnit);
  }

  @override
  void initState() {
    super.initState();

    // LOAD SELECTED UNIT
    SharedPreferences.getInstance().then(
      (SharedPreferences prefs) {
        sharedPreferences = prefs;
        setState(
          () => currentSelectedUnit = (prefs.getString('unit') ?? 'm/s'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Voice Speedometer',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            'Speedometer',
            style: Theme.of(context)
                .textTheme
                .headline6
                .copyWith(color: Colors.white),
          ),
          backgroundColor: Color(0xFF505050),
          // Makes one Unit Selection button for each potential unit (m/s, km/h and miles/h programmed)
          actions: units.map<Widget>(
            (String unitType) {
              return UnitSelectionButton(
                unitButtonName: unitType,
                currentSelectedUnit: currentSelectedUnit,
                unitSelector: unitSelectorFunction,
              );
            },
          ).toList(),
        ),
        body: MainScreen(unit: currentSelectedUnit),
      ),
    );
  }
}

// TEXT BUTTON THAT ENABLES USER TO SELECT A PARTICULAR UNIT - m/s ,
class UnitSelectionButton extends StatelessWidget {
  const UnitSelectionButton({
    Key key,
    this.unitButtonName = 'm/s',
    @required this.currentSelectedUnit,
    @required this.unitSelector,
  }) : super(key: key);

  final String unitButtonName, currentSelectedUnit;
  final void Function(String) unitSelector;

  @override
  Widget build(BuildContext context) {
    final Color textColor = unitButtonName != currentSelectedUnit
        ? Colors.white
        : Colors.lightBlueAccent;
    return Container(
      padding: EdgeInsets.only(right: 10),
      child: FlatButton(
        onPressed: () => unitSelector(unitButtonName),
        minWidth: 0,
        padding: EdgeInsets.zero,
        child: Text(unitButtonName, style: TextStyle(color: textColor)),
      ),
    );
  }
}

// THIS MATERIALAPP LAUNCHES WHEN PERMISSIONS IS DENIED PERMANENTLY
class NoPermissionApp extends StatelessWidget {
  const NoPermissionApp({
    Key key,
    @required bool hasCheckedPermissions,
  })  : _hasCheckedPermissions = hasCheckedPermissions ?? true,
        super(key: key);

  final bool _hasCheckedPermissions;

  @override
  Widget build(BuildContext context) {
    Widget outWidget;
    // Splash screen mode
    if (!_hasCheckedPermissions)
      outWidget = Image(
        image: AssetImage('images/splash_image.png'),
        alignment: Alignment.center,
        fit: BoxFit.contain,
      );
    // Error Message mode
    else
      outWidget = Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          'The Location permission is permanently denied!\n' +
              'Please reinstall the app and allow permission.\n' +
              'Thank you.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF505050),
        body: Center(child: outWidget),
      ),
    );
  }
}
