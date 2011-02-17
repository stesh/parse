#!/usr/bin/env ruby
require 'Set'


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
end


class Grammar
  include Enumerable

  @@default_delim = '-->'
  @@epsilon = ''

  def self.parse_rule(rule_string, delim=@@default_delim)
    #TODO allow BNF-style rules
    head, daughters = rule_string.split(delim)
    [head.split(' '), daughters.split(' ')]
  end


  def initialize(rules)
    @rules = (rules.kind_of? Hash)? rules : {};

    rules.each do |rule|
      add_rule(rule)
    end

  end


  def add_rule(rule, dest=@rules)
    rule = self.class.parse_rule(rule) if rule.kind_of? String

    if @rules.has_key? rule.head
      @rules[rule.head].push(rule.daughters)
    else
      @rules[rule.head] = [rule.daughters]
    end
  end


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


  def strictly_regular?
    return (left_regular? ^ right_regular?)
  end


  def regular?
    return (left_regular? or right_regular?)
  end

  
  alias :cnf :chomsky_normal_form
  def chomsky_normal_form
     
  end

  alias :gnf :greibach_normal_form
  def greibach_normal_form

  end

  alias :cnf? :chomsky_normal_form?
  def chomsky_normal_form?
    if context_free?
      self.each do |rule|

      end
    end
  end

  alias :gnf? :chomsky_normal_form?
  def greibach_normal_form?

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


  def to_hash
    the_hash = {}
    the_hash.replace(@rules)
    return the_hash
  end


  def to_array
    the_array = []
    self.map {|rule| the_array.push(rule)}
    return the_array
  end
end


if __FILE__ == $0
  rules = ["S S --> [a] [b]", "S --> [c]", "A --> [b] [c]", "D --> [e] [f]"]
  this = Grammar.new(rules)
  puts this
end
