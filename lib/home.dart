import 'dart:async';

// PACKAGES USED IN THIS MOBILE APP
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

// SEPARATED FUNCTION - SOURCE CODE
import 'package:speedometer/speedometer.dart';
import 'package:speedometer/voice_assistant.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    this.unit = 'm/s',
    Key key,
  }) : super(key: key);

  final String unit;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  SharedPreferences _sharedPreferences;

  // FOR TEXT TO SPEED NARRATION OF CURRENT VELOCITY
  FlutterTts _ttsService;

  // STREAM TRYING TO SPEAK SPEED
  StreamSubscription _ttsCallback;

  // THE WORDS THAT THE VOICE ASSISTANT WILL READ - SPEED + UNIT
  String get speakText {
    String unit;
    switch (widget.unit) {
      case 'km/h':
        unit = 'kilometers per hour';
        break;

      case 'miles/h':
        unit = 'miles per hour';
        break;

      case 'm/s':
      default:
        unit = 'meters per second';
        break;
    }
    return '${convertedVelocity(_velocity).toStringAsFixed(2)} $unit';
  }

  void _startTTS() {
    if (!_isTTSFemale)
      _ttsService.setVoice({'name': 'en-us-x-tpd-local', 'locale': 'en-US'});
    else
      _ttsService.setVoice({'name': 'en-US-language', 'locale': 'en-US'});

    _ttsCallback?.cancel();

    if (_isTTSActive) _ttsService.speak(speakText);
    _ttsCallback = Stream.periodic(_ttsDuration + Duration(seconds: 1)).listen(
      (event) {
        if (_isTTSActive) _ttsService.speak(speakText);
      },
    );
  }

  // VOICE ASSISTANT TURN ON OR OFF
  bool _isTTSActive = true;

  void setIsActive(bool isActive) => setState(
        () {
          _isTTSActive = isActive;
          _sharedPreferences?.setBool('isTTSActive', _isTTSActive);
          if (isActive)
            _startTTS();
          else
            _ttsCallback?.cancel();
        },
      );

  // VOICE ASSISTANT SWITCH BOY OR GIRL
  bool _isTTSFemale = true;

  void setIsFemale(bool isFemale) => setState(
        () {
          _isTTSFemale = isFemale;
          _sharedPreferences?.setBool('isTTSFemale', _isTTSFemale);
          if (_isTTSActive) _startTTS();
        },
      );

  // VOICE ASSISTANT TALK DURATION
  Duration _ttsDuration;

  void setDuration(int seconds) => setState(
        () {
          _ttsDuration = _secondsToDuration(seconds);
          _sharedPreferences?.setInt('ttsDuration', seconds);
          if (_isTTSActive) _startTTS();
        },
      );

  // FUNCTION TO DESERIALIZE SAVED DURATION
  Duration _secondsToDuration(int seconds) {
    int minutes = (seconds / 60).floor();
    return Duration(minutes: minutes, seconds: seconds % 60);
  }

  // VELOCITY TRACKING
  // GEOLOCATOR PACKAGE IS USED TO FIND VELOCITY
  GeolocatorPlatform locator = GeolocatorPlatform.instance;

  // STREAM THAT EMITS VALUES WHEN VELOCITY UPDATES
  StreamController<double> _velocityUpdatedStreamController =
      StreamController<double>();

  // Current Velocity in m/s
  double _velocity;

  // Highest recorded velocity so far in m/s.
  double _highestVelocity;

  // Velocity in m/s to km/hr converter
  double mpstokmph(double mps) => mps * 18 / 5;

  // Velocity in m/s to miles per hour converter
  double mpstomilesph(double mps) => mps * 85 / 38;

  // Relevant velocity in chosen unit
  double convertedVelocity(double velocity) {
    velocity = velocity ?? _velocity;

    if (widget.unit == 'm/s')
      return velocity;
    else if (widget.unit == 'km/h')
      return mpstokmph(velocity);
    else if (widget.unit == 'miles/h') return mpstomilesph(velocity);
    return velocity;
  }

  @override
  void initState() {
    super.initState();

    //SPEEDOMETER - UPDATES WHEN VELOCITY CHANGES
    locator
        .getPositionStream(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        )
        .listen(
          (Position position) => _onAccelerate(position.speed),
        );

    // SET VELOCITY TO 0 WHEN APP IS OPENED
    _velocity = 0;
    _highestVelocity = 0.0;

    // SETUP VOICE ASSISTANT
    _ttsService = FlutterTts();
    _ttsService.setStartHandler(() => print('VOICE ASSISTANT SPEAKING'));
    _ttsService.setSpeechRate(1);

    // LOAD SAVED SETTINGS - DEFAULT SETTINGS WHEN NO SAVED SETTINGS
    SharedPreferences.getInstance().then(
      (SharedPreferences prefs) {
        _sharedPreferences = prefs;
        _isTTSActive = prefs.getBool('isTTSActive') ?? true;
        _isTTSFemale = prefs.getBool('isTTSFemale') ?? true;
        _ttsDuration = _secondsToDuration(prefs.getInt('ttsDuration') ?? 5);
        // Start text to speech service
        _startTTS();
      },
    );
  }

  // Callback that runs when velocity updates, which in turn updates stream.
  void _onAccelerate(double speed) {
    locator.getCurrentPosition().then(
      (Position updatedPosition) {
        _velocity = (speed + updatedPosition.speed) / 2;
        if (_velocity > _highestVelocity) _highestVelocity = _velocity;
        _velocityUpdatedStreamController.add(_velocity);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double gaugeBegin = 0, gaugeEnd = 200;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                scrollDirection: Axis.vertical,
                children: <Widget>[
                  // StreamBuilder updates Speedometer when new velocity received
                  StreamBuilder<Object>(
                    stream: _velocityUpdatedStreamController.stream,
                    builder: (context, snapshot) {
                      return Speedometer(
                        gaugeBegin: gaugeBegin,
                        gaugeEnd: gaugeEnd,
                        velocity: convertedVelocity(_velocity),
                        maxVelocity: convertedVelocity(_highestVelocity),
                        velocityUnit: widget.unit,
                      );
                    },
                  ),
                  TextToSpeechSettingsForm(
                    isTTSActive: _isTTSActive,
                    isTTSFemale: _isTTSFemale,
                    currentDuration: _ttsDuration,
                    activeSetter: setIsActive,
                    femaleSetter: setIsFemale,
                    durationSetter: setDuration,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // VELOCITY STREAM
    _velocityUpdatedStreamController.close();
    // VOICE ASSISTANT
    _ttsCallback.cancel();
    _ttsService.stop();

    super.dispose();
  }
}
