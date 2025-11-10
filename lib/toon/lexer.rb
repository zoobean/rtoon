module Toon
  class Lexer
    attr_reader :line_number, :indent_stack

    def initialize(input)
      @input = input
      @lines = input.split("\n")
      @line_index = 0
      @pos = 0
      @current_line = @lines[@line_index] || ""
      @indent_stack = [0]
      @pending_dedents = 0
      @line_number = 1
    end

    def next_token
      # Handle pending dedents first
      if @pending_dedents > 0
        @pending_dedents -= 1
        @indent_stack.pop
        return [:DEDENT, nil]
      end

      # Skip empty lines
      while @current_line && @current_line.strip.empty?
        advance_line
        return [false, false] if @current_line.nil?
      end

      return [false, false] if @current_line.nil?

      # Check indentation at start of line
      if @pos == 0
        indent = @current_line[/^\s*/].length
        current_indent = @indent_stack.last

        if indent > current_indent
          @indent_stack.push(indent)
          @pos = indent
          return [:INDENT, nil]
        elsif indent < current_indent
          # Calculate how many dedents needed
          while @indent_stack.length > 1 && @indent_stack[-1] > indent
            @pending_dedents += 1
            if @indent_stack[-2] == indent
              break
            end
          end

          if @pending_dedents > 0
            @pending_dedents -= 1
            @indent_stack.pop
            @pos = indent
            return [:DEDENT, nil]
          end
        end

        @pos = indent
      end

      # Skip whitespace (but not newlines)
      while @pos < @current_line.length && @current_line[@pos] == ' '
        @pos += 1
      end

      # End of line
      if @pos >= @current_line.length
        advance_line
        return [:NEWLINE, "\n"]
      end

      char = @current_line[@pos]

      case char
      when '['
        @pos += 1
        return [:LBRACKET, '[']
      when ']'
        @pos += 1
        return [:RBRACKET, ']']
      when '{'
        @pos += 1
        return [:LBRACE, '{']
      when '}'
        @pos += 1
        return [:RBRACE, '}']
      when ':'
        @pos += 1
        return [:COLON, ':']
      when ','
        @pos += 1
        return [:COMMA, ',']
      when '0'..'9'
        return [:NUMBER, scan_number]
      when 'a'..'z', 'A'..'Z', '_'
        return [:IDENTIFIER, scan_identifier]
      else
        raise "Unexpected character: #{char.inspect} at line #{@line_number}, position #{@pos}"
      end
    end

    private

    def advance_line
      @line_index += 1
      @line_number += 1
      if @line_index < @lines.length
        @current_line = @lines[@line_index]
        @pos = 0
      else
        @current_line = nil
      end
    end

    def scan_number
      start = @pos
      @pos += 1 while @pos < @current_line.length && @current_line[@pos].match?(/[0-9]/)
      @current_line[start...@pos]
    end

    def scan_identifier
      start = @pos
      @pos += 1 while @pos < @current_line.length && @current_line[@pos].match?(/[a-zA-Z0-9_]/)
      @current_line[start...@pos]
    end
  end
end
