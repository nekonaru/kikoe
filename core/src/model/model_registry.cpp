#include "model_registry.h"

namespace kikoe {

const std::vector<ModelEntry>& model_registry()
{
    static const std::vector<ModelEntry> kModels = {
        { "tiny",   "ggml-tiny.bin",   "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin",
          "be07e048e1e599ad46341c8d2a135645097a538221678b7acdd1b1919c6e1b21", 77691713ull },
        { "base",   "ggml-base.bin",   "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin",
          "60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe", 147951465ull },
        { "small",  "ggml-small.bin",  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin",
          "1be3a9b2063867b937e64e2ec7483364a79917e157fa98c5d94b5c1fffea987b", 487601967ull },
        { "medium", "ggml-medium.bin", "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin",
          "6c14d5adee5f86394037b4e4e8b59f1673b6cee10e3cf0b11bbdbee79c156208", 1533763059ull },
        { "large",  "ggml-large-v3.bin", "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin",
          "64d182b440b98d5203c4f9bd541544d84c605196c4f7b845dfa11fb23594d1e2", 3095033483ull },
        { "large-v3-turbo", "ggml-large-v3-turbo.bin", "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin",
          "1fc70f774d38eb169993ac391eea357ef47c88757ef72ee5943879b7e8e2bc69", 1624555275ull },
        // Quantised variants, faster on CPU at a small quality cost.
        { "tiny-q5_1",  "ggml-tiny-q5_1.bin",  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny-q5_1.bin",
          "818710568da3ca15689e31a743197b520007872ff9576237bda97bd1b469c3d7", 32152673ull },
        { "base-q5_1",  "ggml-base-q5_1.bin",  "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q5_1.bin",
          "422f1ae452ade6f30a004d7e5c6a43195e4433bc370bf23fac9cc591f01a8898", 59707625ull },
        { "small-q5_1", "ggml-small-q5_1.bin", "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin",
          "ae85e4a935d7a567bd102fe55afc16bb595bdb618e11b2fc7591bc08120411bb", 190085487ull },
        { "medium-q5_0", "ggml-medium-q5_0.bin", "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium-q5_0.bin",
          "19fea4b380c3a618ec4723c3eef2eb785ffba0d0538cf43f8f235e7b3b34220f", 539212467ull },
        { "large-v3-turbo-q5_0", "ggml-large-v3-turbo-q5_0.bin", "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin",
          "394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2", 574041195ull },
        // Silero VAD model, used with --vad for silence filtering.
        { "vad-silero", "ggml-silero-v6.2.0.bin", "https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin",
          "2aa269b785eeb53a82983a20501ddf7c1d9c48e33ab63a41391ac6c9f7fb6987", 885098ull },
    };
    return kModels;
}

const ModelEntry* find_model(const std::string& name)
{
    for (const auto& entry : model_registry()) {
        if (name == entry.name) return &entry;
    }
    return nullptr;
}

} // namespace kikoe
