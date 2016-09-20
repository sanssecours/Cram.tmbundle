# rubocop: disable AsciiComments

# Fix environment variable for command “Run DocTest”
ENV['TM_BUNDLE_SUPPORT'] = File.expand_path(
  File.dirname(File.dirname(__FILE__))
)

# -- Imports -------------------------------------------------------------------

require ENV['TM_SUPPORT_PATH'] + '/lib/escape'

# -- Classes -------------------------------------------------------------------

# We extend the string class with methods to escape TextMate snippets.
class String
  # This method escapes this string for usage inside a TextMate snippet.
  #
  # = Output
  #
  # The method returns an escaped version of this string.
  #
  # = Examples
  #
  # doctest: Escape a simple text for usage inside a TextMate snippet
  #
  #  >> '$ 🐰'.e_sn
  #  => '\$ 🐰'
  def e_sn
    Kernel.send(:e_sn, self)
  end

  # This method escapes this string for usage inside a snippet placeholder.
  #
  # = Output
  #
  # The method returns an escaped version of this string.
  #
  # = Examples
  #
  # doctest: Escape a simple text for usages inside a snippet placeholder
  #
  #  >> '${1:🐼}'.e_snp
  #  => '\${1:🐼\}'
  def e_snp
    Kernel.send(:e_snp, self)
  end
end

# This extended array class adds support for calling a proc on joined elements.
class Array
  # This method joins array elements and then executes the given proc.
  #
  # = Arguments
  #
  # [proc] The argument specifies the proc this function calls on the joined
  #        elements of the array.
  #
  # = Output
  #
  # This function returns a string containing a modified version of the elements
  # of the array.
  #
  # = Examples
  #
  # doctest: Join some array elements and add braces around the result
  #
  #  >> [1, 2, 3].join_proc(proc { |joined| "{#{joined}}" } )
  #  => "{123}"
  def join_proc(proc)
    identity = proc { |something| something }
    proc ||= identity
    proc.call(join)
  end
end

# This class represents a TextMate
# {selection}[http://manual.textmate.org/references.html#selection-string].
class Selection
  # This attribute stores the text belonging to this selection.
  attr_accessor :text

  # This function creates a new selection.
  #
  # = Arguments
  #
  # [selection] This value stores a string conforming to TextMate’s selection
  #             format.
  #
  # [text] This argument stores the text belonging to the selection.
  #
  # = Output
  #
  # This function returns a new object of type Selection.
  #
  # = Examples
  #
  # doctest: Create a new selection
  #
  #  >> selection = Selection.new('1:1-14', 'Selected Text\nNon Selected Text')
  def initialize(selection = nil, text = '')
    @selection_string = selection || ENV['TM_SELECTION']
    @lines = init_lines
    @text = text
  end

  # The method line_ranges returns a list of ranges representing selected lines.
  #
  # The method takes selected newlines into account. If you select a whole line
  # inside TextMate, then this function will only report the current line as
  # selected. This is contrary to TextMate’s default behaviour: TextMate
  # counts the newline character at the end of a sentence as the first character
  # of the next line.
  #
  # = Arguments
  #
  # [zero_based] This boolean specifies if the returned ranges should start with
  #              0 (zero_based = true) or 1 (default).
  #
  # = Output
  #
  # This function returns a list of sorted and merged integer ranges.
  #
  # = Examples
  #
  # doctest: Determine the selected lines of a single continuous selection
  #
  #  >> Selection.new('10-20').line_ranges
  #  => [10..19]
  #
  # doctest: Determine the selected lines of a partial selection
  #
  #  >> Selection.new('17-17:44').line_ranges
  #  => [17..17]
  #
  # doctest: Determine the selected lines for a complex selection
  #
  #  >> Selection.new('20&12:20&10:2-13&1-10&14-20:3').line_ranges
  #  => [1..12, 14..20]
  #
  # doctest: Determine the selected lines using zero as minimal value
  #
  #  >> Selection.new('41:10-31:22&1-2').line_ranges(true)
  #  => [0..0, 30..40]
  def line_ranges(zero_based = false)
    lines = @lines.dup
    lines.map! { |range| (range.begin - 1..range.end - 1) } if zero_based
    lines
  end

  # This function returns the selected lines belonging to this selection
  #
  # = Output
  #
  # This function returns a list of string containing the selected text.
  #
  # = Examples
  #
  # doctest: Output all lines belonging to a selection
  #
  #  >> text = "One\nTwo\nThree\nFour\nFive"
  #  >> Selection.new('1-3:12&5:2', text).lines
  #  => ["One\n", "Two\n", "Three\n", "Five"]
  def lines
    line_ranges(true).map { |selection| @text.lines[selection] }.flatten
  end

  # This method executes a given block on the selected lines of this selection.
  #
  # The first argument of the block contains the lines (array of string) of a
  # continuous selection. The second argument contains the selection number,
  # which starts at 0 and is increased for each continuous selection.
  #
  # = Arguments
  #
  # [proc_non_selected] This optional argument specifies a proc that this
  #                     function calls on the non selected parts of the
  #                     selection text. The proc has one argument which contains
  #                     a string that stores a continuous part of non-selected
  #                     text.
  #
  # doctest: Add some emoji around a single line selection
  #
  #  >> selection = Selection.new('1:2', "First Line\nSecond Line")
  #  >> selection.map_selected_lines_with_index do |lines , selection_number|
  #       "💖#{selection_number}:#{lines.join}✨"
  #       end
  #  => "💖0:First Line\n✨Second Line"
  #
  # doctest: Add selection numbers to multiple selections
  #
  #  >> text = "  Line 1\n  Line 2\nLine 3\n  $ Line 4\nLine 5"
  #  >> selection = Selection.new('1:2-2:3&5:5', text)
  #  >> proc_snippet = proc { |text| text.e_sn }
  #  >> selection.map_selected_lines_with_index(proc_snippet) do |lines, index|
  #       lines.map { |line| "#{index}: #{line.lstrip}" }
  #       end
  #  => "0: Line 1\n0: Line 2\nLine 3\n  \\$ Line 4\n1: Line 5"
  def map_selected_lines_with_index(proc_non_selected = nil)
    lines = @text.lines
    line_number = 0

    (line_ranges(true).map.each_with_index do |selection, selection_number|
      text = [lines[line_number...selection.begin].join_proc(proc_non_selected),
              yield(lines[selection], selection_number)]
      line_number = selection.end + 1
      text
    end << lines[line_number..-1].join_proc(proc_non_selected)).join
  end

  # This method tries to make all parts of a selection active.
  #
  # For this purpose the method outputs a snippet. Currently this only works
  # correctly for a single continuous selection. This problem here is, that
  # TextMate snippets currently have no support for selecting multiple parts of
  # a document at the same time.
  #
  # = Output
  #
  # This function returns a string containing a TextMate snippet.
  #
  # doctest: Activate a single selection
  #
  #  >> Selection.new('1:2', "First Line\nSecond Line").select
  #  => "${0:First Line\n}Second Line"
  #
  # doctest: Activate two nonconsecutive selections one after the other
  #
  #  >> text = "First Line\n{Between The Lines}\nThird Line"
  #  >> Selection.new('1&3:2', text).select
  #  => "${0:First Line\n}{Between The Lines}\n${1:Third Line}"
  def select
    non_selection_proc = proc { |text| text.e_sn }
    map_selected_lines_with_index(non_selection_proc) do |lines, index|
      "${#{index}:#{lines.join.e_snp}}"
    end
  end

  private

  def init_lines
    ranges = @selection_string.split('&').map do |selection|
      selection = selection.split(/[-x]/)
      range = selection.map(&:to_i)
      range = remove_line_ending_from_selection(range,
                                                selection) if range.length == 2
      range.sort!
      (range[0]..range[-1])
    end
    self.class.merge_overlapping_ranges(ranges)
  end

  def remove_line_ending_from_selection(range, selection)
    index_larger = range[1] > range[0] ? 1 : 0
    if range[0] != range[1] && selection[index_larger] =~ /^\d+$/
      range[index_larger] -= 1
    end
    range
  end

  class << self
    # ======================================================
    # = Source: http://stackoverflow.com/questions/6017523 =
    # ======================================================

    def merge_ranges(range1, range2)
      [range1.begin, range2.begin].min..[range1.end, range2.end].max
    end

    def ranges_overlap?(range1, range2)
      range1.include?(range2.begin - 1) || range2.include?(range1.begin - 1)
    end

    def merge_overlapping_ranges(ranges)
      ranges.sort_by(&:begin).inject([]) do |merged, range|
        if !merged.empty? && ranges_overlap?(merged.last, range)
          merged[0...-1] + [merge_ranges(merged.last, range)]
        else
          merged + [range]
        end
      end
    end
  end
end

# -- Module --------------------------------------------------------------------

# This module provides support for commenting and uncommenting Cram tests.
module Cram
  class << self
    # This method toggles Cram comments in a given selection.
    #
    # The function comments or uncomments all lines of the given selections. If
    # any of the lines in the selection contain a command, then the function
    # comments all lines in the selection. Otherwise the method uncomments all
    # lines in the selection.
    #
    # = Arguments
    #
    # [selection] This selection specifies the Cram code this function should
    #             comment or uncomment.
    #
    # = Output
    #
    # This method returns a modified version of text stored in the given
    # selection.
    #
    # doctest: Comment a single line
    #
    #  >> selection = Selection.new('2', "A Comment\n  $ echo 'A command'")
    #  >> Cram.toggle_comments(selection)
    #  => "A Comment\n$ echo 'A command'"
    #
    # doctest: Comment two nonconsecutive lines
    #
    #  >> text = ['  $ if [ $TM_FILENAME ]; then',
    #             '  >   basename "$TM_FILENAME"',
    #             '  fi'].join("\n")
    #  >> Cram.toggle_comments(Selection.new('1-2&3:2', text))
    #  => "$ if [ $TM_FILENAME ]; then\n  >   basename \"$TM_FILENAME\"\nfi"
    #
    # doctest: Comment two consecutive lines
    #
    #  >> Cram.toggle_comments(Selection.new('2:2&3:3', "  \nComment\n  $ pwd"))
    #  => "  \nComment\n$ pwd"
    #
    # doctest: Comment an already commented line and a command
    #
    #  >> text = "Comment 1\nComment 2\n  $ pwd"
    #  >> Cram.toggle_comments(Selection.new('2:2&3:3', text))
    #  => "Comment 1\nComment 2\n$ pwd"
    def toggle_comments(selection)
      commenter = determine_commenter(selection)
      selection.map_selected_lines_with_index do |lines, _|
        lines.map(&commenter).join
      end
    end

    # This function comments or uncomments parts of a Cram document.
    #
    # = Arguments
    #
    # [selection_string] This string specifies the current selection according
    #                    to TextMate’s selection syntax.
    #
    # [text] This string stores the text belonging to the selection specified
    #        via the variable selection_string.
    #
    # doctest: Comment and select two lines
    #
    #  >> text = "$Comment 1\nComment 2\n  $ pwd"
    #  >> Cram.toggle_comments_snippet('2:2&3:3', text)
    #  => "\\$Comment 1\n${0:Comment 2\n\\$ pwd}"
    def toggle_comments_snippet(selection_string = nil, text = STDIN.read)
      selection = Selection.new(selection_string, text)
      selection.text = toggle_comments(selection)
      selection.select
    end

    private

    def determine_commenter(selection)
      if selection.lines.any? { |line| line.start_with? '  ' }
        return proc { |line| line.sub!(/^\ */, '') }
      end
      proc { |line| line.insert(0, '  ') }
    end
  end
end
