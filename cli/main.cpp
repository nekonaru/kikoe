/*
 * Kikoe CLI entry point (Stage 1 will implement the real interface).
 */
#include "kikoe.h"

#include <cstdio>

int main()
{
    std::printf("kikoe 0.1.0 (abi %d)\n", kk_abi_version());
    std::printf("The transcription pipeline is implemented in Stage 1 and later. See docs/PRD.md.\n");
    return 0;
}
