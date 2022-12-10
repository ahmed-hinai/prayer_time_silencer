import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class WaitAndPreWaitStoreStart {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/waitAndPreWaitStart.json');
  }

  Future<dynamic> readWaitAndPreWait() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      // If encountering an error, return 0
      //print(' is this from here perhapse ?? $e');
      return '';
    }
  }

  Future<File> writeWaitAndPreWait(response) async {
    final file = await _localFile;

    // Write the file

    return file.writeAsString(json.encode(response));
  }
}

class WaitAndPreWaitStoreEnd {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/waitAndPreWaitEnd.json');
  }

  Future<dynamic> readWaitAndPreWait() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      // If encountering an error, return 0
      //print(' is this from here perhapse ?? $e');
      return '';
    }
  }

  Future<File> writeWaitAndPreWait(response) async {
    final file = await _localFile;

    // Write the file

    return file.writeAsString(json.encode(response));
  }
}
