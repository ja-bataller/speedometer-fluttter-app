import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:gender_selection/gender_selection.dart';

class TextToSpeechSettingsForm extends StatelessWidget {
  TextToSpeechSettingsForm({
    @required this.isTTSActive,
    @required this.isTTSFemale,
    @required this.currentDuration,
    @required this.activeSetter,
    @required this.femaleSetter,
    @required this.durationSetter,
    Key key,
  }) : super(key: key);

  final bool isTTSActive;
  final bool isTTSFemale;
  final Duration currentDuration;

  final void Function(bool) activeSetter;
  final void Function(bool) femaleSetter;
  final void Function(int) durationSetter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
        padding: const EdgeInsets.only(top: 10, bottom: 0, left: 14, right: 14),
        width: MediaQuery.of(context).size.width / 2 - 20,
        height: MediaQuery.of(context).size.height / 2 - 00,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF505050),
        ),
        alignment: Alignment.center,
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Voice assistant:  ',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Switch(
                  value: isTTSActive,
                  onChanged: (bool newIsActive) => activeSetter(newIsActive),
                  activeColor: Colors.lightBlueAccent,
                ),
              ],
            ),
            GenderSelection(
              selectedGender: (isTTSFemale) ? Gender.Female : Gender.Male,
              unSelectedGenderTextStyle: const TextStyle(color: Colors.white),
              onChanged: (Gender gender) {
                bool isFemale = gender == Gender.Female;
                femaleSetter(isFemale);
              },
              size: 100,
              padding: const EdgeInsets.all(0),
            ),
          ],
        ),
      ),
    );
  }
}
