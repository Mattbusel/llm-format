# CLAUDE.md — llm-format

## Build & Run

```bash
# Build all examples with CMake
cmake -B build
cmake --build build

# Run examples
./build/basic_format
./build/nested_schema
./build/validate_only

# Or compile a single example directly (no CMake needed)
g++ -std=c++17 -Wall -Wextra -I include examples/basic_format.cpp -o basic_format
./basic_format
```

## Single-Header Constraint

**Everything must stay in `include/llm_format.hpp`.** Never split into separate
`.cpp` or `.hpp` files. Never add a `src/` directory. The point of this library
is that users copy one file and are done.

Implementation code lives inside:
```cpp
#ifdef LLM_FORMAT_IMPLEMENTATION
// ... all function bodies here ...
#endif
```

Declarations (structs, function signatures) live above that guard, visible to
all translation units.

## API Surface (quick reference)

```cpp
// Parse raw JSON text → JsonValue tree
llm::JsonValue v = llm::parse_json(str);

// Serialize back to string
std::string s = llm::to_json(v, /*pretty=*/true);

// Access values
v["key"].as_string()   // string field
v["n"].as_number()     // double
v["flag"].as_bool()    // bool
v["arr"][0]            // array element (const JsonValue&)
v.contains("key")      // bool
v.size()               // element count (array or object)

// Define a schema
llm::Schema schema;
schema.name = "MySchema";
schema.fields = {
    {"field_name", "string", /*required=*/true, "Description"},
    {"count",      "number", true,  ""},
    {"tags",       "array",  false, "Optional tags"},
};

// Validate an already-parsed value
llm::ValidationResult vr = llm::validate(value, schema);
// vr.valid, vr.errors

// Enforce schema with LLM retries
llm::FormatConfig cfg;
cfg.max_retries    = 3;
cfg.strip_markdown = true;
cfg.allow_extra_fields = true;

llm::FormatResult result = llm::enforce_schema(
    "Your base prompt here",
    schema,
    [](const std::string& prompt) -> std::string {
        // Call your LLM API and return the text response
        return your_api_call(prompt);
    },
    cfg
);

if (result.valid) { /* use result.value */ }
```

## Common Mistakes

1. **Throwing from `llm_fn`**: Do not throw inside the LLM callback. Return an
   empty string or partial response on error. `enforce_schema` will detect the
   invalid JSON, build a correction prompt, and retry.

2. **Adding dependencies**: Do not add nlohmann/json, cURL, libfmt, or anything
   else. The library must compile with a stock C++17 compiler and nothing else.

3. **Assuming API availability in `validate_only.cpp`**: That example is
   intentionally offline — it calls `parse_json` and `validate` directly without
   any LLM. Do not add network calls to it.

4. **Forgetting `#define LLM_FORMAT_IMPLEMENTATION`**: Define this macro in
   exactly one `.cpp` file before the include. Multiple definitions will cause
   linker duplicate symbol errors.

5. **Using `<regex>` for markdown stripping**: `strip_markdown_fences` in
   `detail::` uses plain `std::string::find` and `rfind`. Do not replace it with
   a regex — it would add overhead and a dependency on `<regex>`.

## How `strip_markdown` Works

The function `detail::strip_markdown_fences(s)`:
1. Calls `s.find("```")` to locate the opening fence.
2. Advances past the fence and any language tag (e.g., `json`) on the same line.
3. Skips the trailing newline(s).
4. Calls `s.rfind("```")` to locate the closing fence (last occurrence).
5. Trims trailing newlines before the close.
6. Returns the substring between open and close.

If no fence is found, the original string is returned unchanged.

## Field Types

Supported `Field::type` values: `"string"`, `"number"`, `"bool"`, `"array"`,
`"object"`. Any other value is accepted by the validator (treated as unknown →
pass). There is no recursive schema validation for nested objects or arrays.
