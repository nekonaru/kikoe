/// Mirror of the model registry in core/src/model/model_registry.cpp.
/// Keep the two in sync; the mobile downloader uses these SHA-256 values to
/// verify what it fetches (curl is not available on Android).
library;

class MobileModel {
  const MobileModel(this.name, this.filename, this.sizeBytes, this.sha256, this.note);
  final String name;
  final String filename;
  final int sizeBytes;
  final String sha256;
  final String note;

  double get sizeMb => sizeBytes / (1024 * 1024);

  String url() =>
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$filename';
}

/// Subset suited for phones: small and below, plus quantised variants.
/// Order is display order.
const List<MobileModel> kMobileModels = [
  MobileModel('tiny-q5_1', 'ggml-tiny-q5_1.bin', 32152673,
      '818710568da3ca15689e31a743197b520007872ff9576237bda97bd1b469c3d7',
      'fastest, lowest quality'),
  MobileModel('tiny', 'ggml-tiny.bin', 77691713,
      'be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21',
      'fast, basic quality'),
  MobileModel('base-q5_1', 'ggml-base-q5_1.bin', 59707625,
      '422f1ae452ade6f30a004d7e5c6a43195e4433bc370bf23fac9cc591f01a8898',
      'very fast, good quality'),
  MobileModel('base', 'ggml-base.bin', 147951465,
      '60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe',
      'fast, decent quality'),
  MobileModel('small-q5_1', 'ggml-small-q5_1.bin', 190085487,
      'ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb',
      'recommended'),
  MobileModel('small', 'ggml-small.bin', 487601967,
      '1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b',
      'higher quality'),
  MobileModel('medium-q5_0', 'ggml-medium-q5_0.bin', 539212467,
      '19fea4b380c3a618ec4723c3eef2eb785ffba0d0538cf43f8f235e7b3b34220f',
      'high quality, slower'),
  MobileModel('large-v3-turbo-q5_0', 'ggml-large-v3-turbo-q5_0.bin', 574041195,
      '394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2',
      'near-large quality'),
];

MobileModel? findMobileModel(String name) {
  for (final m in kMobileModels) {
    if (m.name == name) return m;
  }
  return null;
}
