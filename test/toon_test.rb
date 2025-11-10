require "minitest/autorun"
require_relative "../lib/toon"

class ToonTest < Minitest::Test
  def test_simple_schema_with_data
    input = <<~TOON
      users[2]{id,name}:
        1,Ada
        2,Bob
    TOON
    
    result = Toon.parse(input)
    
    assert_equal 2, result["users"].length
    assert_equal "1", result["users"][0]["id"]
    assert_equal "Ada", result["users"][0]["name"]
    assert_equal "2", result["users"][1]["id"]
    assert_equal "Bob", result["users"][1]["name"]
  end

  def test_nested_schemas
    input = <<~TOON
      items[1]{users,status}:
        users[2]{id,name}:
          1,Ada
          2,Bob
        status: active
    TOON
    
    result = Toon.parse(input)
    
    assert_equal 1, result["items"].length
    assert_equal 2, result["items"][0]["users"].length
    assert_equal "Ada", result["items"][0]["users"][0]["name"]
    assert_equal "active", result["items"][0]["status"]
  end

  def test_simple_field_assignment
    input = <<~TOON
      name: John
      age: 30
    TOON
    
    result = Toon.parse(input)
    
    assert_equal "John", result["name"]
    assert_equal "30", result["age"]
  end

  def test_schema_without_size
    input = <<~TOON
      config{host,port}:
        localhost,8080
    TOON
    
    result = Toon.parse(input)
    
    assert_equal 1, result["config"].length
    assert_equal "localhost", result["config"][0]["host"]
    assert_equal "8080", result["config"][0]["port"]
  end

  def test_multiple_data_rows
    input = <<~TOON
      products[3]{id,name,price}:
        1,Widget,100
        2,Gadget,200
        3,Gizmo,300
    TOON
    
    result = Toon.parse(input)
    
    assert_equal 3, result["products"].length
    assert_equal "Widget", result["products"][0]["name"]
    assert_equal "100", result["products"][0]["price"]
    assert_equal "Gizmo", result["products"][2]["name"]
  end

  def test_deeply_nested_structure
    input = <<~TOON
      org[1]{depts}:
        depts[2]{name,employees}:
          eng,5
          sales,3
    TOON
    
    result = Toon.parse(input)
    
    assert_equal 1, result["org"].length
    assert_equal 2, result["org"][0]["depts"].length
    assert_equal "eng", result["org"][0]["depts"][0]["name"]
    assert_equal "5", result["org"][0]["depts"][0]["employees"]
  end

  def test_mixed_nested_and_fields
    input = <<~TOON
      server[1]{users,config}:
        users[2]{id,name}:
          1,Alice
          2,Bob
        config: production
    TOON
    
    result = Toon.parse(input)
    
    assert_equal 1, result["server"].length
    assert_equal 2, result["server"][0]["users"].length
    assert_equal "Alice", result["server"][0]["users"][0]["name"]
    assert_equal "production", result["server"][0]["config"]
  end

  def test_single_field_schema
    input = <<~TOON
      tags[3]{name}:
        ruby
        rails
        programming
    TOON
    
    result = Toon.parse(input)
    
    assert_equal 3, result["tags"].length
    assert_equal "ruby", result["tags"][0]["name"]
    assert_equal "programming", result["tags"][2]["name"]
  end

  def test_empty_lines_ignored
    input = <<~TOON
      users[2]{id,name}:
        1,Ada

        2,Bob
    TOON
    
    result = Toon.parse(input)
    
    assert_equal 2, result["users"].length
    assert_equal "Ada", result["users"][0]["name"]
  end

  def test_numeric_values
    input = <<~TOON
      stats[2]{count,total}:
        10,100
        20,200
    TOON
    
    result = Toon.parse(input)
    
    assert_equal "10", result["stats"][0]["count"]
    assert_equal "100", result["stats"][0]["total"]
    assert_equal "200", result["stats"][1]["total"]
  end

  def test_complex_real_world_example
    input = <<~TOON
      database[1]{tables,version}:
        tables[2]{name,columns}:
          users,4
          posts,6
        version: 2
    TOON
    
    result = Toon.parse(input)
    
    assert_equal 1, result["database"].length
    assert_equal 2, result["database"][0]["tables"].length
    assert_equal "users", result["database"][0]["tables"][0]["name"]
    assert_equal "4", result["database"][0]["tables"][0]["columns"]
    assert_equal "2", result["database"][0]["version"]
  end
end
