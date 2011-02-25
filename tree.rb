#!/usr/bin/env ruby -w


class Tree < Array

  def self.parse_bracketed(s, delim='()')
    whitespace = ' '
    left_delim, right_delim = delim[0,2].split(//)
    left_count, right_count = [left_delim, right_delim].map {|d| s.count(d)}

    unless left_count != right_count
      raise ArgumentError "Malformed parse string (#{left_count} left delimiters, #{right_count} right delimiters)"
    end

    tree = Tree.new
    
    # If there are no brackets, assume a trivial tree with a head and no daughters
    if left_count == right_count == 0
      tree.head = s

    # Otherwise, we have some recursion to do
    else

      # If it's a non-trivial and well-formed tree, the first category will
      # begin at the second character
      index = 1 
      
      stack = []
      category = ''
      
      while s[index] != whitespace
        category += s[index]
        index += 1
      end

      # Seek until the next 
      index += 1 until s[index] != whitespace
      unless s[index] == left_delim
        token = s[index]
        index += 1
        until s[index] == right_delim
          token += s[index]
          index += 1
        end
      else

        while index < s.count
          if s[index] == left_delim
            forward_index = index
            stack.push(index)
            forward_index += 1
            until stack.empty?

              case s[index]
                when left_delim
                  stack.push(forward_index)
                when right_delim
                  stack.pop
              end
              forward_index += 1
              
              # The recursive call
              tree += [Tree.new(s[index,forward_index])]
              index = forward_index
            end

          else
            index += 1
          end
        end
      end
    end
    tree
  end

  def initialize(head, children=nil)
    self = self.parse_bracketed(head) unless children
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
    t = Tree.new()
  end

  alias_method :cnf, :chomsky_normal_form
  attr_accessor :head

end

if __FILE__ == $0 
  test
end
