#ifndef KIKOE_MODEL_MANAGER_H
#define KIKOE_MODEL_MANAGER_H

#include "../error.h"
#include "model_registry.h"

#include <string>

namespace kikoe {

// Directory used to cache downloaded models.
// Resolution order: $KIKOE_CACHE_DIR/models, platform default cache location
// (%LOCALAPPDATA%\kikoe\models on Windows, ~/.cache/kikoe/models on Linux or
// ~/Library/Caches/kikoe/models on macOS). Created on demand.
std::string model_cache_dir();

// Resolve `name` to a model file path.
//
// - If `name` is an existing file path, it is returned unchanged.
// - Otherwise `name` is looked up in the registry (see model_registry.h) and
//   the cache dir is checked.
//
// On success returns the path; on failure returns an empty string and sets
// `err` (ModelNotFound when unknown or not downloaded).
std::string resolve_model(const std::string& name, ErrorCode& err);

// Download a registry model into the cache, verifying its SHA-256 afterwards.
// Supports resume: a partial download from an earlier interrupted run is
// continued with HTTP range requests (curl -C -), and a fully present but
// corrupt file is re-downloaded from scratch once.
//
// Requires curl on PATH (ships with Windows 10+, macOS and virtually all
// Linux distributions). Pass nullptr callbacks if progress is not wanted;
// on_progress receives bytes downloaded so far.
ErrorCode download_model(const ModelEntry& entry,
                         void (*on_progress)(unsigned long long bytes_downloaded, unsigned long long total_bytes, void* user) = nullptr,
                         void* user = nullptr);

} // namespace kikoe

#endif // KIKOE_MODEL_MANAGER_H
