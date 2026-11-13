#ifndef KIKOE_SHA256_H
#define KIKOE_SHA256_H

#include <cstdint>
#include <string>

namespace kikoe {

// Compute the SHA-256 of a file, hex encoded lowercase (64 chars).
// Returns an empty string on I/O failure.
std::string sha256_file(const std::string& path);

} // namespace kikoe

#endif // KIKOE_SHA256_H
