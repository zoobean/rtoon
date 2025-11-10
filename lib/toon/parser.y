# TOON Grammar - Tabular, schema-based format

class Toon::Parser

token IDENTIFIER NUMBER
token LBRACKET RBRACKET LBRACE RBRACE COLON COMMA
token INDENT DEDENT NEWLINE

rule
  document
    : statements { result = process_statements(val[0]) }
    | /* empty */ { result = {} }
    ;

  statements
    : statement { result = [val[0]] }
    | statements statement { result = val[0] + [val[1]] }
    ;

  statement
    : schema_block { result = val[0] }
    | field_assignment { result = val[0] }
    | NEWLINE { result = nil }
    ;

  schema_block
    : schema_header NEWLINE INDENT block_content DEDENT
      { result = { type: :schema, header: val[0], content: val[3] } }
    | schema_header NEWLINE INDENT block_content
      { result = { type: :schema, header: val[0], content: val[3] } }
    ;

  schema_header
    : IDENTIFIER LBRACKET NUMBER RBRACKET LBRACE field_list RBRACE COLON
      { result = { name: val[0], size: val[2].to_i, fields: val[5] } }
    | IDENTIFIER LBRACE field_list RBRACE COLON
      { result = { name: val[0], size: nil, fields: val[2] } }
    ;

  field_list
    : IDENTIFIER { result = [val[0]] }
    | field_list COMMA IDENTIFIER { result = val[0] + [val[2]] }
    ;

  block_content
    : statements { result = val[0] }
    ;

  field_assignment
    : IDENTIFIER COLON value { result = { type: :field, name: val[0], value: val[2] } }
    | data_row { result = { type: :data_row, values: val[0] } }
    ;

  data_row
    : value_list { result = val[0] }
    ;

  value_list
    : value { result = [val[0]] }
    | value_list COMMA value { result = val[0] + [val[2]] }
    ;

  value
    : IDENTIFIER { result = val[0] }
    | NUMBER { result = val[0] }
    ;

end

---- header
require_relative 'lexer'

---- inner

def parse(str)
  @lexer = Lexer.new(str)
  do_parse
end

def next_token
  @lexer.next_token
end

def on_error(token_id, value, value_stack)
  line = @lexer.line_number
  raise ParseError, "Parse error at line #{line}: unexpected token #{value.inspect}"
end

def process_statements(statements)
  result = {}
  current_schema = nil
  data_rows = []

  statements.compact.each do |stmt|
    case stmt[:type]
    when :schema
      # First, finalize any pending schema with data rows
      if current_schema && !data_rows.empty?
        result[current_schema[:name]] = build_array_from_rows(current_schema, data_rows)
        data_rows = []
      end

      current_schema = stmt[:header]

      # Process nested content
      nested_result = process_statements(stmt[:content])

      # Check if there are data rows in the nested content
      nested_data_rows = stmt[:content].select { |s| s && s[:type] == :data_row }

      if !nested_data_rows.empty?
        # This schema has data rows
        result[current_schema[:name]] = build_array_from_rows(current_schema, nested_data_rows)
        current_schema = nil
      elsif !nested_result.empty?
        # This schema has nested schemas
        if current_schema[:size]
          result[current_schema[:name]] = [nested_result]
        else
          result[current_schema[:name]] = nested_result
        end
        current_schema = nil
      end

    when :field
      result[stmt[:name]] = stmt[:value]

    when :data_row
      data_rows << stmt[:values]
    end
  end

  # Finalize any remaining schema
  if current_schema && !data_rows.empty?
    result[current_schema[:name]] = build_array_from_rows(current_schema, data_rows)
  end

  result
end

def build_array_from_rows(schema, data_row_statements)
  fields = schema[:fields]

  data_row_statements.map do |row_stmt|
    values = row_stmt[:values]
    obj = {}
    fields.each_with_index do |field, idx|
      obj[field] = values[idx] if idx < values.length
    end
    obj
  end
end

class ParseError < StandardError; end
