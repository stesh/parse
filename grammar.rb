#!/usr/bin/env ruby
# encoding: utf-8


class Grammar

  require 'set'
  include Enumerable

  @@default_delim = '-->'
  @@epsilon = ''

  def self.parse_rule(rule_string, delim=@@default_delim)
    # TODO allow BNF-style rules
    # FIXME nasty things will happen if invalid DCG-type rules are provided
    rule_string.gsub!(/ /, '');
    head, daughters = rule_string.split(delim)
    [head.split(','), daughters.split(',')]
  end


  # Construct a new Grammar from the supplied rules.
  #
  # Rules may be an Array of Arrays (corresponding to heads and daughters of
  # rules), an Array of DCG-like strings, or a hash mapping head symbols to
  # possible daughter productions.
  def initialize(rules, start_symbol=nil)
  
    # Allow a previously-generated hash to be dropped into place
    #FIXME validate the hash?
    @rules = rules if rules.kind_of? Hash
    @rules ||= {}

    # Allow a single rule expressed as a string
    rules = [rules] if rules.kind_of? String

    
    rules.each do |rule|
      push(rule)
    end

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
    Set.new(alphabet.partition {|symbol| symbol.terminal?}.shift)
  end

  def non_terminal_alphabet
    Set.new(alphabet.partition {|symbol| symbol.non_terminal?}.shift)
  end

  def alphabet
    Set.new(to_a.flatten!.uniq!)
  end

  # Add a rule to this Grammar
  # If a DCG-style rule string is supplied, it is tokenized into heads and
  # daughters.
  def push(rule, dest=@rules)
    rule = self.class.parse_rule(rule) if rule.kind_of? String

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
    all? {|rule| rule.context_free?}
  end


  def right_regular?
    all? {|rule| rule.right_regular?}
  end


 def left_regular?
    all? {|rule| rule.left_regular?}
  end 

  # Determine whether or not this grammar is strictly regular.
  #
  # A grammar is strictly regular if and only if it is left-regular or
  # right-regular, but not both.
  def strictly_regular?
    left_regular? or right_regular?
  end


  # Determine whether or not this grammar is regular.
  # A grammar is regular if and only if it is left-regular or right-regular, or
  # both.
  def regular?
     all? {|rule| rule.left_regular? or rule.right_regular?}
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
    all? {|rule| rule.chomsky_normal_form?} 
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
    all? {|rule| rule.greibach_normal_form?}
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
    any {|rule| rule.left_recursive?} 
  end


  # Return a new Grammar containing the rules of this grammar and other
  def +(other)
    self if other.length == 0
    union = Grammar.new(to_hash)
    other.each do |rule|
      union.push(rule)
    end

    union
  end

  # Return a new Grammar containing the rules of this grammar, minus those
  # contained by other
  def -(other)
    self if other.length == 0
    intersection = Grammar.new(to_hash)
    intersection.delete_if {|rule| other.include? rule}
    intersection
  end

  # Return the nth rule defined by this grammar
  def at(n)
      return nil if n >= count
      first(n+1).pop
  end


  # Return whether or not this Grammar contains production
  def include?(production)
    production = self.class.parse_rule(production) if production.kind_of? String
    any? {|existing_production| existing_production == production}
  end


  def each
    @rules.each do |head,daughters|
      daughters.each do |daughter|
        yield [head, daughter]
      end
    end
  end


  def to_s(delim=@@default_delim,bnf=false)
    #TODO BNF form
#    if bnf and context_free?
#      delim = '::=' if delim != @@default_delim 
#      @rules.map {|head, daughters| "#{head.join(' ')} #{delim} #{daughters.map {|daughter| daughter.join(' ')}.join(' | ')}"}
#    end
    map {|r|"#{r.head.join(', ')} #{delim} #{r.daughters.join(', ')}"}.join("\n")
  end


  # Return a Hash mapping Head symbols to an array of their possible
  # productions in this grammar
  #
  # Order of introduction is preserved.
  def to_hash
    the_hash = {}
    the_hash.replace(@rules)
    return the_hash
  end


  def to_a
    to_hash.to_a
  end

  alias :cnf :chomsky_normal_form
  alias :cnf? :chomsky_normal_form?

  alias :gnf :greibach_normal_form
  alias :gnf? :greibach_normal_form?

  alias :length :count
  alias :[] :at

end


class Array
  def head
    at(0)
  end
  def daughters
    at(1)
  end

  def context_free?
    head.length == 1 and head[0].non_terminal?
  end

  def right_regular?
    context_free? and
    daughters.length == 2 and
    daughters[0].terminal? and
    (daughters[1].non_terminal? or daughters[1].nil?)
  end

  def left_regular?
    context_free? and
    daughters.length == 2 and
    daughters[1].terminal? and
    (daughters[0].non_terminal? or daughters[1].nil?)
  end


  def left_recursive? 
    return head == daughters.first(head.count)
  end

  def epsilon_production?
    context_free? and daughters.count == 1 and daughters[0].empty_string?
  end

  def chomsky_normal_form?
    context_free? and (
      (daughters.count == 2 and daughters.all {|symbol| symbol.non_terminal?}) or
      (daughters.count == 1 and daughters[0].terminal?)
    )
  end

  def cyclic?
    head == daughters
  end

  def greibach_normal_form?
     context_free? and (
      (daughters.count == 2 and daughters[0].terminal? and daughters[1].non_terminal?) or
      (daughters.count == 1 and daughters[0].empty_string?)
    ) 
  end

end


class String
  def terminal?
    start_with? '[' and end_with? ']';
  end

  def non_terminal?
    not terminal?
  end

  def empty_string?
    self == '[]'
  end

end

if __FILE__ == $0
  g = Grammar.new("Noun --> verb, adjective")
  puts g.to_s
end
