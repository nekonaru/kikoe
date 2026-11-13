#ifndef KIKOE_MODEL_REGISTRY_H
#define KIKOE_MODEL_REGISTRY_H

#include <cstddef>
#include <string>
#include <vector>

namespace kikoe {

struct ModelEntry {
    const char* name;        // CLI name, e.g. "small"
    const char* filename;    // cache filename, e.g. "ggml-small.bin"
    const char* url;         // download URL
    const char* sha256;      // expected lowercase hex digest
    unsigned long long size; // bytes, for progress display
};

// Registry of downloadable models. Checksums come from the Hugging Face
// "tree/main" API of ggerganov/whisper.cpp and ggml-org/whisper-vad and were
// captured at the time the registry was written.
const std::vector<ModelEntry>& model_registry();

// Look up a model by CLI name. Returns nullptr when unknown.
const ModelEntry* find_model(const std::string& name);

} // namespace kikoe

#endif // KIKOE_MODEL_REGISTRY_H
