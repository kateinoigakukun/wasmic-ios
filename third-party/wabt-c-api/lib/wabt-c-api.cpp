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

using namespace wabt;

extern "C" bool wabt_c_api_compile_wat(const char *input_filename,
                                       const uint8_t *wat_bytes,
                                       const size_t wat_bytes_len,
                                       const uint8_t **wasm_bytes,
                                       size_t *wasm_bytes_len) {
  std::unique_ptr<WastLexer> lexer =
      WastLexer::CreateBufferLexer(input_filename, wat_bytes, wat_bytes_len);

  Result result;
  Errors errors;
  std::unique_ptr<Module> module;
  Features s_features;
  bool s_validate = true;

  WastParseOptions parse_wast_options(s_features);
  result = ParseWatModule(lexer.get(), &module, &errors, &parse_wast_options);

  if (Succeeded(result) && s_validate) {
    ValidateOptions options(s_features);
    result = ValidateModule(module.get(), &errors, options);
  }

  if (Succeeded(result)) {
    MemoryStream stream;
    WriteBinaryOptions s_write_binary_options;
    s_write_binary_options.features = s_features;
    result = WriteBinaryModule(&stream, module.get(), s_write_binary_options);

    if (Succeeded(result)) {
      const OutputBuffer &buffer = stream.output_buffer();
      *wasm_bytes = buffer.data.data();
      *wasm_bytes_len = buffer.size();
    }
  }
  auto line_finder = lexer->MakeLineFinder();
  FormatErrorsToFile(errors, Location::Type::Text, line_finder.get());
  return result != Result::Ok;
}
