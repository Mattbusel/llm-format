# AGENTS.md — llm-format

## Repo Purpose

`llm-format` is a **zero-dependency, single-header C++17 library** that enforces
structured JSON output from LLM API calls. You pass it a schema and an LLM
callback; it handles parsing, validation, and retries with correction prompts
automatically.

## Architecture

Everything lives in **`include/llm_format.hpp`**. There are no source files to
compile separately. The implementation is gated behind:

```cpp
#define LLM_FORMAT_IMPLEMENTATION
```

Define this macro in exactly one translation unit before including the header.
All other translation units include the header without the macro.

**Never split the header into separate files.** The single-header constraint is
intentional — it makes integration trivial (copy one file, done).

## Build

```bash
cmake -B build
cmake --build build
```

Executables land in `build/` (or `build/Debug/` on MSVC). Three examples are
built: `basic_format`, `nested_schema`, `validate_only`.

Alternatively, compile a single example directly:

```bash
g++ -std=c++17 -Wall -Wextra -I include examples/basic_format.cpp -o basic_format
```

## No External Dependencies

The library ships its own recursive descent JSON parser. Do **not** add
nlohmann/json, rapidjson, cURL, libfmt, or any other dependency. The zero-dep
constraint is a hard requirement, not a preference.

## Retry Mechanism

`enforce_schema` runs a loop up to `FormatConfig::max_retries` times:

1. Build prompt = `base_prompt + "\n\n" + schema_to_prompt(schema)`.
2. Call `llm_fn(prompt)` to get a raw string.
3. Optionally strip markdown fences (```` ```json ```` … ```` ``` ````).
4. Parse the result with `parse_json`.
5. Validate against the schema with `validate`.
6. If valid — return immediately.
7. If invalid — build a correction prompt:
   ```
   Your previous response was invalid. Errors: <errors joined by '; '>.
   Please respond again with only valid JSON matching the schema.

   <schema_to_prompt output>
   ```
8. Repeat from step 2 with the correction prompt.

## Public API Surface

```cpp
// Types
struct JsonValue   { ... };   // Parsed JSON node
struct Field       { ... };   // One schema field descriptor
struct Schema      { ... };   // Collection of fields + name
struct FormatConfig{ ... };   // Retry/strip behaviour
struct FormatResult{ ... };   // Output of enforce_schema
struct ValidationResult{ ... }; // Output of validate

// Core functions
JsonValue        parse_json(const std::string&);
std::string      to_json(const JsonValue&, bool pretty = false);
ValidationResult validate(const JsonValue&, const Schema&, bool allow_extra_fields = true);
std::string      schema_to_prompt(const Schema&);
FormatResult     enforce_schema(const std::string& base_prompt,
                                const Schema&,
                                std::function<std::string(const std::string&)> llm_fn,
                                const FormatConfig& = {});
```

## Agent Guidelines

- **Do not** throw exceptions from within `llm_fn` callbacks; return an empty
  string or a best-effort string instead. `enforce_schema` will treat it as an
  invalid response and retry.
- **Do not** add new public headers. Extend `llm_format.hpp` only.
- **Do not** introduce `<regex>` — `strip_markdown` uses plain string search.
- Keep the `#ifdef LLM_FORMAT_IMPLEMENTATION` guard accurate when adding new
  implementation functions.
- All new public API items must be declared above the guard and implemented
  inside it.
