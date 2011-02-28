#!/usr/bin/env ruby -w
# encoding: utf-8


class Grammar

  require 'set'
  include Enumerable

  @@default_delim = '-->'
  @@epsilon = ''


  # Construct a new Grammar from the supplied rules.
  #
  # Rules may be an Array of Arrays (corresponding to heads and daughters of
  # rules), an Array of DCG-like strings, or a hash mapping head symbols to
  # possible daughter productions.
  def initialize(rules, start_symbol=nil)
  
    # Allow a previously-generated hash to be dropped into place
    #FIXME validate the hash?
    @rules = rules if rules.kind_of? Hash
    @rules ||= {  }

    # Allow a single rule expressed as a string
    
    if rules.kind_of? String
      if rules.include? "\n"
        rules = rules.parse_rules
      else
        rules = rules.parse_rule
      end
    end
    rules = [rules] if rules.kind_of? String
    rules.each { |r| push(r) }

    # If no start symbol is given, assume the left-most head symbol of the first
    # rule supplied to be start symbol
    @start_symbol = start_symbol
    @start_symbol ||= first(1).head[0]

  end

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

  def terminal_alphabet
    Set.new(alphabet.partition { |s| s.terminal? }.shift)
  end

  def non_terminal_alphabet
    Set.new(alphabet.partition { |s| s.non_terminal? }.shift)
  end

  def alphabet
    Set.new(to_a.flatten!.uniq!)
  end

  # Add a rule to this Grammar
  # If a DCG-style rule string is supplied, it is tokenized into heads and
  # daughters.
  def push(rule, dest=@rules)
    rule = rule.parse_rule if rule.kind_of? String
    if @rules.has_key? rule.head
      @rules[rule.head].push(rule.daughters)
    else
      @rules[rule.head] = [rule.daughters]
    end
  end

  # Determine whether or not this Grammar is context-free.
  #
  # A grammar is context-free if and only if all of its rules are of the form 
  #
  # A --> w
  #
  # Where A is a single non-terminal, and w is an arbitrary sequence of
  # possibly-empty terminals or non-terminals.
  def context_free?
    all? { |r| r.context_free? }
  end

  def right_regular?
    all? { |r| r.right_regular? }
  end

  def left_regular?
    all? { |r| r.left_regular? }
  end 

  # Determine whether or not this grammar is strictly regular.
  #
  # A grammar is strictly regular if and only if it is left-regular or
  # right-regular, but not both.
  def strictly_regular?
    left_regular? || right_regular?
  end

  # Determine whether or not this grammar is linear.
  # A grammar is regular if and only if all of its rules are left-regular or
  # right-regular
  def linear?
     all? { |r| r.left_regular? || r.right_regular? }
  end

  #FIXME
  # Determine whether or not this Grammar is in Chomsky-normal form (CNF).
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
  def chomsky_normal_form?
    all? { |r| r.chomsky_normal_form? } 
  end

  # Determine whether or not this Grammar is in Greibach-normal form (GNF).
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

  # Return a Grammar in Chomsky-normal form which is equivalent to this Grammar.
  def chomsky_normal_form
     
  end

  # Return a Grammar in Greibach-normal form which is equivalent to this Grammar.
  def greibach_normal_form

  end

  # Return whether or not this Grammar is left-recursive.
  # 
  # A Grammar is left-recursive if it contains any production of the form
  #
  # A --> A, n
  #
  # where A is a non-empty sequence of symbols containing at least one
  # non-terminal, and n is an arbitrary sequence of possibly empty
  # terminals or not terminals
  def left_recursive?
    any { |r| r.left_recursive? } 
  end


  # Return a new Grammar containing the rules of this grammar and other
  def +(other)
    self if other.length == 0
    union = Grammar.new(to_hash)
    other.each do |r|
      union.push(r)
    end

    union
  end

  # Return a new Grammar containing the rules of this grammar, minus those
  # contained by other
  def -(other)
    self if other.length == 0
    intersection = Grammar.new(to_hash)
    intersection.delete_if { |r| other.include? r }

    intersection
  end

  # FIXME Should == correspond to 'has the same productions in the same order'
  # or 'Generates the same language'? If so, how?
  def ==(other)
    to_has == other.to_hash
  end

  # Return the nth rule defined by this grammar
  def at(n)
      return nil if n >= count
      first(n+1).pop
  end


  # Return whether or not this Grammar contains production
  def include?(production)
    production = production.parse_rule if production.kind_of? String

    any? { |p| p == production }
  end


  def each
    @rules.each { |h,ds| ds.each { |d| yield [h, d] } }
  end


  def to_s(delim=@@default_delim,bnf=false)
    #TODO BNF form
#    if bnf and context_free?
#      delim = '::=' if delim != @@default_delim 
#      @rules.map { |head, daughters| "#{ head.join(' ') } #{ delim } #{ daughters.map { |daughter| daughter.join(' ') }.join(' | ') }" }
#    end
    map { |r|"#{ r.head.join(', ') } #{ delim } #{ r.daughters.join(', ') }" }.join("\n")
  end


  # Return a Hash mapping Head symbols to an array of their possible
  # productions in this grammar
  #
  # Order of introduction is preserved.
  def to_hash
    the_hash = {  }
    the_hash.replace(@rules)

    return the_hash
  end


  def to_a
    the_array = []
    each { |r| the_array.push(r) }
    the_array
  end

  alias_method :cnf :chomsky_normal_form
  alias_method :cnf? :chomsky_normal_form?

  alias_method :gnf :greibach_normal_form
  alias_method :gnf? :greibach_normal_form?

  alias_method :length :count
  alias_method :[] :at

end


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
    (self =~ /^((\[\w+\]|\w+),)*(\[\w+\]|\w+)-->((\[\w+\]|\w+),)*(\[\w+\]|\w+)$/) != nil
  end


  def parse_rule(delim='-->')
    rule = gsub(/ /, '')
    #raise ArgumentError unless valid_production?
    head, daughters = rule.split(delim)

    [head.split(','), daughters.split(',')]
  end

  def parse_rules(delim='-->', line_end="\n")
    rules = split("\n")

    rules.map { |r| r.parse_rule } 
  end
end

if __FILE__ == $0
end
