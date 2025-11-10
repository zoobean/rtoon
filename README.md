# RTOON - Token Object Oriented Notation Parser

[![CI](https://github.com/zoobean/rtoon/actions/workflows/ci.yml/badge.svg)](https://github.com/zoobean/rtoon/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![Gem Version](https://badge.fury.io/rb/rtoon.svg)](https://badge.fury.io/rb/rtoon)

A Ruby gem for parsing and encoding **Token Object Oriented Notation (TOON)** — a human-readable data format combining tabular structure with JSON-like flexibility.'

Inspired by [toon-format/toon](https://github.com/toon-format/toon) which is written in TypeScript and for TypeScript projects.


## What is TOON?

TOON is a data serialization format with schema declarations, tabular rows, and indentation-based nesting.

From the original project description:

> Token-Oriented Object Notation is a compact, human-readable serialization format designed for passing structured data to Large Language Models with significantly reduced token usage. It's intended for LLM input as a lossless, drop-in representation of JSON data.

> TOON's sweet spot is uniform arrays of objects – multiple fields per row, same structure across items. It borrows YAML's indentation-based structure for nested objects and CSV's tabular format for uniform data rows, then optimizes both for token efficiency in LLM contexts. For deeply nested or non-uniform data, JSON may be more efficient.

> TOON achieves CSV-like compactness while adding explicit structure that helps LLMs parse and validate data reliably.

**Example:**
```toon
users[2]{id,name}:
  1,Ada
  2,Bob
```

**Parses to:**
```ruby
{"users" => [{"id" => "1", "name" => "Ada"}, {"id" => "2", "name" => "Bob"}]}
```

## Installation

```bash
gem install rtoon
```

Or add to `Gemfile`:
```ruby
gem 'rtoon'
```

## Quick Start

```ruby
require 'rtoon'

# Parse TOON → Ruby
result = Rtoon.parse("users[1]{id,name}:\n  1,Ada\n")
# => {"users" => [{"id" => "1", "name" => "Ada"}]}

# Encode Ruby → TOON
data = {"users" => [{"id" => "1", "name" => "Ada"}]}
toon = Rtoon.encode(data)
# => "users[1]{id,name}:\n  1,Ada\n"
```

## Syntax

**Schema Declaration:**
```toon
identifier[size]{field1,field2}:
  value1,value2
  value3,value4
```

**Field Assignment:**
```toon
name: John
age: 30
```

**Nested Structure:**
```toon
company[1]{depts,location}:
  depts[2]{name,size}:
    engineering,50
    sales,20
  location: NYC
```

## API

### `Rtoon.parse(string)` / `Rtoon.decode(string)`
Parses TOON-formatted string to Ruby Hash/Array.

### `Rtoon.encode(hash, indent_level = 0)`
Converts Ruby data structure to TOON format.

### Error Handling
```ruby
begin
  result = Rtoon.parse(invalid_toon)
rescue Rtoon::Parser::ParseError => e
  puts "Parse error: #{e.message}"
end
```

## Development

```bash
# Clone and setup
git clone https://github.com/zoobean/rtoon.git
cd rtoon
bundle install

# Run tests
ruby test/toon_test.rb

# Compile grammar (if modified)
racc -o lib/rtoon/parser.tab.rb lib/rtoon/parser.y
```

## Limitations

- Values returned as strings (no automatic type conversion)
- No string escaping (commas in values not supported)
- Fixed 2-space indentation
- No comment syntax

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a Pull Request

See [ARCHITECTURE.md](ARCHITECTURE.md) for implementation details.

## License

MIT License - See [LICENSE.txt](LICENSE.txt)

## Author

**Antonio Chavez** - [Zoobean](https://github.com/zoobean)

Report bugs: [GitHub Issues](https://github.com/zoobean/rtoon/issues)
