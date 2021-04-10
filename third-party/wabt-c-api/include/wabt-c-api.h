#ifndef WABT_C_API_H
#define WABT_C_API_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum __attribute__((enum_extensibility(closed))) {
  wabt_c_api_error_level_warning = 0,
  wabt_c_api_error_level_error = 1,
} wabt_c_api_error_level;

typedef struct {
  const char *filename;
  int line;
  int first_column;
  int last_column;
} wabt_c_api_text_location;

typedef struct {
  wabt_c_api_error_level level;
  wabt_c_api_text_location loc;
  const char *message;
} wabt_c_api_error;

bool wabt_c_api_compile_wat(
    const char *input_filename, const char *wat_bytes,
    const size_t wat_bytes_len, void *context,
    void (*handler)(void *context, const uint8_t *bytes, size_t),
    void (*error_handler)(void *context, const wabt_c_api_error *errors,
                          size_t));

#ifdef __cplusplus
}
#endif

#endif
