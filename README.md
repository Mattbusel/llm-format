# llm-format

[![CI](https://github.com/Mattbusel/llm-format/actions/workflows/ci.yml/badge.svg)](https://github.com/Mattbusel/llm-format/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![C++17](https://img.shields.io/badge/C%2B%2B-17-blue.svg)
![Single header](https://img.shields.io/badge/single-header-green.svg)

Get schema-valid JSON out of any LLM from C++: validate the reply, and retry with the errors until it conforms.

> Part of **[llm-cpp](https://github.com/Mattbusel/llm-cpp)**, a family of 26 single-header C++ libraries for building on LLM APIs. Each one stands alone: copy one header, include it, done.

Asking a model for JSON works most of the time, and the rest of the time you get markdown fences, a missing field or a string where a number should be. llm-format turns your schema into prompt instructions, strips fences, validates the result, and re-asks the model with the specific validation errors. It has no HTTP code: you pass in a function that calls whichever model you use.

## Features

- Declare a schema as fields with name, type (`string`, `number`, `bool`, `array`, `object`), required flag and description
- `schema_to_prompt()` generates the formatting instructions appended to your prompt
- `enforce_schema()`: call your LLM, strip markdown fences, parse, validate, and retry with a correction prompt (default 3 attempts)
- `validate()` on its own: missing required fields, wrong types, and optional rejection of unexpected fields
- Built-in JSON parser and serializer (`JsonValue`, `parse_json`, `to_json`)
- Provider-agnostic: works with any `std::string(const std::string&)` callable

## Quick start

Requirements: a C++17 compiler. No other dependencies, no network access.

1. Copy [`include/llm_format.hpp`](include/llm_format.hpp) into your project.
2. In exactly one `.cpp` file, `#define LLM_FORMAT_IMPLEMENTATION` before including it. Other files just `#include "llm_format.hpp"`.

```cpp
#define LLM_FORMAT_IMPLEMENTATION
#include "llm_format.hpp"
#include <iostream>

// Plug in any LLM client: a function that takes a prompt and returns text.
std::string my_llm(const std::string& prompt) {
    (void)prompt;
    return "```json\n{\"name\": \"Ada Lovelace\", \"born\": 1815, \"programmer\": true}\n```";
}

int main() {
    llm::Schema schema;
    schema.name   = "Person";
    schema.fields = {
        {"name",       "string", true, "Full name"},
        {"born",       "number", true, "Year of birth"},
        {"programmer", "bool",   true, "Wrote programs"},
    };

    llm::FormatResult r = llm::enforce_schema("Tell me about Ada Lovelace.", schema, my_llm);
    if (r.valid)
        std::cout << r.value["name"].as_string() << " (" << r.value["born"].as_number() << ")"
                  << ", attempts: " << r.attempts_used << "\n";
}
```

Build and run:

```bash
g++ -std=c++17 -I include example.cpp -o example
./example
```

Output:

```text
Ada Lovelace (1815), attempts: 1
```

## API

Everything lives in namespace `llm`.

| Function / type | What it does |
|---|---|
| `enforce_schema(prompt, schema, llm_fn, cfg)` | Return a `FormatResult` (parsed value, attempts used, valid flag, raw response) |
| `validate(value, schema, allow_extra)` | Return a `ValidationResult` with a list of error strings |
| `schema_to_prompt(schema)` | Render the schema as instructions for the model |
| `parse_json(str)`, `to_json(value, pretty)` | JSON parsing and serialization |
| `FormatConfig` | `max_retries` (default 3), `strip_markdown`, `allow_extra_fields` |

## How it works

The first attempt sends your prompt plus the rendered schema. Each reply is stripped of markdown code fences, parsed, and validated against the schema. If it fails, the next prompt tells the model exactly what was wrong ("Missing required field", "wrong type") and asks again, up to `max_retries`.

## Examples

The [`examples/`](examples) folder has runnable programs:

- [`basic_format.cpp`](examples/basic_format.cpp)
- [`nested_schema.cpp`](examples/nested_schema.cpp)
- [`validate_only.cpp`](examples/validate_only.cpp)

Build the examples with CMake:

```bash
cmake -B build
cmake --build build
```

## Limitations

- The schema describes the top-level object's fields and their types; nested objects and arrays are type-checked but their contents are not validated against a sub-schema.
- This is its own schema format, not JSON Schema.

## License

MIT. See [LICENSE](LICENSE).
