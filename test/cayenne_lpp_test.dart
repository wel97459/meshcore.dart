import 'dart:typed_data';
import 'package:meshcore_dart/src/cayenne_lpp.dart';
import 'package:test/test.dart';

void main() {
  group('CayenneLpp Constants', () {
    test('constants match JS values', () {
      expect(CayenneLpp.lppDigitalInput, 0);
      expect(CayenneLpp.lppDigitalOutput, 1);
      expect(CayenneLpp.lppAnalogInput, 2);
      expect(CayenneLpp.lppAnalogOutput, 3);
      expect(CayenneLpp.lppGenericSensor, 100);
      expect(CayenneLpp.lppLuminosity, 101);
      expect(CayenneLpp.lppPresence, 102);
      expect(CayenneLpp.lppTemperature, 103);
      expect(CayenneLpp.lppRelativeHumidity, 104);
      expect(CayenneLpp.lppAccelerometer, 113);
      expect(CayenneLpp.lppBarometricPressure, 115);
      expect(CayenneLpp.lppVoltage, 116);
      expect(CayenneLpp.lppCurrent, 117);
      expect(CayenneLpp.lppFrequency, 118);
      expect(CayenneLpp.lppPercentage, 120);
      expect(CayenneLpp.lppAltitude, 121);
      expect(CayenneLpp.lppConcentration, 125);
      expect(CayenneLpp.lppPower, 128);
      expect(CayenneLpp.lppDistance, 130);
      expect(CayenneLpp.lppEnergy, 131);
      expect(CayenneLpp.lppDirection, 132);
      expect(CayenneLpp.lppUnixTime, 133);
      expect(CayenneLpp.lppGyrometer, 134);
      expect(CayenneLpp.lppColour, 135);
      expect(CayenneLpp.lppGps, 136);
      expect(CayenneLpp.lppSwitch, 142);
      expect(CayenneLpp.lppPolyline, 240);
    });
  });

  group('CayenneLpp Parsing', () {
    test('parses temperature correctly', () {
      // Channel 1, Type Temperature (103), Value 25.5 -> 255 (0x00FF)
      final bytes = Uint8List.fromList([0x01, 103, 0x00, 0xFF]);
      final result = CayenneLpp.parse(bytes);
      expect(result.length, 1);
      expect(result[0]['channel'], 1);
      expect(result[0]['type'], 103);
      expect(result[0]['value'], 25.5);
    });

    test('parses GPS correctly', () {
      // Channel 2, Type GPS (136)
      // Lat: 1.2345 -> 12345 (0x003039)
      // Lon: 6.7890 -> 67890 (0x010932)
      // Alt: 123.45 -> 12345 (0x003039)
      final bytes = Uint8List.fromList([
        0x02, 136,
        0x00, 0x30, 0x39, // Lat
        0x01, 0x09, 0x32, // Lon
        0x00, 0x30, 0x39  // Alt
      ]);
      final result = CayenneLpp.parse(bytes);
      expect(result.length, 1);
      expect(result[0]['value']['latitude'], 1.2345);
      expect(result[0]['value']['longitude'], 6.7890);
      expect(result[0]['value']['altitude'], 123.45);
    });

    test('parses multiple sensors', () {
      final bytes = Uint8List.fromList([
        0x01, 103, 0x00, 0xFF, // Temp 25.5
        0x03, 116, 0x01, 0xF4  // Voltage 5.00
      ]);
      final result = CayenneLpp.parse(bytes);
      expect(result.length, 2);
      expect(result[0]['value'], 25.5);
      expect(result[1]['value'], 5.00);
    });
  });

  group('CayenneLpp Serialization', () {
    test('round-trip for temperature', () {
      final lpp = CayenneLpp();
      lpp.addTemperature(1, 25.5);
      final bytes = lpp.toBytes();
      
      final parsed = CayenneLpp.parse(bytes);
      expect(parsed.length, 1);
      expect(parsed[0]['value'], 25.5);
    });

    test('round-trip for GPS', () {
      final lpp = CayenneLpp();
      lpp.addGps(2, 1.2345, 6.7890, 123.45);
      final bytes = lpp.toBytes();

      final parsed = CayenneLpp.parse(bytes);
      expect(parsed.length, 1);
      expect(parsed[0]['value']['latitude'], 1.2345);
      expect(parsed[0]['value']['longitude'], 6.7890);
      expect(parsed[0]['value']['altitude'], 123.45);
    });
  });
}
