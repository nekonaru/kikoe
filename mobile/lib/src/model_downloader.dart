/// Model downloader for Android. The native downloader (curl + SHA-256)
/// cannot run on Android, so this does the same job in Dart: resume support,
/// progress events, and SHA-256 verification against the registry values in
/// model_menu.dart. Mirrors core/src/model/model_manager.cpp.
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'model_menu.dart';

class ModelChecksumException implements Exception {
  const ModelChecksumException(this.name);
  final String name;
  @override
  String toString() => 'model $name failed checksum verification';
}

class ModelDownloadException implements Exception {
  const ModelDownloadException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ModelDownloader {
  ModelDownloader._();

  static final instance = ModelDownloader._();

  /// Download [model] into [modelDir] (must exist). Resumes an interrupted
  /// download when a .part file with a sane size is present.
  ///
  /// Calls [onProgress] with percent 0-100 during the download. Throws
  /// [ModelChecksumException] if the file fails SHA-256 verification after
  /// download (the .part file is deleted in that case).
  Future<String> download(
    MobileModel model, {
    required String modelDir,
    void Function(int percent)? onProgress,
  }) async {
    final finalPath = p.join(modelDir, model.filename);
    if (await File(finalPath).exists()) {
      final ok = await _sha256File(finalPath) == model.sha256;
      if (ok) return finalPath;
      // Corrupt cache: download again.
      await File(finalPath).delete();
    }

    final partPath = '$finalPath.part';
    var existing = 0;
    final part = File(partPath);
    if (await part.exists()) {
      existing = await part.length();
      if (existing >= model.sizeBytes) {
        await part.delete();
        existing = 0;
      }
    }

    final request = http.Request('GET', Uri.parse(model.url()));
    if (existing > 0) {
      request.headers['range'] = 'bytes=$existing-';
    }
    request.headers['user-agent'] = 'kikoe/0.1';

    final client = http.Client();
    http.StreamedResponse response;
    try {
      response = await client.send(request);
    } catch (e) {
      client.close();
      throw ModelDownloadException('network error: $e');
    }

    // 200 for a fresh download, 206 (partial content) when resuming.
    final resuming = existing > 0 && response.statusCode == 206;
    if (!resuming && response.statusCode != 200) {
      await response.stream.drain<void>();
      client.close();
      throw ModelDownloadException('HTTP ${response.statusCode} for ${model.url()}');
    }

    final sink = await part.open(mode: existing > 0 && resuming ? FileMode.writeOnlyAppend : FileMode.writeOnly);
    var received = existing;
    final total = model.sizeBytes;
    try {
      await for (final chunk in response.stream) {
        await sink.writeFrom(chunk);
        received += chunk.length;
        onProgress?.call(total == 0 ? 0 : (received * 100) ~/ total);
      }
    } finally {
      await sink.close();
      client.close();
    }

    final digest = await _sha256File(partPath);
    if (digest != model.sha256) {
      await part.delete();
      throw ModelChecksumException(model.name);
    }

    if (await File(finalPath).exists()) await File(finalPath).delete();
    await part.rename(finalPath);
    onProgress?.call(100);
    return finalPath;
  }

  Future<String> _sha256File(String path) async {
    // Streamed SHA-256 so a 500 MB model does not sit in memory.
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  }
}
