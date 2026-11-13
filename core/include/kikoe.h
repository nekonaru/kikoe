#ifndef KIKOE_H
#define KIKOE_H

/*
 * Kikoe public C API (draft).
 *
 * The stable, versioned API is introduced in Stage 4 of the roadmap.
 * This header currently exposes only the ABI version probe so that the
 * core builds and links across all platforms.
 */

#ifdef KIKOE_STATIC
#  define KK_API
#else
#  if defined(_WIN32)
#    if defined(KIKOE_BUILD_SHARED)
#      define KK_API __declspec(dllexport)
#    elif defined(KIKOE_SHARED)
#      define KK_API __declspec(dllimport)
#    else
#      define KK_API
#    endif
#  else
#    define KK_API
#  endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* Returns the Kikoe ABI version as a single integer: major * 100 + minor. */
KK_API int kk_abi_version(void);

#ifdef __cplusplus
}
#endif

#endif /* KIKOE_H */
