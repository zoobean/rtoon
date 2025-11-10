# TOON Parser - Quick Start

## Installation

```bash
gem install rtoon
```

Or add to your Gemfile:

```ruby
gem 'rtoon'
```

## Basic Usage

```ruby
require 'rtoon'

# Your original example!
toon_string = <<~TOON
  items[1]{users,status}:
    users[2]{id,name}:
      1,Ada
      2,Bob
    status: active
TOON

result = Rtoon.parse(toon_string)

# Access the data
result["items"][0]["users"]       # => [{"id"=>"1", "name"=>"Ada"}, ...]
result["items"][0]["status"]      # => "active"
```

## TOON Syntax Basics

### 1. Schema Declaration
```toon
name[size]{field1,field2}:
```

### 2. Data Rows
```toon
value1,value2
```

### 3. Indentation (2 spaces)
```toon
parent:
  child:
    data
```

## Examples

### Simple Table
```toon
users[2]{id,name}:
  1,Ada
  2,Bob
```

Result:
```ruby
{"users" => [{"id"=>"1", "name"=>"Ada"}, {"id"=>"2", "name"=>"Bob"}]}
```

### Nested Structure
```toon
company[1]{depts,location}:
  depts[2]{name,size}:
    eng,50
    sales,20
  location: NYC
```

### Simple Fields
```toon
name: John
age: 30
active: yes
```

## Run the Demo

```bash
ruby example.rb
```

## Run Tests

```bash
ruby test/toon_test.rb
```

## Key Features

✅ Schema-based declarations
✅ Tabular data rows
✅ Indentation-based nesting
✅ Simple field assignments

See README.md for complete documentation!
