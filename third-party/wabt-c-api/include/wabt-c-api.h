#ifndef WABT_C_API_H
#define WABT_C_API_H

#include <stdbool.h>
#include <stdint.h>

bool wabt_c_api_compile_wat(
    const char *input_filename, const char *wat_bytes,
    const size_t wat_bytes_len, void *context,
    void (*handler)(void *context, const uint8_t *bytes, size_t));

#endif
