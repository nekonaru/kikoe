/// Mirror of the model registry in core/src/model/model_registry.cpp.
/// Keep the two in sync when models change.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

class ModelEntry {
  const ModelEntry(this.name, this.filename, this.sizeBytes, this.note);
  final String name;
  final String filename;
  final int sizeBytes;
  final String note;

  double get sizeMb => sizeBytes / (1024 * 1024);

  String cachedPath(String cacheDir) => p.join(cacheDir, filename);

  bool isCached(String cacheDir) =>
      File(cachedPath(cacheDir)).existsSync();
}

/// Display order matches docs (smallest to largest).
const List<ModelEntry> kModels = [
  ModelEntry('tiny', 'ggml-tiny.bin', 77691713, 'fastest, lowest quality'),
  ModelEntry('base', 'ggml-base.bin', 147951465, 'fast, decent quality'),
  ModelEntry('small', 'ggml-small.bin', 487601967, 'recommended default'),
  ModelEntry('medium', 'ggml-medium.bin', 1533763059, 'high quality, slower'),
  ModelEntry('large', 'ggml-large-v3.bin', 3095033483, 'best quality, slowest'),
  ModelEntry('large-v3-turbo', 'ggml-large-v3-turbo.bin', 1624555275, 'near-large quality, faster'),
  ModelEntry('tiny-q5_1', 'ggml-tiny-q5_1.bin', 32152673, 'tiny, quantised'),
  ModelEntry('base-q5_1', 'ggml-base-q5_1.bin', 59707625, 'base, quantised'),
  ModelEntry('small-q5_1', 'ggml-small-q5_1.bin', 190085487, 'small, quantised'),
  ModelEntry('medium-q5_0', 'ggml-medium-q5_0.bin', 539212467, 'medium, quantised'),
  ModelEntry('large-v3-turbo-q5_0', 'ggml-large-v3-turbo-q5_0.bin', 574041195, 'turbo, quantised'),
];

ModelEntry? findModel(String name) {
  for (final m in kModels) {
    if (m.name == name) return m;
  }
  return null;
}
