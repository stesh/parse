#!/usr/bin/env ruby

require 'grammar'
require 'test/unit'

class TestGrammar < Test::Unit::TestCase


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

  end


  def test_left_regular?

  end


  def test_strictly_regular?

  end


  def test_regular?

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


end
