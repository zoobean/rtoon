#!/usr/bin/env ruby

require_relative 'lib/rtoon'
require 'json'

puts "=== TOON Parser Demo ==="
puts "Token Object Oriented Notation - Tabular Format"
puts

# Example 1: Simple schema with data
puts "1. Simple Schema with Data Rows"
puts "-" * 50
toon1 = <<~TOON
  users[2]{id,name}:
    1,Ada
    2,Bob
TOON

puts "TOON Input:"
puts toon1
puts "\nParsed Result:"
result1 = Rtoon.parse(toon1)
puts JSON.pretty_generate(result1)
puts

# Example 2: Nested schemas (your original example)
puts "2. Nested Schemas with Mixed Content"
puts "-" * 50
toon2 = <<~TOON
  items[1]{users,status}:
    users[2]{id,name}:
      1,Ada
      2,Bob
    status: active
TOON

puts "TOON Input:"
puts toon2
puts "\nParsed Result:"
result2 = Rtoon.parse(toon2)
puts JSON.pretty_generate(result2)
puts

# Example 3: Multiple fields
puts "3. Multiple Fields in Schema"
puts "-" * 50
toon3 = <<~TOON
  products[3]{id,name,price,stock}:
    1,Widget,99,50
    2,Gadget,149,30
    3,Gizmo,199,20
TOON

puts "TOON Input:"
puts toon3
puts "\nParsed Result:"
result3 = Rtoon.parse(toon3)
puts JSON.pretty_generate(result3)
puts

# Example 4: Simple field assignments
puts "4. Simple Field Assignments"
puts "-" * 50
toon4 = <<~TOON
  name: John
  age: 30
  active: yes
  role: admin
TOON

puts "TOON Input:"
puts toon4
puts "\nParsed Result:"
result4 = Rtoon.parse(toon4)
puts JSON.pretty_generate(result4)
puts

# Example 5: Complex real-world structure
puts "5. Complex Real-World Example"
puts "-" * 50
toon5 = <<~TOON
  database[1]{name,tables,version}:
    name: myapp
    tables[3]{name,records,indexed}:
      users,1500,yes
      posts,8000,yes
      comments,25000,no
    version: 2
TOON

puts "TOON Input:"
puts toon5
puts "\nParsed Result:"
result5 = Rtoon.parse(toon5)
puts JSON.pretty_generate(result5)
puts

# Example 6: Deep nesting
puts "6. Deeply Nested Structure"
puts "-" * 50
toon6 = <<~TOON
  company[1]{departments}:
    departments[2]{name,teams}:
      engineering,3
      sales,2
TOON


puts "TOON Input:"
puts toon6
puts "\nParsed Result:"
result6 = Rtoon.parse(toon6)
puts JSON.pretty_generate(result6)
puts

# Example 7: Round-trip encoding
puts "7. Round-Trip Encoding (Parse → Encode)"
puts "-" * 50
puts "Original data structure:"
original_data = {
  "users" => [
    {"id" => "1", "name" => "Alice", "role" => "admin"},
    {"id" => "2", "name" => "Bob", "role" => "user"},
    {"id" => "3", "name" => "Carol", "role" => "user"}
  ],
  "config" => {
    "version" => "1.0",
    "active" => "true"
  }
}
puts JSON.pretty_generate(original_data)
puts

puts "Encoded TOON:"
encoded = Rtoon.encode(original_data)
puts encoded
puts

puts "Re-parsed result:"
reparsed = Rtoon.parse(encoded)
puts JSON.pretty_generate(reparsed)
puts

puts "Match: #{original_data == reparsed ? '✓' : '✗'}"
puts

puts "See README.md for complete documentation!"

puts "=== Demo Complete ==="
puts
puts "Key Features Demonstrated:"
puts "  ✓ Schema declarations with field definitions"
puts "  ✓ Tabular data rows"
puts "  ✓ Nested structures with indentation"
puts "  ✓ Field assignments"
puts "  ✓ Array size hints"
puts "  ✓ Mixed content types"
puts "  ✓ Round-trip encoding and parsing"
puts
