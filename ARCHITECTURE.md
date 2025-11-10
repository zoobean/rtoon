# RTOON Architecture

## Overview

RTOON is a Ruby parser for Token Object Oriented Notation (TOON), a tabular data format with indentation-based structure. The parser is built using **Racc** (Ruby's LALR parser generator) with a custom **indentation-aware lexer**.

## System Architecture

```
┌──────────────────────────────────────────┐
│     TOON Source Text                     │
└──────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────┐
│     Rtoon::Lexer                         │
│  • Tokenization                          │
│  • Indentation tracking (INDENT/DEDENT)  │
│  • Line-by-line processing               │
└──────────────────────────────────────────┘
                 ↓ tokens
┌──────────────────────────────────────────┐
│     Rtoon::Parser (Racc-generated)       │
│  • LALR(1) parsing                       │
│  • Grammar rules matching                │
│  • AST construction                      │
└──────────────────────────────────────────┘
                 ↓ AST
┌──────────────────────────────────────────┐
│     Semantic Processing                  │
│  • process_statements()                  │
│  • build_array_from_rows()               │
│  • Nested structure resolution           │
└──────────────────────────────────────────┘
                 ↓
┌──────────────────────────────────────────┐
│     Ruby Hash/Array Structure            │
└──────────────────────────────────────────┘
```

## Core Components

### 1. Lexer (`lib/rtoon/lexer.rb`)

**Purpose**: Converts TOON text into a stream of tokens while tracking indentation levels.

**Key Responsibilities**:
- Character-by-character scanning
- Token recognition and generation
- Indentation stack management
- Line number tracking

**Token Types**:
| Token | Description | Example |
|-------|-------------|---------|
| `IDENTIFIER` | Names/identifiers | `users`, `status` |
| `NUMBER` | Numeric literals | `42`, `3.14` |
| `LBRACKET`/`RBRACKET` | Square brackets | `[`, `]` |
| `LBRACE`/`RBRACE` | Curly braces | `{`, `}` |
| `COLON` | Colon separator | `:` |
| `COMMA` | Comma separator | `,` |
| `INDENT` | Indentation increase | (virtual) |
| `DEDENT` | Indentation decrease | (virtual) |
| `NEWLINE` | Line terminator | `\n` |

**Indentation Algorithm**:
```ruby
@indent_stack = [0]  # Stack tracks nesting levels

# On each line:
if new_indent > current_indent
  push(new_indent)
  emit INDENT
elsif new_indent < current_indent
  while stack.top > new_indent
    pop()
    emit DEDENT
  end
end
```

**Example**:
```toon
users[2]{id,name}:
  1,Ada
  2,Bob
```

Produces tokens:
```
IDENTIFIER("users"), LBRACKET, NUMBER("2"), RBRACKET,
LBRACE, IDENTIFIER("id"), COMMA, IDENTIFIER("name"), RBRACE, COLON,
NEWLINE, INDENT,
NUMBER("1"), COMMA, IDENTIFIER("Ada"), NEWLINE,
NUMBER("2"), COMMA, IDENTIFIER("Bob"), NEWLINE,
DEDENT
```

### 2. Parser (`lib/rtoon/parser.y`)

**Purpose**: Defines the TOON grammar and generates the parser using Racc.

**Grammar Rules** (simplified):
```
document      → statements
statements    → statement+
statement     → schema_block | field_assignment | NEWLINE

schema_block  → schema_header NEWLINE INDENT block_content DEDENT
schema_header → IDENTIFIER [size]? {fields} :
block_content → statements

field_assignment → IDENTIFIER : value
                | data_row

data_row     → value_list
value_list   → value (, value)*
value        → IDENTIFIER | NUMBER
```

**AST Structure**:
```ruby
# Schema node
{
  type: :schema,
  header: { name: "users", size: 2, fields: ["id", "name"] },
  content: [...]
}

# Field node
{
  type: :field,
  name: "status",
  value: "active"
}

# Data row node
{
  type: :data_row,
  values: ["1", "Ada"]
}
```

### 3. Semantic Processor (embedded in parser)

**Purpose**: Transforms the AST into the final Ruby data structure.

**Key Functions**:

**`process_statements(statements)`**
- Iterates through AST nodes
- Accumulates data rows for schemas
- Recursively processes nested schemas
- Builds the output hash structure

**`build_array_from_rows(schema, data_rows)`**
- Maps row values to schema fields
- Creates array of hash objects
- Handles field/value alignment

**Processing Logic**:
```ruby
def process_statements(statements)
  result = {}
  current_schema = nil
  data_rows = []

  statements.each do |stmt|
    case stmt[:type]
    when :schema
      # Finalize previous schema if data rows exist
      if current_schema && !data_rows.empty?
        result[current_schema[:name]] =
          build_array_from_rows(current_schema, data_rows)
        data_rows = []
      end

      # Process nested content recursively
      nested_result = process_statements(stmt[:content])

      # Determine if schema has data or nested schemas
      # ...assign to result accordingly

    when :field
      result[stmt[:name]] = stmt[:value]

    when :data_row
      data_rows << stmt[:values]
    end
  end

  result
end
```

## Complete Example Flow

### Input
```toon
items[1]{users,status}:
  users[2]{id,name}:
    1,Ada
    2,Bob
  status: active
```

### Step 1: Lexing
```
IDENTIFIER("items"), LBRACKET, NUMBER("1"), ..., COLON, NEWLINE,
INDENT,
  IDENTIFIER("users"), LBRACKET, NUMBER("2"), ..., COLON, NEWLINE,
  INDENT,
    NUMBER("1"), COMMA, IDENTIFIER("Ada"), NEWLINE,
    NUMBER("2"), COMMA, IDENTIFIER("Bob"), NEWLINE,
  DEDENT,
  IDENTIFIER("status"), COLON, IDENTIFIER("active"), NEWLINE,
DEDENT
```

### Step 2: Parsing (AST)
```ruby
{
  type: :schema,
  header: { name: "items", size: 1, fields: ["users", "status"] },
  content: [
    {
      type: :schema,
      header: { name: "users", size: 2, fields: ["id", "name"] },
      content: [
        { type: :data_row, values: ["1", "Ada"] },
        { type: :data_row, values: ["2", "Bob"] }
      ]
    },
    { type: :field, name: "status", value: "active" }
  ]
}
```

### Step 3: Semantic Processing
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

## File Organization

```
lib/
├── rtoon.rb                  # Public API (parse, decode, encode)
└── rtoon/
    ├── lexer.rb              # Indentation-aware lexer
    ├── parser.y              # Racc grammar source
    ├── parser.tab.rb         # Generated parser (auto-generated)
    └── encoder.rb            # Ruby → TOON converter
```

## Development Workflow

### Building the Parser
```bash
# Edit grammar
vim lib/rtoon/parser.y

# Compile with Racc
racc -o lib/rtoon/parser.tab.rb lib/rtoon/parser.y

# Run tests
ruby test/toon_test.rb
```

### Debugging Strategies

**1. Inspect Lexer Output**
```ruby
lexer = Rtoon::Lexer.new(input)
loop do
  token = lexer.next_token
  break if token == [false, false]
  p token
end
```

**2. Enable Parser Debug Mode**
```ruby
parser = Rtoon::Parser.new
parser.parse(input, true)  # Verbose output
```

**3. Add Debug Prints in Semantic Actions**
```ruby
# In parser.y
schema_block
  : schema_header NEWLINE INDENT block_content DEDENT
    {
      p [:DEBUG, val[0], val[3]]  # Debug line
      result = { type: :schema, header: val[0], content: val[3] }
    }
```

## Performance Characteristics

| Component | Complexity | Notes |
|-----------|-----------|-------|
| Lexer | O(n) | Linear scan of input |
| Parser | O(n) | LALR(1) parsing |
| Semantic Processing | O(n) | Single pass tree walk |
| **Overall** | **O(n)** | Linear in input size |

Where n = length of input text.

## Extension Guide

### Adding New Token Types

**1. Lexer** (`lib/rtoon/lexer.rb`):
```ruby
when '"'
  @pos += 1
  return [:STRING, scan_string]
```

**2. Grammar** (`lib/rtoon/parser.y`):
```
token STRING

value
  : IDENTIFIER { result = val[0] }
  | NUMBER { result = val[0] }
  | STRING { result = val[0] }  # New!
  ;
```

**3. Recompile**:
```bash
racc -o lib/rtoon/parser.tab.rb lib/rtoon/parser.y
```

### Adding New Grammar Rules

1. Define rule in `parser.y` with semantic action
2. Recompile with Racc
3. Update `process_statements()` if needed
4. Add tests for new syntax

## Known Limitations

- Values parsed as strings (no type conversion)
- No escape sequences for commas in values
- Fixed 2-space indentation requirement
- No comment support
- Limited error messages (line numbers only)

## Future Enhancements

- [ ] Type inference (convert "123" → 123, "true" → true)
- [ ] String literals with quotes and escaping
- [ ] Configurable indentation width
- [ ] Comment syntax (`# comment`)
- [ ] Better error messages with context
- [ ] Streaming mode for large files
- [ ] Schema validation
- [ ] Optional schema enforcement

## References

- **Racc**: https://github.com/ruby/racc
- **LALR Parsing**: https://en.wikipedia.org/wiki/LALR_parser
- **Off-side Rule**: https://en.wikipedia.org/wiki/Off-side_rule (indentation-based syntax)
