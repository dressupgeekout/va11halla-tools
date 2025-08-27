#
# This program writes in a standard format the name and parameters of every
# instruction in every line of dialogue in a given script.
#
# You can use it to do all sorts of interesting analytics. For example, you
# can sort all instructions across the game in order of frequency with
# something like:
#
#   find VA-11_Hall_A/assets/scripts/eng -name \*.txt  \
#     -exec ruby scripts/all_commands.rb {} \;         \
#     | sort | uniq -c | sort -rn                      \
#     > stats.txt
#

$LOAD_PATH.unshift File.join(__dir__, "..", "lib")
require 'va11halla'

script = ARGV.shift or raise(ArgumentError, "need a path to a script")

reader = Va11halla::ScriptReader.new(File.expand_path(script))
at_exit { reader.close }
reader.interpret

reader.lines.each do |bits|
  bits.select { |bit| bit.class == Va11halla::Instruction }.each do |instruction|
    p [instruction.name, instruction.params]
  end
end
