# TOON Parser - Token Object Oriented Notation

A Ruby gem for parsing Token Object Oriented Notation (TOON), a tabular, schema-based data format with indentation-based structure.

## What is TOON?

TOON is a data serialization format that combines:
- **Schema declarations** with field definitions
- **Tabular data** for compact representation
- **Indentation-based nesting** for hierarchy
- **Array size hints** for structure clarity

### Example

```toon
items[1]{users,status}:
  users[2]{id,name}:
    1,Ada
    2,Bob
  status: active
```

This parses to:

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

Add this line to your application's Gemfile:

```ruby
gem 'rtoon'
```

Or install it yourself:

```bash
gem install rtoon
```

## Usage

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

Use indentation for nesting:

```toon
company[1]{depts,location}:
  depts[2]{name,size}:
    engineering,50
    sales,20
  location: NYC
```

### Field Assignments

Simple key-value pairs:

```toon
name: John
age: 30
active: true
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

### `Rtoon.parse(string)`

Parses a TOON string and returns a Ruby hash/array structure.

**Parameters:**
- `string` (String): TOON formatted string

**Returns:**
- Hash or Array with parsed data

**Raises:**
- `RtoonParser::ParseError`: If the string contains invalid TOON syntax

### `Rtoon.decode(string)`

Alias for `Rtoon.parse(string)`.

## Features

✅ Schema-based declarations
✅ Tabular data rows
✅ Indentation-based nesting
✅ Array size hints
✅ Field assignments
✅ Multi-level nesting
✅ Empty line handling

## Grammar

TOON uses a context-free grammar parsed with Racc (Ruby parser generator):

- **Statements**: Schema blocks or field assignments
- **Schema Block**: Header + indented content
- **Schema Header**: `name[size]{fields}:`
- **Data Rows**: Comma-separated values
- **Field Assignment**: `name: value`
- **Indentation**: INDENT/DEDENT tokens (2 spaces)

## Development

### Prerequisites

```bash
# Ruby 2.7 or higher
ruby --version

# Racc (included with Ruby)
ruby -e "require 'racc/parser'; puts 'Racc available'"
```

### Building from Source

```bash
# Clone or extract the gem
cd rtoon

# Compile grammar
racc -o lib/rtoon.tab.rb lib/rtoon.y

# Run tests
ruby test/toon_test.rb

# Build gem
gem build rtoon.gemspec
```

### Running Tests

```bash
ruby test/toon_test.rb
```

Expected output:
```
11 runs, 39 assertions, 0 failures, 0 errors, 0 skips
```

## Architecture

```
TOON String
    ↓
RtoonLexer (tokenization + indentation tracking)
    ↓
RtoonParser (Racc-generated parser)
    ↓
Ruby Hash/Array
```

### Components

- **lib/rtoon/lexer.rb**: Indentation-aware lexer
- **lib/rtoon/parser.y**: Racc grammar definition
- **lib/rtoon/parser.tab.rb**: Generated parser (don't edit!)
- **lib/rtoon/encoder.rb**: TOON encoder (Ruby → TOON)
- **lib/rtoon.rb**: Main interface

## Use Cases

TOON is ideal for:

- **Configuration files** with tabular data
- **Database seeds** with schemas and rows
- **API responses** with structured tables
- **Data exports** in readable format
- **Test fixtures** with clear structure

## Limitations

- Values are currently returned as strings (no automatic type conversion)
- No support for nested arrays in data rows
- No string escaping (commas in values not supported)
- Numbers are treated as identifiers/strings

## Future Enhancements

- Type inference/conversion (numbers, booleans)
- String literals with quotes
- Escape sequences for commas in values
- Comments support
- Encoder (Ruby → TOON)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for your changes
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - See LICENSE.txt

## Resources

- Racc: https://github.com/ruby/racc
- Parser theory: https://en.wikipedia.org/wiki/Parsing
- Indentation-based parsing: https://en.wikipedia.org/wiki/Off-side_rule
