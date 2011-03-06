#!/usr/bin/env ruby -w
# encoding: utf-8


class Grammar

  require 'set'
  include Enumerable

  @@default_delim = '-->'
  @@epsilon = ''


  # 
  # Construct a new Grammar from the supplied rules.
  #
  # Rules may be an Array of Arrays (corresponding to heads and daughters of
  # rules), an Array of DCG-like strings, or a hash mapping head symbols to
  # possible daughter productions.
  #
  def initialize(rules, start_symbol=nil)
  
    # Allow a previously-generated hash to be dropped into place
    #FIXME validate the hash?
    @rules = rules if rules.kind_of? Hash
    @rules ||= Hash.new

    # Allow a single rule expressed as a string
    
    if rules.kind_of? String
      if rules.include? "\n"
        rules = rules.parse_rules
      else
        rules = [rules.parse_rule]
      end
    end
    rules = [rules] if rules.kind_of? String
    rules.each { |r| push(r) }

    # If no start symbol is given, assume the left-most head symbol of the first
    # rule supplied to be start symbol
    @start_symbol = start_symbol
    @start_symbol ||= first(1).head[0]

  end

  #
  # Return the start symbol of this Grammar.
  #
  def start_symbol
    @start_symbol
  end

  def start_symbol=(new_start_symbol)
    if non_terminal_alphabet.include? new_start_symbol
      @start_symbol = new_start_symbol
    else
      raise ArgumentError "The start symbol must be an element of the alphabet"
    end
  end

  #
  # Return the set of terminal symbols in this Grammar's alphabet.
  #
  def terminal_alphabet
    Set.new(alphabet.partition { |s| s.terminal? }.shift)
  end

  #
  # Return the set of non-terminal symbols in this Grammar's alphabet.
  #
  def non_terminal_alphabet
    Set.new(alphabet.partition { |s| s.non_terminal? }.shift)
  end

  #
  # Return this Grammar's alphabet.
  #
  def alphabet
    Set.new(to_a.flatten!.uniq!)
  end

  # 
  # Add a rule to this Grammar.
  #
  # If a DCG-style rule string is supplied, it is tokenized into heads and
  # daughters.
  #
  def push(rule, dest=@rules)
    rule = rule.parse_rule if rule.kind_of? String
    if @rules.has_key? rule.head
      @rules[rule.head].push(rule.daughters)
    else
      @rules[rule.head] = [rule.daughters]
    end
  end

  #
  # Remove and return a rule from this Grammar.
  #
  # If a non-negative integer n is supplied as an argument, the rule with that
  # index will be removed from the grammar, if possible. Otherwise, the last
  # rule to be added to the Grammar will be removed.
  #
  def pop(rule_index=nil)
    rule_index = count - 1 if rule_index.nil?
    raise ValueError if rule_index >= count

    rule = at(rule_index)

    unless rule.nil?
      if @rules[rule.head].count == 1
        @rules.delete(rule.head)
      else
        if @rules[rule.head].include? rule.daughters
        @rules[rule.head].delete(rule.daughters)
        end
      end
    end

    rule
  end


  #
  # Return whether or not this Grammar is context-free.
  #
  # A Grammar is context-free if and only if all of its rules are of the form 
  #
  # A --> w
  #
  # Where A is a single non-terminal, and w is an arbitrary sequence of
  # possibly-empty terminals or non-terminals.
  #
  def context_free?
    all? { |r| r.context_free? }
  end

  #
  # Return whether or not this Grammar is right-regular.
  #
  # A Grammar is right-regular if and only if all of its rules are of one of the
  # following forms:
  # 
  # A --> b, C
  # A --> b
  # A --> []
  #
  # Where A and C are non-terminals, b is a terminal, and [] is the empty string
  #
  def right_regular?
    all? { |r| r.right_regular? }
  end

  #
  # Return whether or not this Grammar is right-regular.
  #
  # A Grammar is right-regular if and only if all of its rules are of one of the
  # following forms:
  #
  # A --> B, c
  # A --> c
  # A --> []
  #
  # Where A and B are non-terminals, c is a terminal, and [] is the empty
  # string.
  #
  def left_regular?
    all? { |r| r.left_regular? }
  end 

  # Return whether or not this Grammar is strictly regular.
  #
  # A Grammar is strictly regular if and only if it is left-regular or
  # right-regular, but not both.
  def strictly_regular?
    left_regular? || right_regular?
  end

  #FIXME
  # Return whether or not this Grammar is in Chomsky-normal form (CNF).
  #
  # A Grammar is in CNF if and only if all of its rules are of one of the
  # following forms:
  #
  # (1) A --> B, C
  # (2) A --> a
  # (3) S --> []
  #
  # where A, B and C are non-terminals, a is a terminal, and [] is the empty
  # string.
  #
  def chomsky_normal_form?
    all? { |r| r.chomsky_normal_form? } 
  end

  # 
  # Return whether or not this Grammar is in Greibach-normal form (GNF).
  # 
  # A Grammar is in GNF if and only if all its rules are of one of the following
  # forms:
  #
  # (1) S --> a, B
  # (2) S --> []
  #
  # where S and B are non-terminals, a is a terminal, and [] is the empty
  # string.
  #
  def greibach_normal_form?
    all? { |r| r.greibach_normal_form? }
  end

  # 
  # Return a Grammar in Chomsky-normal form which is equivalent to this Grammar.
  #
  def chomsky_normal_form
    raise NotImplementedError   
  end

  # 
  # Return a Grammar in Greibach-normal form which is equivalent to this Grammar.
  #
  def greibach_normal_form
    raise NotImplementedError
  end

  # 
  # Return whether or not this Grammar is left-recursive.
  # 
  # A Grammar is left-recursive if it contains any production of the form
  #
  # A --> A, n
  #
  # where A is a non-empty sequence of symbols containing at least one
  # non-terminal, and n is an arbitrary sequence of possibly empty
  # terminals or not terminals
  #
  def left_recursive?
    any { |r| r.left_recursive? } 
  end


  # 
  # Return a new Grammar containing the rules of this Grammar and other
  #
  def +(other)
    self if other.length == 0
    union = Grammar.new(to_hash)
    other.each do |r|
      union.push(r)
    end

    union
  end

  # 
  # Return a new Grammar containing the rules of this Grammar, minus those
  # contained by other
  #
  def -(other)
    self if other.length == 0
    intersection = Grammar.new(to_hash)
    intersection.delete_if { |r| other.include? r }

    intersection
  end

  # FIXME Should == correspond to 'has the same productions in the same order'
  # or 'Generates the same language'? If so, how?
  def ==(other)
    to_hash == other.to_hash
  end

  # 
  # Return the nth rule defined by this Grammar
  #
  def at(n)
      return nil if n >= count
      first(n+1).pop
  end


  # 
  # Return whether or not this Grammar contains production
  #
  def include?(production)
    production = production.parse_rule if production.kind_of? String

    any? { |p| p == production }
  end

  #
  # Return whether or not this Grammar excludes production
  #
  def exclude?(production)
    !include?(production)
  end

  #
  # Iterate over the rules of this Grammar
  #
  def each
    @rules.each { |h,ds| ds.each { |d| yield [h, d] } }
  end


  def to_s(delim=@@default_delim,bnf=false)
    #TODO BNF form
#    if bnf and context_free?
#      delim = '::=' if delim != @@default_delim 
#      @rules.map { |head, daughters| "#{ head.join(' ') } #{ delim } #{ daughters.map { |daughter| daughter.join(' ') }.join(' | ') }" }
#    end
    raise NotImplementedError if bnf

    map { |r|"#{ r.head.join(', ') } #{ delim } #{ r.daughters.join(', ') }" }.join("\n")
  end


  # 
  # Return a Hash mapping Head symbols to an array of their possible
  # productions in this Grammar
  #
  # Order of introduction is preserved.
  #
  def to_hash
    the_hash = Hash.new
    the_hash.replace(@rules)
    the_hash
  end


  def to_a
    the_array = Array.new
    each { |r| the_array.push(r) }
    the_array
  end

  alias_method :cnf, :chomsky_normal_form
  alias_method :cnf?, :chomsky_normal_form?
  alias_method :gnf, :greibach_normal_form
  alias_method :gnf?, :greibach_normal_form?
  alias_method :length, :count
  alias_method :[], :at
  alias_method :add_rule, :push
  alias_method :remove_rule, :pop

end


# FIXME Should there be a Production/Rule/whatever class?
# Will the duck be punched?
class Array
  def head
    at(0)
  end
  def daughters
    at(1)
  end

  def context_free?
    head.length == 1 && head[0].non_terminal?
  end

  def right_regular?
    context_free? &&
    daughters.length == 2 &&
    daughters[0].terminal? &&
    (daughters[1].non_terminal? || daughters[1].nil?)
  end

  def left_regular?
    context_free? &&
    daughters.length == 2 &&
    daughters[1].terminal? &&
    (daughters[0].non_terminal? || daughters[1].nil?)
  end


  def left_recursive? 
    return head == daughters.first(head.count)
  end

  def epsilon_production?
    context_free? && daughters.count == 1 && daughters[0].empty_string?
  end

  def chomsky_normal_form?
    context_free? && (
      (daughters.count == 2 && daughters.all { |s| s.non_terminal? }) ||
      (daughters.count == 1 && daughters[0].terminal?)
    )
  end

  def cyclic?
    head == daughters
  end

  def greibach_normal_form?
     context_free? && (
      (daughters.count == 2 && daughters[0].terminal? && daughters[1].non_terminal?) ||
      (daughters.count == 1 && daughters[0].empty_string?)
    ) 
  end

end

# FIXME Should there be a 'ProductionString' class?
# If so, will the duck be punched?
class String
  def terminal?
    start_with? '[' and end_with? ']'
  end

  def non_terminal?
    not terminal?
  end

  def empty_string?
    self == '[]'
  end

  def valid_production?
    not (self =~ /^((\[\w+\]|\w+),)*(\[\w+\]|\w+)-->((\[\w+\]|\w+),)*(\[\w+\]|\w+)$/).nil?
  end


  def parse_rule(delim='-->')
    rule = gsub(/ /, '')
    #raise ArgumentError unless valid_production?
    head, daughters = rule.split(delim)

    [head.split(','), daughters.split(',')]
  end

  def parse_rules(delim='-->', line_end="\n")
    d, le = delim, line_end
    rules = split(le)

    rules.map { |r| r.parse_rule(d) } 
  end
end


if __FILE__ == $0
  # Run the tests
  eval DATA.read, nil, $0, __LINE__ + 4
end

__END__

require 'test/unit'

class TestGrammar < Test::Unit::TestCase
  require 'set'
  
  def test_initialize
   grammar = Grammar.new([[['S'],['NP', 'VP']]]) 
   assert_equal(grammar[0], [['S'],['NP', 'VP']]) 
   assert_equal(grammar.length, 1)

   string_constructed = Grammar.new('S --> NP, VP')
   assert_equal(grammar, string_constructed)
  end

  def test_push
    grammar = Grammar.new('N --> N, VP')
    assert_equal(grammar.length, 1)
    grammar.push('N --> [ruby]')
    assert_equal(grammar.length, 2)
  end


  def test_context_free?
    grammar = Grammar.new([
      # All context free, by definition
      'X --> [y]',
      'Y --> p, [q], [z]',
      'G --> y, [z]'
    ])
    assert grammar.context_free?

    # Not context free, by definition
    grammar.push('X, p, y --> [a], [b], [c]')
    assert (!grammar.context_free?)

    # Not context free, by definition
    grammar = Grammar.new('[s] --> d, s')
    assert (!grammar.context_free?)

  end


  def test_right_regular?
    grammar = Grammar.new('B --> [a]')
    assert grammar.right_regular?

    grammar = Grammar.new('B --> [a], C')
    assert grammar.right_regular?

    grammar = Grammar.new('B --> []')
    assert grammar.right_regular?

    grammar = Grammar.new([
      'B --> [a]',
      'B --> [a], C',
      'B --> []',
    ])
    assert grammar.right_regular?

    # Not right-regular, by definition
    grammar.push('B --> A, [b]')
    assert(!grammar.right_regular?)
    
    # Not right-regular, by definition
    grammar = Grammar.new('B --> A, [b]')
    assert(!grammar.right_regular?)
  end


  def test_left_regular?
    grammar = Grammar.new('B --> [a]')
    assert grammar.left_regular?

    grammar = Grammar.new('B --> C, [a]')
    assert grammar.left_regular?

    grammar = Grammar.new('B --> []')
    assert grammar.left_regular?

    grammar = Grammar.new([
      'B --> [a]',
      'B --> C, [a]',
      'B --> []',
    ])
    assert grammar.left_regular?

    # Not left-regular, by definition
    grammar.push('B --> [b], A')
    assert(!grammar.left_regular?)
    
    # Not left-regular, by definition
    grammar = Grammar.new('B --> [b], A')
    assert(!grammar.left_regular?)
  end
 

  def test_chomsky_normal_form

  end


  def test_greibach_normal_form

  end


  def test_chomsky_normal_form?

  end


  def test_greibach_normal_form?

  end


  def test_plus

  end


  def test_minus

  end


  def test_at
    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])

    assert_equal([['S'],['NP', 'VP']], grammar.at(0))
    assert_equal([['NP'], ['N']], grammar.at(1))
    assert_equal([['PP'], ['P', 'NP']], grammar.at(2))
    assert_equal([['VP'], ['V', 'NP']], grammar.at(3))
    assert_equal([['P'], ['[to]']], grammar.at(4))
    assert_equal([['P'], ['[from]']], grammar.at(5))
    assert_equal([['V'], ['[work]']], grammar.at(6))
    assert_equal([['N'], ['[home]']], grammar.at(7))
    assert_equal([['N'], ['[rule]']], grammar.at(8))
    
    assert_nil(grammar.at(grammar.count + 1))
  end


  def test_include?
    production = 'S --> [a], b'
    grammar = Grammar.new(production)
    assert(grammar.include?(production))
    assert(!grammar.include?(production.sub('a', 'b')))
    assert(!grammar.include?(production.upcase))
  end


  def test_each

    # Hashes in ruby 1.9 preserve order; those from 1.8 don't
    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])

    extracted = []
    grammar.each {|rule|extracted.push(rule)}

    expected = [
      [['S'], ['NP', 'VP']], 
      [['NP'], ['N']],
      [['PP'], ['P', 'NP']],
      [['VP'], ['V', 'NP']],
      [['P'], ['[to]']],
      [['P'], ['[from]']],
      [['V'], ['[work]']],
      [['N'], ['[home]']],
      [['N'], ['[rule]']]
    ]

    assert_equal(expected,extracted)
  end


  def test_to_s
    assert_equal('S --> [a], b', Grammar.new('S --> [a], b').to_s)
    assert_equal('Noun --> verb, adjective', Grammar.new('Noun --> verb, adjective').to_s)
    
    assert_equal('a,S,a --> a, b', Grammar.new('a S a --> a ,    b').to_s)
  end


  def test_to_hash
    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])

    expected = {
      ['S'] => [['NP', 'VP']],
      ['NP'] => [['N']],
      ['PP'] => [['P', 'NP']],
      ['VP'] => [['V', 'NP']], 
      ['P'] => [['[to]'], ['[from]']],
      ['V'] => [['[work]']],
      ['N'] => [['[home]'], ['[rule]']]
    }


    assert_equal(expected, grammar.to_hash)
  end


  def test_start_symbol
    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])
    assert_equal(['S'], grammar.start_symbol)
  end

  def test_start_symbol=
    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])
    #assert_raise(ArgumentError, grammar.start_symbol = 'X') # not in alphabet
    grammar.push('X --> XP')
    grammar.start_symbol = 'X'
    assert_equal('X', grammar.start_symbol)
  end

  def test_alphabet
    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])
    expected = Set.new('S NP VP N PP P VP V P [to] [from] [work] [rule] [home]'.split)
    assert_equal(expected, grammar.alphabet)

  end

  def test_terminal_alphabet
    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])
    expected = Set.new('[to] [from] [work] [rule] [home]'.split)
    assert_equal(expected, grammar.terminal_alphabet)
  end

  def test_non_terminal_alphabet
    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])

    expected = Set.new('S NP VP N PP P VP V P'.split)
    assert_equal(expected, grammar.non_terminal_alphabet)
  end

  def test_pop
    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])

    grammar.pop

    expected = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]'
    ])

    assert_equal(grammar, expected)

    grammar = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'VP --> V, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])

    grammar.pop(3)

    expected = Grammar.new([
      'S --> NP, VP',
      'NP --> N',
      'PP --> P, NP',
      'P --> [to]',
      'P --> [from]',
      'V --> [work]',
      'N --> [home]',
      'N --> [rule]'
    ])

  end

end

