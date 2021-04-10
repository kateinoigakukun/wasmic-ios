#include <cassert>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <string>

#include "src/binary-writer.h"
#include "src/common.h"
#include "src/error-formatter.h"
#include "src/feature.h"
#include "src/filenames.h"
#include "src/ir.h"
#include "src/option-parser.h"
#include "src/resolve-names.h"
#include "src/stream.h"
#include "src/validator.h"
#include "src/wast-parser.h"

#include "wabt-c-api.h"

using namespace wabt;

void translate_error(Error &error, wabt_c_api_error *c_error) {
  switch (error.error_level) {
  case ErrorLevel::Warning:
    c_error->level = wabt_c_api_error_level_warning;
    break;
  case ErrorLevel::Error:
    c_error->level = wabt_c_api_error_level_error;
    break;
  }

  c_error->loc.filename = error.loc.filename.data();
  c_error->loc.first_column = error.loc.first_column;
  c_error->loc.last_column = error.loc.last_column;
  c_error->loc.line = error.loc.line;

  c_error->message = error.message.data();
}

extern "C" bool wabt_c_api_compile_wat(
    const char *input_filename, const char *wat_bytes,
    const size_t wat_bytes_len, void *context,
    void (*handler)(void *context, const uint8_t *bytes, size_t),
    void (*error_handler)(void *context, const wabt_c_api_error *errors,
                          size_t)) {
  std::unique_ptr<WastLexer> lexer =
      WastLexer::CreateBufferLexer(input_filename, wat_bytes, wat_bytes_len);

  Result result;
  Errors errors;
  std::unique_ptr<Module> module;
  Features s_features;

  WastParseOptions parse_wast_options(s_features);
  result = ParseWatModule(lexer.get(), &module, &errors, &parse_wast_options);

  if (Succeeded(result)) {
    ValidateOptions options(s_features);
    result = ValidateModule(module.get(), &errors, options);
  }

  MemoryStream stream;
  if (Succeeded(result)) {
    WriteBinaryOptions s_write_binary_options;
    s_write_binary_options.features = s_features;
    result = WriteBinaryModule(&stream, module.get(), s_write_binary_options);
  }
  if (Succeeded(result)) {
    const OutputBuffer &buffer = stream.output_buffer();
    handler(context, buffer.data.data(), buffer.size());
  } else {
    wabt_c_api_error *c_errors =
        (wabt_c_api_error *)malloc(sizeof(wabt_c_api_error) * errors.size());
    for (size_t idx = 0; idx < errors.size(); idx++) {
      translate_error(errors[idx], c_errors + idx);
    }
    error_handler(context, c_errors, errors.size());
  }
  return result != Result::Ok;
}
