# RTOON - Token Object Oriented Notation Parser

[![CI](https://github.com/zoobean/rtoon/actions/workflows/ci.yml/badge.svg)](https://github.com/zoobean/rtoon/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
[![Gem Version](https://badge.fury.io/rb/rtoon.svg)](https://badge.fury.io/rb/rtoon)

A Ruby gem for parsing and encoding **Token Object Oriented Notation (TOON)** — a tabular, schema-based data format with indentation-based structure.

Inspired by [toon-format/toon](https://github.com/toon-format/toon) which is written in TypeScript and for TypeScript projects.

## What is TOON?

TOON is a human-readable data serialization format designed for structured tabular data. It combines the clarity of CSV with the flexibility of JSON, using indentation to express hierarchy.

**Key Features:**
- 📋 **Schema declarations** with explicit field definitions
- 📊 **Tabular data rows** for compact representation
- 🌳 **Indentation-based nesting** for clear hierarchy
- 📏 **Array size hints** for structure documentation
- 🔄 **Round-trip encoding** (Ruby ↔ TOON)

### Quick Example

**TOON Format:**
```toon
items[1]{users,status}:
  users[2]{id,name}:
    1,Ada
    2,Bob
  status: active
```

**Parses to Ruby:**
```ruby
{
  "items" => [
    {
      "users" => [
        { "id" => "1", "name" => "Ada" },
        { "id" => "2", "name" => "Bob" }
      ],
      "status" => "active"
    }
  ]
}
```

## Installation

**Via RubyGems:**
```bash
gem install rtoon
```

**Via Bundler** (add to `Gemfile`):
```ruby
gem 'rtoon'
```

Then run:
```bash
bundle install
```

## Quick Start

```ruby
require 'rtoon'

# Parse TOON → Ruby
toon_string = <<~TOON
  users[2]{id,name}:
    1,Ada
    2,Bob
TOON

result = Rtoon.parse(toon_string)
# => {"users" => [{"id" => "1", "name" => "Ada"}, {"id" => "2", "name" => "Bob"}]}

# Encode Ruby → TOON
data = {"users" => [{"id" => "1", "name" => "Ada"}]}
toon = Rtoon.encode(data)
# => "users[1]{id,name}:\n  1,Ada\n"
```

## Usage Examples

### Basic Parsing

```ruby
require 'rtoon'

toon_string = <<~TOON
  users[2]{id,name}:
    1,Ada
    2,Bob
TOON

result = Rtoon.parse(toon_string)
# => {"users" => [{"id" => "1", "name" => "Ada"}, {"id" => "2", "name" => "Bob"}]}

# Access data
result["users"][0]["name"]  # => "Ada"
result["users"][1]["id"]    # => "2"
```

### Schema Declarations

Define data structures with schemas:

```toon
products[3]{id,name,price}:
  1,Widget,100
  2,Gadget,200
  3,Gizmo,300
```

### Nested Structures

```ruby
toon = <<~TOON
  company[1]{depts,location}:
    depts[2]{name,size}:
      engineering,50
      sales,20
    location: NYC
TOON

result = Rtoon.parse(toon)
# Access nested data
result["company"][0]["depts"][0]["name"]  # => "engineering"
result["company"][0]["location"]          # => "NYC"
```

### Field Assignments

```ruby
toon = <<~TOON
  name: John
  age: 30
  active: true
TOON

result = Rtoon.parse(toon)
# => {"name" => "John", "age" => "30", "active" => "true"}
```

### Encoding Ruby to TOON

```ruby
data = {
  "products" => [
    {"id" => "1", "name" => "Widget", "price" => "99"},
    {"id" => "2", "name" => "Gadget", "price" => "149"}
  ]
}

toon = Rtoon.encode(data)
puts toon
# Output:
# products[2]{id,name,price}:
#   1,Widget,99
#   2,Gadget,149
```

## TOON Syntax

### Schema Declaration

```
identifier[size]{field1,field2,...}:
```

- **identifier**: Name of the data structure
- **[size]**: Optional array size hint (can be any number)
- **{fields}**: Comma-separated list of field names
- **:** Indicates content follows on indented lines

### Data Rows

```
value1,value2,value3
```

Comma-separated values matching the schema fields in order.

### Indentation

- Use **2 spaces** for each nesting level
- Indentation defines the structure hierarchy
- Empty lines are ignored

### Complete Example

```toon
database[1]{tables,version}:
  tables[3]{name,records,indexed}:
    users,1000,yes
    posts,5000,yes
    comments,20000,no
  version: 3
```

Parses to:

```ruby
{
  "database" => [
    {
      "tables" => [
        { "name" => "users", "records" => "1000", "indexed" => "yes" },
        { "name" => "posts", "records" => "5000", "indexed" => "yes" },
        { "name" => "comments", "records" => "20000", "indexed" => "no" }
      ],
      "version" => "3"
    }
  ]
}
```

## API Reference

### `Rtoon.parse(string)` → Hash/Array

Parses a TOON-formatted string and returns a Ruby data structure.

**Parameters:**
- `string` (String) - TOON formatted text

**Returns:**
- `Hash` or `Array` - Parsed data structure

**Raises:**
- `Rtoon::Parser::ParseError` - On invalid syntax

**Example:**
```ruby
result = Rtoon.parse("users[1]{id,name}:\n  1,Ada\n")
# => {"users" => [{"id" => "1", "name" => "Ada"}]}
```

### `Rtoon.decode(string)` → Hash/Array

Alias for `Rtoon.parse(string)`. Provided for semantic clarity when deserializing.

**Example:**
```ruby
result = Rtoon.decode(toon_string)  # Same as Rtoon.parse
```

### `Rtoon.encode(hash, indent_level = 0)` → String

Converts a Ruby data structure to TOON format.

**Parameters:**
- `hash` (Hash/Array) - Ruby data structure to encode
- `indent_level` (Integer) - Starting indentation level (default: `0`)

**Returns:**
- `String` - TOON-formatted text

**Example:**
```ruby
data = {"users" => [{"id" => "1", "name" => "Ada"}]}
toon = Rtoon.encode(data)
# => "users[1]{id,name}:\n  1,Ada\n"
```

### Error Handling

```ruby
begin
  result = Rtoon.parse(invalid_toon)
rescue Rtoon::Parser::ParseError => e
  puts "Parse error: #{e.message}"
  # Example: "Parse error at line 3: unexpected token '}'"
end
```

## Features

- ✅ **Schema-based declarations** - Define structure with field names
- ✅ **Tabular data rows** - Compact CSV-like data representation
- ✅ **Indentation-based nesting** - Clear hierarchical structure
- ✅ **Array size hints** - Optional size documentation
- ✅ **Field assignments** - Simple key-value pairs
- ✅ **Multi-level nesting** - Unlimited depth support
- ✅ **Round-trip encoding** - Parse and encode seamlessly
- ✅ **Pure Ruby** - No external dependencies
- ✅ **Empty line handling** - Flexible formatting

## Grammar & Parsing

TOON uses a context-free grammar parsed with **Racc** (Ruby's LALR parser generator).

**Grammar Elements:**
- **Statements** - Schema blocks or field assignments
- **Schema Block** - Header + indented content
- **Schema Header** - `name[size]{fields}:`
- **Data Rows** - Comma-separated values
- **Field Assignment** - `name: value`
- **Indentation** - INDENT/DEDENT tokens (2 spaces)

**Parser Pipeline:**
```
TOON Text → Lexer (tokenization) → Parser (grammar) → Semantic Processor → Ruby Data
```

👉 **See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed implementation.**

## Development

### Prerequisites

- Ruby 2.7 or higher
- Racc (included with Ruby standard library)

```bash
ruby --version  # Check Ruby version
ruby -e "require 'racc/parser'; puts 'Racc available'"
```

### Setup

```bash
# Clone the repository
git clone https://github.com/zoobean/rtoon.git
cd rtoon

# Install dependencies (if any)
bundle install

# Run tests
ruby test/toon_test.rb
```

### Building from Source

```bash
# 1. Edit grammar (if needed)
vim lib/rtoon/parser.y

# 2. Compile grammar with Racc
racc -o lib/rtoon/parser.tab.rb lib/rtoon/parser.y

# 3. Run tests
ruby test/toon_test.rb

# 4. Build gem
gem build rtoon.gemspec

# 5. Install locally
gem install rtoon-0.1.0.gem
```

### Running Tests

```bash
ruby test/toon_test.rb
```

**Expected output:**
```
Run options: --seed 12345

# Running:

...........

Finished in 0.123456s, 89.10 runs/s, 316.87 assertions/s.
11 runs, 39 assertions, 0 failures, 0 errors, 0 skips
```

### Running Examples

```bash
# See all examples in action
ruby example.rb

# Test with a custom TOON file
ruby -e "require './lib/rtoon'; p Rtoon.parse(File.read('test_example.toon'))"
```

## Architecture Overview

```
┌──────────────────┐
│   TOON Text      │
└────────┬─────────┘
         ↓
┌──────────────────┐
│  Rtoon::Lexer    │  ← Tokenization + indentation tracking
└────────┬─────────┘
         ↓ tokens
┌──────────────────┐
│  Rtoon::Parser   │  ← Racc-generated LALR(1) parser
└────────┬─────────┘
         ↓ AST
┌──────────────────┐
│ Semantic Proc.   │  ← Build final data structure
└────────┬─────────┘
         ↓
┌──────────────────┐
│  Ruby Hash/Array │
└──────────────────┘
```

### Project Structure

```
lib/
├── rtoon.rb                  # Public API (parse, decode, encode)
└── rtoon/
    ├── lexer.rb              # Indentation-aware lexer
    ├── parser.y              # Racc grammar source
    ├── parser.tab.rb         # Generated parser (auto-generated)
    └── encoder.rb            # Ruby → TOON encoder

test/
└── toon_test.rb              # Test suite

ARCHITECTURE.md               # Detailed architecture documentation
```

👉 **Read [ARCHITECTURE.md](ARCHITECTURE.md) for implementation details.**

## Limitations & Considerations

**Current Limitations:**
- ⚠️ Values are returned as strings (no automatic type conversion)
- ⚠️ No string escaping (commas in values not supported)
- ⚠️ Fixed 2-space indentation requirement
- ⚠️ No comment syntax

**Tips:**
- Use descriptive field names for clarity
- Add size hints for documentation
- Handle type conversion in your application code
- Avoid commas in data values (they're delimiters)

## Roadmap & Future Enhancements

- [ ] Type inference/conversion (numbers, booleans, null)
- [ ] String literals with quotes and escaping
- [ ] Configurable indentation width
- [ ] Comment syntax (`# comment`)
- [ ] Better error messages with context
- [ ] Schema validation mode
- [ ] Streaming parser for large files
- [ ] CLI tool for validation and conversion

## Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository** on GitHub
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes** and add tests
4. **Ensure tests pass** (`ruby test/toon_test.rb`)
5. **Commit your changes** (`git commit -am 'Add amazing feature'`)
6. **Push to the branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

### Development Guidelines

- Add tests for all new features
- Follow Ruby style conventions
- Update documentation for API changes
- Recompile grammar if modifying `parser.y`
- Keep backward compatibility when possible

## Testing

```bash
# Run test suite
ruby test/toon_test.rb

# Run example demonstrations
ruby example.rb

# Test specific TOON file
ruby -e "require './lib/rtoon'; p Rtoon.parse(File.read('your_file.toon'))"
```

## Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Implementation details
- **[README.md](README.md)** - This file

## License

MIT License - See [LICENSE.txt](LICENSE.txt) for details.

## Resources & References

- **Racc Parser Generator**: https://github.com/ruby/racc
- **LALR Parsing**: https://en.wikipedia.org/wiki/LALR_parser
- **Indentation-based Syntax**: https://en.wikipedia.org/wiki/Off-side_rule
- **Ruby Language**: https://www.ruby-lang.org/

## Author

**Antonio Chavez** - [Zoobean](https://github.com/zoobean)

## Support

- 🐛 **Report bugs**: [GitHub Issues](https://github.com/zoobean/rtoon/issues)
- 💬 **Questions**: Open a discussion on GitHub
- 📧 **Contact**: Via GitHub profile

---

**Made with ❤️ using Ruby and Racc**
