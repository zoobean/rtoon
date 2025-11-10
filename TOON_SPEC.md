# TOON Format Specification

## Overview
Token Object Oriented Notation (TOON) is a tabular, schema-based data format with indentation-based structure.

## Syntax Elements

### Schema Declaration
```
identifier[size]{field1,field2,...}:
```

- **identifier**: Name of the data structure
- **[size]**: Optional array size hint
- **{fields}**: Comma-separated list of field names
- **:** Indicates content follows

### Data Rows
```
value1,value2,value3
```

Comma-separated values corresponding to the schema fields.

### Nesting
Uses indentation (2 spaces) to indicate nested structures.

### Example
```
items[1]{users,status}:
  users[2]{id,name}:
    1,Ada
    2,Bob
  status: active
```

## Parsed Structure
The above should parse to:
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

## Grammar Rules

1. **Top-level**: Schema declaration or field assignment
2. **Schema**: `name[size]{fields}:` followed by indented content
3. **Field**: `name: value` (simple assignment)
4. **Data rows**: Comma-separated values matching schema fields
5. **Indentation**: 2 spaces per level
6. **Arrays**: Created from schema declarations with size hint
7. **Objects**: Created from schema fields
