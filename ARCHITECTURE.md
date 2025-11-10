# TOON Parser Architecture

## Overview

The TOON parser is built using Racc (Ruby parser generator) with a custom indentation-aware lexer.

## Component Architecture

```
┌─────────────────────────────────────────────┐
│           User Code                         │
│   result = Toon.parse(toon_string)         │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      Toon Module (lib/toon.rb)             │
│   - parse(string)                           │
│   - decode(string)                          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│   ToonParser (lib/toon_parser.tab.rb)      │
│   [Racc-generated LALR parser]             │
│   - Applies grammar rules                   │
│   - Builds parse tree                       │
│   - Calls semantic actions                  │
└─────────────────────────────────────────────┘
                    ↑
                    │ tokens
┌─────────────────────────────────────────────┐
│   ToonLexer (lib/toon_lexer.rb)            │
│   - Tokenizes input                         │
│   - Tracks indentation levels               │
│   - Emits INDENT/DEDENT tokens             │
└─────────────────────────────────────────────┘
                    ↑
                    │ text
┌─────────────────────────────────────────────┐
│           TOON Text Input                   │
└─────────────────────────────────────────────┘
```

## Lexer (ToonLexer)

### Responsibilities
1. **Tokenization**: Convert text to tokens (IDENTIFIER, NUMBER, COLON, etc.)
2. **Indentation Tracking**: Maintain indent stack and emit INDENT/DEDENT
3. **Line Management**: Handle line-by-line processing

### Key Features

#### Indentation Handling
```ruby
@indent_stack = [0]  # Stack of indentation levels
```

When indentation increases: emit `INDENT`  
When indentation decreases: emit `DEDENT` (possibly multiple)

#### Token Types
- `IDENTIFIER` - Names (users, items, etc.)
- `NUMBER` - Numeric values
- `LBRACKET`, `RBRACKET` - `[` and `]`
- `LBRACE`, `RBRACE` - `{` and `}`
- `COLON` - `:`
- `COMMA` - `,`
- `INDENT` - Indentation increase
- `DEDENT` - Indentation decrease
- `NEWLINE` - Line break

### Example Tokenization

Input:
```toon
users[2]{id,name}:
  1,Ada
  2,Bob
```

Tokens:
```
IDENTIFIER("users")
LBRACKET
NUMBER("2")
RBRACKET
LBRACE
IDENTIFIER("id")
COMMA
IDENTIFIER("name")
RBRACE
COLON
NEWLINE
INDENT
NUMBER("1")
COMMA
IDENTIFIER("Ada")
NEWLINE
NUMBER("2")
COMMA
IDENTIFIER("Bob")
NEWLINE
DEDENT
```

## Parser (ToonParser)

### Grammar Structure

```
document → statements
statements → statement | statements statement
statement → schema_block | field_assignment | NEWLINE

schema_block → schema_header NEWLINE INDENT block_content DEDENT
schema_header → IDENTIFIER [SIZE] {FIELDS} :
field_assignment → IDENTIFIER : value | data_row
data_row → value_list
```

### Semantic Actions

The parser includes Ruby code that processes the parse tree:

1. **`process_statements(statements)`**
   - Main processing function
   - Handles schemas, fields, and data rows
   - Builds the final data structure

2. **`build_array_from_rows(schema, data_rows)`**
   - Converts tabular rows into array of hashes
   - Maps values to field names

### Example Parse Flow

Input:
```toon
users[2]{id,name}:
  1,Ada
  2,Bob
```

Parse Tree:
```
document
  └─ statements
      └─ schema_block
          ├─ schema_header: {name: "users", size: 2, fields: ["id", "name"]}
          └─ block_content
              ├─ data_row: ["1", "Ada"]
              └─ data_row: ["2", "Bob"]
```

Semantic Processing:
```ruby
schema = {name: "users", size: 2, fields: ["id", "name"]}
rows = [
  {values: ["1", "Ada"]},
  {values: ["2", "Bob"]}
]

build_array_from_rows(schema, rows)
# => [
#   {"id" => "1", "name" => "Ada"},
#   {"id" => "2", "name" => "Bob"}
# ]
```

## Data Flow Example

### Input TOON
```toon
items[1]{users,status}:
  users[2]{id,name}:
    1,Ada
    2,Bob
  status: active
```

### Lexer Output (Tokens)
```
IDENTIFIER("items"), LBRACKET, NUMBER("1"), RBRACKET,
LBRACE, IDENTIFIER("users"), COMMA, IDENTIFIER("status"), RBRACE, COLON,
NEWLINE, INDENT,
  IDENTIFIER("users"), LBRACKET, NUMBER("2"), RBRACKET,
  LBRACE, IDENTIFIER("id"), COMMA, IDENTIFIER("name"), RBRACE, COLON,
  NEWLINE, INDENT,
    NUMBER("1"), COMMA, IDENTIFIER("Ada"), NEWLINE,
    NUMBER("2"), COMMA, IDENTIFIER("Bob"), NEWLINE,
  DEDENT,
  IDENTIFIER("status"), COLON, IDENTIFIER("active"), NEWLINE,
DEDENT
```

### Parser Output (AST)
```ruby
{
  type: :schema,
  header: {name: "items", size: 1, fields: ["users", "status"]},
  content: [
    {
      type: :schema,
      header: {name: "users", size: 2, fields: ["id", "name"]},
      content: [
        {type: :data_row, values: ["1", "Ada"]},
        {type: :data_row, values: ["2", "Bob"]}
      ]
    },
    {type: :field, name: "status", value: "active"}
  ]
}
```

### Final Result
```ruby
{
  "items" => [
    {
      "users" => [
        {"id" => "1", "name" => "Ada"},
        {"id" => "2", "name" => "Bob"}
      ],
      "status" => "active"
    }
  ]
}
```

## Key Algorithms

### Indentation Tracking

```ruby
def next_token
  if @pos == 0  # Start of line
    indent = count_leading_spaces()
    current_indent = @indent_stack.last
    
    if indent > current_indent
      @indent_stack.push(indent)
      return [:INDENT, nil]
    elsif indent < current_indent
      emit_dedents_until(indent)
      return [:DEDENT, nil]
    end
  end
  # ... continue tokenizing
end
```

### Schema Processing

```ruby
def process_statements(statements)
  result = {}
  current_schema = nil
  data_rows = []
  
  statements.each do |stmt|
    case stmt[:type]
    when :schema
      # Finalize previous schema with accumulated rows
      if current_schema && !data_rows.empty?
        result[current_schema[:name]] = build_array_from_rows(current_schema, data_rows)
        data_rows = []
      end
      
      # Process new schema
      current_schema = stmt[:header]
      nested_result = process_statements(stmt[:content])
      
      # Check if schema has data rows or nested schemas
      # ... build appropriate structure
      
    when :field
      result[stmt[:name]] = stmt[:value]
      
    when :data_row
      data_rows << stmt[:values]
    end
  end
  
  result
end
```

## File Structure

```
lib/
├── toon.rb              # Main interface module
├── toon_lexer.rb        # Indentation-aware lexer
├── toon_parser.y        # Racc grammar definition
└── toon_parser.tab.rb   # Generated parser (don't edit!)
```

## Build Process

```
toon_parser.y (grammar source)
      ↓
   [racc compiler]
      ↓
toon_parser.tab.rb (generated parser)
      ↓
   [gem build]
      ↓
toon_parser-0.1.0.gem
```

## Performance Considerations

- **Lexer**: O(n) where n is input length
- **Parser**: O(n) for LALR parsing
- **Semantic Actions**: O(n) for tree processing
- **Overall**: Linear time complexity

## Extension Points

### Adding New Token Types

1. Update `ToonLexer#next_token`
2. Add token to grammar (`token NEW_TOKEN`)
3. Add grammar rules using the token
4. Update semantic actions if needed

### Adding New Grammar Rules

1. Edit `lib/toon_parser.y`
2. Add rule with semantic action
3. Recompile: `racc -o lib/toon_parser.tab.rb lib/toon_parser.y`
4. Test thoroughly

### Example: Adding String Literals

Lexer:
```ruby
when '"'
  return [:STRING, scan_string]
```

Grammar:
```
token STRING

value
  : IDENTIFIER { result = val[0] }
  | NUMBER { result = val[0] }
  | STRING { result = val[0] }  # New!
  ;
```

## Testing Strategy

1. **Unit Tests**: Individual components (lexer, parser functions)
2. **Integration Tests**: Full parse of TOON examples
3. **Edge Cases**: Empty input, deep nesting, large files
4. **Error Cases**: Invalid syntax, wrong indentation

## Debugging Tips

### Enable Racc Debug Mode
```ruby
parser = ToonParser.new
parser.parse(input, true)  # Enable debug output
```

### Check Lexer Output
```ruby
lexer = ToonLexer.new(input)
while (token = lexer.next_token) != [false, false]
  p token
end
```

### Inspect Parse Tree
Add debug output in semantic actions:
```ruby
{ 
  p [:schema_block, val[0], val[3]]  # Debug
  result = { type: :schema, ... }
}
```

## Known Limitations

1. **Values are strings**: No automatic type conversion
2. **No string escaping**: Commas in values not supported
3. **Fixed indentation**: Must use 2 spaces
4. **No comments**: Comment syntax not implemented

## Future Improvements

- Type inference (convert "123" → 123)
- String literals with escaping
- Variable indentation width
- Comment support
- Better error messages with line numbers
- Streaming parser for large files
