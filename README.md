# llm-format

**Zero-dependency single-header C++17 library that enforces structured JSON output from any LLM API.**

![C++17](https://img.shields.io/badge/C%2B%2B-17-blue.svg)
![Single Header](https://img.shields.io/badge/single-header-green.svg)
![No Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

```cpp
#define LLM_FORMAT_IMPLEMENTATION
#include "llm_format.hpp"

llm::Schema schema;
schema.fields = {
    {"name", "string", true, "Full name"},
    {"age",  "number", true, "Age in years"},
    {"city", "string", true, "City of residence"},
};

llm::FormatResult result = llm::enforce_schema(
    "Extract from: \"John Smith, 34, Seattle\"",
    schema,
    [](const std::string& prompt) { return your_api_call(prompt); }
);

if (result.valid) {
    std::cout << result.value["name"].as_string() << "\n"; // "John Smith"
    std::cout << result.value["age"].as_number()  << "\n"; // 34
}
```

## How It Works

`enforce_schema` runs a **retry loop** up to `max_retries` times (default 3):

1. Appends a schema description to your base prompt.
2. Calls your `llm_fn` callback with the full prompt.
3. Strips markdown fences if the model wrapped the JSON in ` ```json ` ... ` ``` `.
4. Parses the response with the built-in JSON parser.
5. Validates against your schema (required fields, correct types).
6. Returns immediately on success.
7. On failure, sends a **correction prompt** containing the specific errors:

```
Your previous response was invalid. Errors: Missing required field: "age"; Field "city" has wrong type: expected string.
Please respond again with only valid JSON matching the schema.

Respond with a valid JSON object matching this schema:
{
  "name": <string> — Full name,
  "age": <number> — Age in years,
  "city": <string> — City of residence
}
Respond with only the JSON object, no explanation, no markdown fences.
```

## API Reference

### Types

```cpp
struct JsonValue {
    // Type accessors
    bool is_null() const;    bool is_bool() const;
    bool is_number() const;  bool is_string() const;
    bool is_array() const;   bool is_object() const;

    // Value accessors
    std::string as_string() const;
    double      as_number() const;
    bool        as_bool()   const;

    // Subscript (returns null sentinel on missing key/index — never throws)
    const JsonValue& operator[](const std::string& key) const;
    const JsonValue& operator[](size_t idx) const;

    bool   contains(const std::string& key) const;
    size_t size() const;
};

struct Field {
    std::string name;
    std::string type;        // "string", "number", "bool", "array", "object"
    bool        required = true;
    std::string description;
};

struct Schema {
    std::vector<Field> fields;
    std::string        name;
};

struct FormatConfig {
    int  max_retries        = 3;
    bool strip_markdown     = true;
    bool allow_extra_fields = true;
};

struct FormatResult {
    JsonValue   value;
    int         attempts_used = 0;
    bool        valid         = false;
    std::string raw_response;
};

struct ValidationResult {
    bool                     valid = false;
    std::vector<std::string> errors;
};
```

### Functions

```cpp
// Parse JSON text into a JsonValue tree. Returns null JsonValue on error.
JsonValue parse_json(const std::string& json_str);

// Serialize a JsonValue back to a JSON string.
std::string to_json(const JsonValue& val, bool pretty = false);

// Validate a parsed value against a schema.
ValidationResult validate(const JsonValue& value, const Schema& schema,
                          bool allow_extra_fields = true);

// Generate the schema description prompt fragment.
std::string schema_to_prompt(const Schema& schema);

// Full enforce loop: prompt → LLM → parse → validate → retry on failure.
FormatResult enforce_schema(
    const std::string& base_prompt,
    const Schema& schema,
    std::function<std::string(const std::string& prompt)> llm_fn,
    const FormatConfig& config = {});
```

## Ships With a Complete JSON Parser

No nlohmann/json. No rapidjson. No simdjson. `llm-format` includes a hand-rolled
recursive descent parser that handles:

- Strings with full escape sequences (`\"`, `\\`, `\/`, `\n`, `\r`, `\t`, `\uXXXX`)
- Numbers: integer, float, negative, scientific notation
- Booleans (`true` / `false`) and `null`
- Arbitrarily nested arrays and objects
- Whitespace everywhere it is legal

`operator[]` and `size()` are safe to call on any `JsonValue` — they return a
null sentinel or zero rather than throwing or crashing on wrong types.

## Works With Any LLM API

The `llm_fn` parameter is a plain `std::function<std::string(const std::string&)>`.
You own the HTTP call. Wire it to whichever provider you use:

```cpp
// OpenAI example (pseudocode — use your preferred HTTP client)
auto llm_fn = [](const std::string& prompt) -> std::string {
    return openai_chat("gpt-4o", prompt);
};

// Anthropic example
auto llm_fn = [](const std::string& prompt) -> std::string {
    return anthropic_messages("claude-opus-4-6", prompt);
};

// Any other provider
auto llm_fn = [](const std::string& prompt) -> std::string {
    return my_local_model(prompt);
};
```

## Examples

| Example | What it shows |
|---------|--------------|
| [`examples/basic_format.cpp`](examples/basic_format.cpp) | Extract a `PersonInfo` struct from free text |
| [`examples/nested_schema.cpp`](examples/nested_schema.cpp) | Schema with an `array` field (skills list) |
| [`examples/validate_only.cpp`](examples/validate_only.cpp) | Offline `parse_json` + `validate` — no LLM needed |

## Building the Examples

**CMake:**
```bash
cmake -B build
cmake --build build

./build/basic_format
./build/nested_schema
./build/validate_only
```

**Direct (g++):**
```bash
g++ -std=c++17 -Wall -Wextra -I include examples/basic_format.cpp   -o basic_format
g++ -std=c++17 -Wall -Wextra -I include examples/nested_schema.cpp  -o nested_schema
g++ -std=c++17 -Wall -Wextra -I include examples/validate_only.cpp  -o validate_only
```

**MSVC:**
```bat
cl /std:c++17 /W4 /I include examples\basic_format.cpp /Fe:basic_format.exe
```

## Requirements

- C++17 or later
- Standard library only — no other dependencies

## See Also

| Repo | What it does |
|------|-------------|
| [llm-stream](https://github.com/Mattbusel/llm-stream) | Streaming responses from OpenAI & Anthropic |
| [llm-cache](https://github.com/Mattbusel/llm-cache) | Response caching |
| [llm-cost](https://github.com/Mattbusel/llm-cost) | Token counting + cost estimation |
| [llm-retry](https://github.com/Mattbusel/llm-retry) | Retry logic + circuit breaker |
| **llm-format** *(this repo)* | Structured output / schema enforcement |

## License

MIT License — Copyright (c) 2026 Mattbusel. See [LICENSE](LICENSE).
