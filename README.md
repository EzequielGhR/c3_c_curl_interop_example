# C3 - C cURL Interoperability example HTTP + JSON Pipeline

## A lightweight HTTP client + JSON tokenizer/parser written in C3, featuring:

- A minimal cURL binding to make GET/POST requests
- A safe, manually-managed Requester abstraction
- A JSON tokenizer, parser, and JsonValue model
- An end-to-end pipeline test that fetches JSON → tokenizes → parses → extracts values
- Clear memory-management patterns designed to be Valgrind-clean

## This project is a learning + experimentation repo to explore:

- Writing low-level bindings in C3
- Managing memory manually
- Building a small JSON library from scratch
- Integrating third-party C libraries (libcurl)
- Designing a clean request/response API

## Repository Structure
```
├── LICENSE
├── project.json       # C3 project manifest
├── README.md
├── src/
│   ├── curl_binding/
│   │   └── curl.c3            # Thin wrapper around libcurl, constants extracted from curl header files.
│   ├── json/
│   │   ├── lexer.c3           # Tokenizer
│   │   ├── parser.c3          # Recursive-descent JSON parser
│   │   └── types.c3           # JsonValue model (object, array, string, number…)
│   ├── main.c3                # CLI entrypoint with multiple test modes
│   └── requests/
│       ├── memory.c3          # Growable memory buffer for cURL callbacks
│       └── requester.c3       # Requester object with GET/POST helpers
```

## Features
- HTTP Client (Requester)
- Simple GET & POST helpers
- Small abstraction over curl_easy_*
- Header support (String[])
- Configurable response capacity
- Automatic memory cleanup (easy handle, slist, buffer)
- Safe error handling via C3 faultdef

## Response Model
```
struct Response {
    Memory* mem;
    int     status;
}
```


### Includes:

```
contents() → returns char*
size()
write_contents()
clear()
```

## JSON Tokenizer

- Converts raw text into typed tokens
- Handles strings, numbers, punctuation, keywords (true/false/null)

## JSON Parser
- Recursive-descent implementation
- Produces a JsonValue:
  - Object (HashMap{String, JsonValue}*)
  - Array (List{JsonValue}*)
  - Number (double for simplicity)
  - Boolean
  - Null
  - String

## Full Processing Pipeline

- `test_pipeline()` shows the full flow:
  - GET request
  - Read body
  - Tokenize
  - Parse JSON
  - Extract fields from the result

## Usage
- Compile: `c3c build`
- Run: `./build/<binary> <argument>`
- Arguments:
  - GET – run a GET request
  - POST – run a POST request
  - PARSE – parse a sample JSON string
  - PIPE – full HTTP → JSON pipeline

## How It Works
### HTTP Request Flow

- Requester.request() sets up:
  - Initialize easy handle
  - Assign URL
  - Assign write callback (memory::w_callback)
  - Allocate Response buffer
  - Perform request
  - Copy curl buffer → Response → clean up temporary state

- All memory allocated during the request is either:
  - Freed inside Requester.cleanup(), or
  - Handed to user inside Response* (caller must free)

### JSON Tokenization & Parsing
- lexer.c3 converts characters into tokens:
```
{      -> TOKEN_LBRACE
"key"  -> TOKEN_STRING
:      -> TOKEN_COLON
123    -> TOKEN_NUMBER
.
.
.
```

- parser.c3 uses recursive descent:
  - parse_object()
  - parse_array()
  - parse_value()

- All parsed structures are freed via:
  - value.free_inner();

## Memory Safety Notes

- This project is intentionally written to be:
  - Free of leaks (Valgrind: "definitely lost: 0 bytes")
  - Explicit in ownership rules
  - Clear about when the caller must free memory
  
- Expected Valgrind "still reachable" memory comes from:
  - libcurl global allocations
  - glibc internals

(These are normal and not leaks.)

## Contributing

Ideas and improvements are welcome:
- Better error messages
- Expand JSON parser (UTF-8 escapes, numbers, edge cases)
- Streaming HTTP responses
- Async request support
- Tests under docs/ or resources/

## License
MIT License — see LICENSE.
