#!/usr/bin/env ruby -w


class Tree < Array

  def self.parse_bracketed(s, delim='()')
  end

  def initialize(head, children)
    super(children)
    @head = head
  end

  def leaves
    #FIXME this is probably a bit newbish
    the_leaves = []
    each do |child|
      if child.kind_of? Tree
        the_leaves.push(child)
      else
        
        the_leaves = the leaves + (child.leaves)
      end
    end

    the_leaves
  end

  def flatten
    Tree.new(@head, leaves)
  end

  def flatten!
    self = flatten
  end

  def height
    max_height = 0
    each do |child|
      if child.kind_of? Tree
        max_height = [max_height, 1].max
      else
        max_height = [max_height, child.height].max
      end
    end
    max_height.succ
  end

  def subtrees
    yield self
    each do |child|
      if child.kind_of? Tree
        child.subtrees do |tree|
          yield tree
        end
      end
  end

  def preorder
  end

  def postorder
  end

  def to_grammar
  end

  def pre_terminals
  end

  def terminal?
    self.empty?
  end

  def part_of_speech
  end

  def chomsky_normal_form
  end

  def to_s(delim='()', nonterm_prefix='')
    if terminal?
      @head
    else
      l, r = delim[0,2].split(//)
      "#{ l } #{ nonterm_prefix } #{ @head } #{ map {|child| child.to_s}.join(' ')} #{ r }"
    end
  end

  def draw
    # TODO write or steal a graphical pretty-printer
    to_s
  end

  def latex_qtree
    to_s(delim='[]', nonterm_prefix='.')
  end

  def penn_bracketed_tree
    to_s
  end

  def test
  end

  alias_method :cnf, :chomsky_normal_form
  attr_accessor :head

end
