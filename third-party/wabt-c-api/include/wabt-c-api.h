#ifndef WABT_C_API_H
#define WABT_C_API_H

#include <stdbool.h>
#include <stdint.h>

bool wabt_c_api_compile_wat(
  const char *input_filename,
  const char *wat_bytes, const size_t wat_bytes_len,
  const uint8_t **wasm_bytes, size_t *wasm_bytes_len);

#endif
