#include "kikoe.h"

#include <cstdio>
#include <cstdlib>

int main()
{
    int version = kk_abi_version();
    if (version < 1) {
        std::fprintf(stderr, "kk_abi_version() returned %d, expected >= 1\n", version);
        return 1;
    }
    std::printf("kikoe core ok (abi %d)\n", version);
    return 0;
}
