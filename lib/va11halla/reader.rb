#
# Copyright (c) 2019-2025 Charlotte Koch. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   1. Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
#   2.  Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# =========================================================================
#
# reader.rb
#

require 'json'

module Va11halla
  Instruction = Struct.new(:name, :params) do
    def to_h
      return {
        "type" => "instruction",
        "name" => self.name,
        "params" => self.params,
      }
    end

    def to_json
      return JSON.dump(self.to_h)
    end
  end

  Dialogue = Struct.new(:text) do
    def to_h
      return {
        "type" => "dialogue",
        "text" => self.text,
      }
    end

    def to_json
      return JSON.dump(self.to_h)
    end
  end

  class LineInterpreter
    attr_reader :mode
    attr_reader :raw
    attr_reader :instructions

    def initialize(raw)
      @mode = nil
      @raw = raw
      @instructions = []
    end

    def interpret
      this_meta_name = nil
      this_meta_params = []
      this_meta_params_i = 0
      dialogue = ""

      @raw.split("").each do |char|
        case char
        when "["
          if not @mode and !dialogue.empty?
            @instructions << Dialogue.new(dialogue)
            dialogue = ""
          end
          @mode = :meta_open
          this_meta_name = ""
        when "]"
          if @mode == :meta_params
            @mode = nil
            @instructions << Instruction.new(this_meta_name, this_meta_params)
            this_meta_name = nil
            this_meta_params = []
            this_meta_params_i = 0
          end
        when ":"
          if @mode == :meta_open
            @mode = :meta_params
          else
            dialogue += char
          end
        when ","
          if @mode == :meta_params
            this_meta_params_i += 1
          else
            dialogue += char
          end
        when "#"
          dialogue += "\n"
        when "\n"
          break
        when "\r"
          # IGNORE
        else
          # Unhandled character, probably a letter or insignificant
          # punctuation mark.
          case @mode
          when :meta_open
            this_meta_name += char
          when :meta_params
            this_meta_params[this_meta_params_i] ||= ""
            this_meta_params[this_meta_params_i] += char
          else
            dialogue += char
          end
        end
      end

      return @instructions
    end
  end

  class Line
    attr_reader :raw
    attr_reader :instructions

    def initialize(raw)
      @raw = raw
      @instructions = []
    end

    def interpret
      return @instructions if @instructions.any?
      @instructions = LineInterpreter.new(@raw).interpret
      return @instructions
    end
  end

  class MagicError < RuntimeError
  end

  class ScriptReader
    attr_reader :path
    attr_accessor :file
    attr_reader :lines

    MAGIC = [239, 187, 191].freeze

    def initialize(path)
      @path = path
      @file = File.open(path, "r")
      @lines = []
    end

    def interpret
      magic = @file.read(3).unpack("C*")

      if magic != MAGIC
        raise(MagicError, "Unknown magic: #{magic.inspect} -- was expecting #{MAGIC.inspect}")
      end

      until @file.eof?
        line_str = @file.gets
        @lines << Line.new(line_str).interpret
      end

      return true
    end

    def to_json
      JSON.dump(@lines.map { |line| line.instructions })
    end

    def close
      @file.close
    end
  end
end
