/// Coordinates share intents with engine startup.
///
/// A share can open the app before [AppState.ensureStarted] has loaded the
/// saved model and created the model directory. Calling transcribe at that
/// moment silently does nothing because no model is selected yet. This class
/// keeps the newest shared batch and replays it once startup finishes.
library;

import 'app_state.dart';

class ShareHandler {
  ShareHandler(this._state);

  final AppState _state;
  bool _startupComplete = false;
  List<String>? _pending;

  /// Call when the startup future completes, successfully or not.
  void markStartupComplete() {
    _startupComplete = true;
    final pending = _pending;
    _pending = null;
    if (pending != null) handle(pending);
  }

  /// Accept a batch of shared file paths.
  void handle(List<String> paths) {
    if (paths.isEmpty) return;
    _state.setInputs(paths);
    if (!_startupComplete) {
      _pending = paths;
      return;
    }
    if (_state.selectedModelCached) _state.transcribe();
  }
}
