#!/usr/bin/env ruby


class Array
  def head
    at(0)
  end
  def daughters
    at(1)
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


class Grammar
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
  def initialize(rules)

    # Allow a previously-generated hash to be dropped into place
    #FIXME validate the hash?
    @rules = rules if rules.kind_of? Hash
    @rules ||= {}

    rules.each do |rule|
      add_rule(rule)
    end

  end

  # Add a rule to this Grammar
  # If a DCG-style rule string is supplied, it is tokenized into heads and
  # daughters.
  def add_rule(rule, dest=@rules)
    rule = self.class.parse_rule(rule) if rule.kind_of? String

    if @rules.has_key? rule.head
      @rules[rule.head].push(rule.daughters)
    else
      @rules[rule.head] = [rule.daughters]
    end
  end


  # Determine whether or not this Grammar is context-free.
  #
  # A grammar is context-freee if and only if all of its rules are of the form 
  #
  # A --> w
  #
  # Where A is a single non-terminal, and w is an arbitrary sequence of
  # possibly-empty terminals or non-terminals.
  def context_free?
    self.each do |rule|
      return false if rule.head.length > 1 or rule.head[0].terminal? 
    end
  true
  end


  def right_regular?
    if context_free?
      self.each do |rule|
        return false if rule.daughters.length > 2
        return false unless rule.daughters[0].terminal? && rule.daughters[1].non_terminal?  
      end
    else
      false
    end
    true
  end


  def left_regular?
    if context_free?
      self.each do |rule|
        return false if rule.daughters.length > 2
        return false unless rule.daughters[0].non_terminal? && rule.daughters[1].terminal?
      end
    else
      false
    end
    true
  end

  # Determine whether or not this grammar is strictly regular.
  #
  # A grammar is strictly regular if and only if it is left-regular or
  # right-regular, but not both.
  def strictly_regular?
    return (left_regular? ^ right_regular?)
  end


  # Determine whether or not this grammar is regular.
  # A grammar is regular if and only if it is left-regular or right-regular, or
  # noth.
  def regular?
    return (left_regular? or right_regular?)
  end

  # Return a Grammar in Chomsky-normal form which is equivalent to this Grammar.
  def chomsky_normal_form
     
  end

  # Return a Grammar in Greibach-normal form which is equivalent to this Grammar.
  def greibach_normal_form

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
    if context_free?
      self.each do |rule|
        if rule.daughters.length == 1
          return false if rule.daughters[0].non_terminal?
        else
          return false if rule.daughters.any{|d| d.terminal?}
        end
      end
    else
      false
    end
    true
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
    if context_free?
      self.each do |rule|
        return false if rule.daughters[0].terminal?
        return false if rule.daughters.length > 1 and not rule.daughters[0].empty_string?
      end
    else
      false
    end
    true
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
    self.map {|r|"#{r.head.join(', ')} #{delim} #{r.daughters.join(', ')}"}.join("\n")
  end


  # Return a Hash mapping Head symbols to an array of their possible
  # productions in this grammar
  #
  # Order of introduction is not necessarily preserved.
  def to_hash
    the_hash = {}
    the_hash.replace(@rules)
    return the_hash
  end

  # Return an Array of Arrays, each corresponding to the Array of head symbols
  # and Array of daughter symbols of a rule in this Grammar.
  #
  # Order of introduction is preserved.
  #
  def to_array
    the_array = []
    self.map {|rule| the_array.push(rule)}
    return the_array
  end


  alias :cnf :chomsky_normal_form
  alias :cnf? :chomsky_normal_form?

  alias :gnf :greibach_normal_form
  alias :gnf? :chomsky_normal_form?
end


if __FILE__ == $0
  rules = ["S --> [a],S,[b]", "S -->[c]", "A --> [b],[c]", "D --> [e],[f]"]
  this = Grammar.new(rules)
  puts this
end
