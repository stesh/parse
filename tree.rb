#!/usr/bin/env ruby -w


class Tree < Array

  def initialize(head, children=nil)

    # If there are no children, assume a Penn-style bracketed tree has been
    # supplied. This needs to be parsed into a Tree.
    if children.nil?
      whitespace = ' '
      delim = '()'
      left_delim, right_delim = delim[0,2].split(//)
      left_count, right_count = [left_delim, right_delim].map {|d| head.count(d)}

      unless left_count == right_count
        raise ArgumentError, "Malformed bracketed tree \"#{head}\": #{left_count} left delimiters, #{right_count} right delimiters"
      end
    
      # If there are no brackets, assume a trivial tree with a head and no daughters
      if left_count.zero? and right_count.zero?
        @head = head

      # Otherwise, we have some recursion to do
      else
        stack = Array.new
        index = 1
        forward_index = 0

        category = ''

        until head[index] == ' '
          category += head[index]
          index += 1
        end

        index += 1 until head[index] != ' '

        if head[index] != '('
          word = ''
          word += head[index]
          index += 1
          while head[index] != ')'
            word += head[index]
            index += 1
          end
        else
          while index < head.length
            if head[index] == '('
              forward_index = index
              stack.push(index)
              forward_index += 1
              until stack.empty?
                puts stack
                case head[forward_index]
                when '('
                  stack.push(forward_index)
                when ')'
                  stack.pop()
                end
                forward_index += 1
              end

              # The recursive call
              push(Tree.new(head[index, forward_index]))
              index = forward_index
            else
              index += 1
            end
          end
        end
      end
    else
      super(children)
      @head = head
    end
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
    # buggerit
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
    t = Tree.new()
  end

  alias_method :cnf, :chomsky_normal_form
  attr_accessor :head

end

if __FILE__ == $0 
  sentence = "(S (NP (NNP John)) (VP (V runs)))"
  test = Tree.new(sentence)
  puts test.to_s
end
