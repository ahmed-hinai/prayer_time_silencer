import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CorrectionsStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/corrections.json');
  }

  Future<dynamic> readCorrections() async {
    Map currentValue = {
      'Fajr': '0',
      'Dhuhr': '0',
      'Asr': '0',
      'Maghrib': '0',
      'Isha': '0'
    };
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      // If encountering an error, return 0
      //print(' is this from here perhapse ?? $e');
      return currentValue;
    }
  }

  Future<File> writeCorrections(response) async {
    final file = await _localFile;

    // Write the file

    return file.writeAsString(json.encode(response));
  }
}

class CreateCorrections {
  late Map<String, String> corrections = {};
  late var importedCorrections;
  CorrectionsStorage correctionsStorage = CorrectionsStorage();

  CreateCorrections({required this.importedCorrections});

  Future<void> createCorrections() async {
    for (String key in importedCorrections.keys) {
      corrections[key] = importedCorrections[key];
      correctionsStorage.writeCorrections(corrections);
    }
  }
}
