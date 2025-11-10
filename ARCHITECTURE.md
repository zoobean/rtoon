# RTOON Architecture

## Overview

RTOON is a Ruby parser for TOON (Token Object Oriented Notation) - a tabular data format that uses indentation to show structure. It uses **Racc** for parsing and a custom lexer that understands indentation.

## How It Works

```
TOON Text → Lexer → Parser → Ruby Hash/Array
```

1. **Lexer** breaks text into tokens and tracks indentation
2. **Parser** applies grammar rules and builds a tree structure
3. **Processor** converts the tree into Ruby objects

## Main Components

### Lexer (`lib/rtoon/lexer.rb`)

Reads TOON text character-by-character and produces tokens.

**Key tokens**:
- `IDENTIFIER` - names like `users`, `status`
- `NUMBER` - numbers like `42`, `3.14`
- `INDENT`/`DEDENT` - indentation changes
- Punctuation: `[`, `]`, `{`, `}`, `:`, `,`

**Example**:
```toon
users[2]{id,name}:
  1,Ada
```

Becomes tokens: `IDENTIFIER("users")`, `LBRACKET`, `NUMBER("2")`, `RBRACKET`, `LBRACE`, `IDENTIFIER("id")`, `COMMA`, `IDENTIFIER("name")`, `RBRACE`, `COLON`, `INDENT`, `NUMBER("1")`, `COMMA`, `IDENTIFIER("Ada")`, `DEDENT`

### Parser (`lib/rtoon/parser.y`)

Defines TOON's grammar rules using Racc.

**Basic grammar**:
```
schema_block  → name[size]{fields}: INDENT content DEDENT
field         → name: value
data_row      → value, value, ...
```

Builds a tree structure from tokens.

### Processor

Converts the tree into Ruby hashes and arrays by:
- Collecting data rows under schemas
- Mapping values to field names
- Building nested structures

## Complete Example

**Input**:
```toon
users[2]{id,name}:
  1,Ada
  2,Bob
status: active
```

**Output**:
```ruby
{
  "users" => [
    { "id" => "1", "name" => "Ada" },
    { "id" => "2", "name" => "Bob" }
  ],
  "status" => "active"
}
```

## Files

```
lib/
├── rtoon.rb              # Main API
└── rtoon/
    ├── lexer.rb          # Tokenizer
    ├── parser.y          # Grammar (source)
    ├── parser.tab.rb     # Generated parser
    └── encoder.rb        # Ruby → TOON
```

## Building

```bash
# Edit grammar
vim lib/rtoon/parser.y

# Compile parser
racc -o lib/rtoon/parser.tab.rb lib/rtoon/parser.y

# Run tests
ruby test/toon_test.rb
```

## Debugging

**View tokens**:
```ruby
lexer = Rtoon::Lexer.new(input)
loop do
  token = lexer.next_token
  break if token == [false, false]
  p token
end
```

**Parser debug mode**:
```ruby
parser = Rtoon::Parser.new
parser.parse(input, true)
```

## Limitations

- All values are strings (no automatic number conversion)
- Commas in values not supported
- Must use 2-space indentation
- No comments
- Basic error messages

## Future Ideas

- Type conversion (strings to numbers/booleans)
- String quotes and escape sequences
- Flexible indentation
- Comment syntax
- Better error messages
- Large file streaming
