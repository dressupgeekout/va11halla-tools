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
# Thanks to svanheulen, who wrote the original Gist that got me a head
# start:
#
#     https://gist.github.com/svanheulen/15d7b56ba64fd7d826ac23ad879b4e92
#
# I also learned a few things from the Undertale modding folks:
#
#     https://github.com/krzys-h/UndertaleModTool
#

module Va11halla

  # This is *not* a general purpose IFF reader. It is optimized specifically
  # for VA-11 Hall-A's use case (and perhaps other games made with Game Maker
  # Studio, too).
  class IFF
    MAGIC_NUMBER = "FORM"

    # Intentionally does not include the FORM chunk.
    VALID_CHUNKS= %w[
      AGRP AUDO BGND CODE DAFL EXTN FONT FUNC GEN8 OBJT OPTN PATH ROOM SCPT
      SHDR SOND SPRT STRG TMLN TPAG TXTR VARI
    ]

    # Options requested by the caller governing how to read the IFF file.
    attr_accessor :specific_chunk
    attr_accessor :extract
    attr_accessor :debug

    # Data that is discovered while parsing the file.
    attr_reader :total_length
    attr_reader :section_lengths
    attr_reader :sond_filenames
    attr_reader :font_infos
    attr_reader :sond_infos
    attr_reader :sond_count
    attr_reader :agrp_count
    attr_reader :sprt_count
    attr_reader :scpt_count
    attr_reader :font_count
    attr_reader :code_count
    attr_reader :vari_count
    attr_reader :func_count
    attr_reader :strg_count
    attr_reader :txtr_count
    attr_reader :audo_count

    # "Private" vars.
    attr_reader :filename
    attr_reader :fp

    def initialize(filename)
      @filename = filename

      @specific_chunk = nil
      @extract = true
      @debug = false
    end

    # Actually obtains a handle on the file. Don't forget to close it with
    # `#close` when you're done.
    def open
      @fp = File.open(@filename, 'rb')
    end

    def close
      @fp.close
    end

    # Available options:
    # - `:specific_chunk`
    # - `:extract`
    # - `:debug`
    def parse(**kwargs)
      @specific_chunk = kwargs[:specific_chunk]
      @extract = kwargs[:extract]
      @debug = kwargs[:debug]

      verify_magic

      @total_length = read_uint

      @sond_filenames = []
      @section_lengths = {}

      while @fp.tell < @total_length
        chunk_name = read_chars(4)
        section_length = read_uint
        @section_lengths[chunk_name] = section_length

        section_end = @fp.tell() + section_length

        case chunk_name
        when "GEN8"
          nil
        when "OPTN"
          nil
        when "EXTN"
          nil
        when "BGND"
          nil
        when "PATH"
          nil
        when "SHDR"
          nil
        when "TMLN"
          nil
        when "OBJT"
          nil
        when "ROOM"
          nil
        when "DAFL"
          nil
        when "TPAG"
          nil
        when "SOND"
          sond if ((@specific_chunk && @specific_chunk == "SOND") || !@specific_chunk)
        when "AGRP"
          agrp if ((@specific_chunk && @specific_chunk == "AGRP") || !@specific_chunk)
        when "SPRT"
          sprt(section_end) if ((@specific_chunk && @specific_chunk == "SPRT") || !@specific_chunk)
        when "SCPT"
          scpt if ((@specific_chunk && @specific_chunk == "SCPT") || !@specific_chunk)
        when "FONT"
          font if ((@specific_chunk && @specific_chunk == "FONT") || !@specific_chunk)
        when "CODE"
          code if ((@specific_chunk && @specific_chunk == "CODE") || !@specific_chunk)
        when "VARI"
          vari if ((@specific_chunk && @specific_chunk == "VARI") || !@specific_chunk)
        when "FUNC"
          func if ((@specific_chunk && @specific_chunk == "FUNC") || !@specific_chunk)
        when "STRG"
          strg if ((@specific_chunk && @specific_chunk == "STRG") || !@specific_chunk)
        when "TXTR"
          txtr(section_end) if ((@specific_chunk && @specific_chunk == "TXTR") || !@specific_chunk)
        when "AUDO"
          audo if ((@specific_chunk && @specific_chunk == "AUDO") || !@specific_chunk)
        else
          raise(RuntimeError, "unknown chunk: #{chunk_name.inspect}")
        end

        @fp.seek(section_end)
      end
    end

    # The SOND chunk contains information about the audio data, but the audio
    # itself is located in the AUDO chunk. Hence, there are an equal number
    # SONDs as there are AUDOs.
    def sond
      @sond_count = read_uint
      @sond_infos = Array.new(@sond_count)
      real_offsets = []

      (0...@sond_count).each do |i|
        real_offset = read_uint
        real_offsets[i] = real_offset
      end

      p real_offsets if @debug

      sondinfo_klass = Struct.new(:x, :a, :extname, :index, :name, :filename) do
        def to_s
          return ("SOND %d\t%d\t%s\t%d\t%s\t%s" % [x, a, extname, index, name, filename])
        end
      end

      real_offsets.each_with_index do |offset, i|
        si = sondinfo_klass.new

        @fp.seek(offset)
        name_loc = read_uint
        si.x = read_uint # not sure what this is
        extname_loc = read_uint
        filename_loc = read_uint
        read_uint # zero?
        si.a = read_uint
        2.times { read_uint } # zeroes?
        si.index = read_uint

        @fp.seek(name_loc-4)
        namelen = read_uint
        si.name = read_chars(namelen)

        @fp.seek(extname_loc-4)
        extname_len = read_uint
        si.extname = read_chars(extname_len)

        @fp.seek(filename_loc-4)
        filename_len = read_uint
        si.filename = read_chars(filename_len)

        @sond_infos[i] = si

        if @extract
          @sond_filenames[i] = filename
        end
      end
    end

    def agrp
      @agrp_count = read_uint
      real_offsets = []

      (0...@agrp_count).each do |i|
        real_offset = read_uint
        real_offsets[i] = real_offset
      end

      real_offsets.each do |offset|
        @fp.seek(offset)
        name_loc = read_uint
        @fp.seek(name_loc-4)
        name_len = read_uint
        name = read_chars(name_len)
        puts("\tAGRP #{name}")
      end
    end

    # The SPRT chunk.
    def sprt(section_end)
      @sprt_count = read_uint
      real_offsets = []

      (0...@sprt_count).each do |i|
        real_offset = read_uint
        real_offsets[i] = real_offset
      end

      p real_offsets if @debug

      real_offsets.each_with_index do |offset, i|
        @fp.seek(offset)
        name_loc = read_uint
        w = read_uint
        h = read_uint
        x = read_uint # always 7?
        a = read_uint
        b = read_uint

        8.times { read_uint } # 8 zeroes

        nframes = read_uint
        frames = []

        nframes.times do |j|
          frame = read_uint
          frames[j] = frame
        end

        @fp.seek(name_loc-4)
        namelen = read_uint
        name = read_chars(namelen)

        puts("SPRT %d\t%d\t%s -> %dx%d -> %dx%d\t%d - %s" % [i, x, name, w, h, a, b, nframes, frames.inspect])

        (0...nframes).each do |j|
          @fp.seek(frames[j]-2)
          n_sheet = read_ushort
          ary = []
          (0...10).each do |i|
            n = read_ushort
            ary[i] = n
          end
          puts("\\ frame %d @ sheet #%d\t%s" % [j, n_sheet, ary.inspect])
        end

        puts("")
      end
    end

    def scpt
      @scpt_count = read_uint
    end

    # The FONT chunk contains information about fonts.
    def font
      @font_count = read_uint
      @font_infos = Array.new(@font_count)
      real_offsets = []

      (0...@font_count).each do |i|
        real_offset = read_uint
        real_offsets[i] = real_offset
      end

      p real_offsets if @debug

      fontinfo_klass = Struct.new(:i, :varname, :name, :ptsize, :b, :c, :d, :e) do
        def to_s
          return ("FONT %d\t%s\t%s\t%d\t%d\t%d\t%d\t%d" % [i, varname, name, ptsize, b, c, d, e])
        end
      end

      real_offsets.each_with_index do |offset, i|
        fi = fontinfo_klass.new
        fi.i = i

        @fp.seek(offset)
        varname_loc = read_uint
        name_loc = read_uint
        fi.ptsize = read_uint
        read_uint # blank 3?
        read_uint # blank 2?
        fi.b = read_ushort
        fi.c = read_ushort
        fi.d = read_ushort
        fi.e = read_ushort

        @fp.seek(varname_loc-4)
        varname_len = read_uint
        fi.varname = read_chars(varname_len)

        @fp.seek(name_loc-4)
        name_len = read_uint
        fi.name = read_chars(name_len)

        @font_infos[i] = fi
      end
    end

    def code
      @code_count = read_uint
    end

    def vari
      @vari_count = read_uint
    end

    def func
      @func_count = read_uint
    end

    def strg
      @strg_count = read_uint
      real_offsets = []

      # XXX We're making an enormous array like this
      (0...@strg_count).each do |i|
        real_offset = read_uint
        real_offsets[i] = real_offset
      end

      if @extract
        real_offsets.each do |real_offset|
          @fp.seek(real_offset)
          strlen = read_uint
          the_str = read_chars(strlen)
          @fp.read(1) # terminating NUL
          puts(">> " + the_str.inspect)
        end
      end
    end

    # The TXTR chunk contains actual raster graphic data. In practice, these
    # are spritesheets in PNG format.
    def txtr(section_end)
      @txtr_count = read_uint
      pre_offsets = @fp.read(4*@txtr_count).unpack("L*")
      p pre_offsets if @debug
      @fp.read(4) # zeroes?

      real_offsets = pre_offsets.map do |pre_offset|
        @fp.seek(pre_offset)
        _, real_offset = @fp.read(8).unpack('L*')
        real_offset
      end

      p real_offsets if @debug

      # XXX but where are the TXTR lengths, really?
      # According to this, there might not even *be* lengths included:
      # --> https://github.com/krzys-h/UndertaleModTool/wiki/Corrections-to-Game-Maker:-Studio-1.4-data.win-format-and-VM-bytecode,-.yydebug-format-and-debugger-instructions
      if @extract
        (0...(real_offsets.length-1)).each do |i|
          @fp.seek(real_offsets[i])
          size = real_offsets[i+1] - @fp.tell()
          fname = sprintf("TXTR_%03d.png", i)
          puts("writing #{fname}")
          File.open(fname, 'wb') { |txtr| txtr.write(@fp.read(size)) }
        end

        # I guess we have to treat the last txtr specially:
        @fp.seek(real_offsets[real_offsets.length-1])
        size = section_end - @fp.tell()
        File.open(sprintf('TXTR_%03d.png', real_offsets.length-1), 'wb') { |txtr| txtr.write(@fp.read(size)) }
      end
    end

    # The AUDO chunk contains the actual audio data. Information about this
    # audio is informed by metadata stored in the SOND chunk. Hence, there are
    # an equal number of AUDOs as there are SONDs.
    def audo
      @audo_count = read_uint
      offsets = @fp.read(@audo_count*4).unpack("L*")
      p offsets if @debug

      if @extract
        offsets.each_with_index do |offset, i|
          @fp.seek(offset)
          size = read_uint
          puts("writing " + @sond_filenames[i])
          File.open(@sond_filenames[i], 'wb') { |audo| audo.write(@fp.read(size)) }
        end
      end
    end

    # Returns a hash.
    def chunk_counts
      return {
        "AGRP" => @agrp_count,
        "AUDO" => @audo_count,
        "CODE" => @code_count,
        "FONT" => @font_count,
        "FUNC" => @func_count,
        "SCPT" => @scpt_count,
        "SOND" => @sond_count,
        "SPRT" => @sprt_count,
        "STRG" => @strg_count,
        "TXTR" => @txtr_count,
        "VARI" => @vari_count,
      }
    end

    ########## ########## ##########

    private

    # The stream must already be rewound to the beginning. Raises RuntimeError
    # if the first chunk is not 'FORM'.
    def verify_magic
      magic = read_chars(4)
      if magic != MAGIC_NUMBER
        raise(RuntimeError, "Missing initial #{MAGIC_NUMBER} chunk (got #{magic.inspect})")
      end
    end

    def read_ushort
      return @fp.read(2).unpack('S<')[0]
    end

    alias read_ushortle read_ushort

    def read_uint
      return @fp.read(4).unpack('L<')[0]
    end

    alias read_uint32 read_uint
    alias read_uint32le read_uint

    def read_chars(length)
      return @fp.read(length)
    end
  end
end
