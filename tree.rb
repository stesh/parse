#!/usr/bin/env ruby -w


class Tree < Array

  #
  # Create a new Tree.
  #
  def initialize(head, children=nil, delim='()')

    # If there are no children, assume a Penn-style bracketed tree has been
    # supplied. This needs to be parsed into a Tree.
    if children.nil?
      whitespace = ' '
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
        # normalize spaces
        head = head.gsub(/\(\s+/, '(').gsub(/\s+\)/, ')')
        stack = Array.new
        index = 1
        forward_index = 0

        @head = ''

        until head[index] == ' '
          @head += head[index]
          index += 1
        end

        index += 1 until head[index] != ' '
        if head[index] != left_delim
          word = ''
          word += head[index]
          index += 1
          while head[index] != right_delim
            word += head[index]
            index += 1
          end
          push(word)
        else
          while index < head.length
            if head[index] == left_delim
              forward_index = index
              stack.push(index)
              forward_index += 1
              until stack.empty?
                case head[forward_index]
                when left_delim
                  stack.push(forward_index)
                when right_delim
                  stack.pop
                end
                forward_index += 1
              end
              # The recursive call
              push(Tree.new(head[index...forward_index]))
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

  #
  # Return the leaves of this Tree. 
  #
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

  #
  # Return a new Tree whose root node is this Tree's root note, with this Tree's
  # leaf nodes as its children.
  #
  # Example:
  #
  # (S (NP (Det The) (N politician)) (VP (V took) (NP (Det the) (N bribe))))
  #
  # =>
  #
  # (S The politician took the bribe)
  #
  def flatten
    Tree.new(@head, leaves)
  end

  # 
  # Flatten this Tree in-place
  #
  def flatten!
    # buggerit
    raise NotImplementedError
  end

  #
  # Return the height of this Tree.
  #
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

  # 
  # Iterate over all the subtrees of this Tree.
  #
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

  #
  # Return an Array of all the subtrees of this Tree.
  #
  def subtrees!
    trees = Array.new
    subtrees {|tree| trees.push(tree)}
    return trees
  end

  #
  # Iterate over this Tree in preorder traversal.
  #
  def preorder
    yield self
    each do |child|
      unless pre_terminal?
        child.preorder {|c| yield c}
      else
        each {|c| yield c}
      end
    end
  end

  # 
  # Iterate over this Tree in postorder traversal.
  #
  def postorder
    each do |child|
      unless pre_terminal?
        child.postorder {|c| yield c}
      else
        each {|c| yield c}
      end
    end
    yield self
  end
  
  #
  # Return the grammar licensing the generation of this Tree.
  #
  def to_grammar
    raise NotImplementedError
  end

  #
  # Return the pre-terminals of this Tree.
  #
  def pre_terminals
    raise NotImplementedError
  end

  # 
  # Return whether or not this Tree is terminal. A tree is considered terminal
  # if and only if it possesses no children.
  def terminal?
    self.empty?
  end

  # 
  # Return an Array of terminal/pre-terminal pairs from this Tree.
  #
  # In a natural language parse, such an Array corresponds to a
  # part-of-speech-tagged utterance:
  #
  # (S (NP (Det The) (N politician)) (VP (V took) (NP (Det the) (N bribe))))
  #
  # =>
  #
  # [["The", "Det"], ["politician","N"], ["took","V"], ["the","the"], ["bribe","N"]]
  #
  def part_of_speech
    raise NotImplementedError
  end

  # 
  # Return a copy of this Tree in Chomsky-normal form.
  #
  def chomsky_normal_form
    raise NotImplementedError
  end

  #
  # Transform this Tree to Chomsky-normal form in-place.
  #
  def chomsky_normal_form!
    raise NotImplementedError
  end

  #
  # Return a String representation of this Tree.
  #
  # Trees are represented in Penn treebank-style notation. As such, parentheses
  # () are used to delimit constituents. If desired, alternative delimeters can
  # be supplied. An arbitrary String may also be prepended to non-terminal
  # labels.
  #
  def to_s(delim='()', nonterm_prefix='')
    d, n = delim, nonterm_prefix
    if terminal?
      @head
    else
      l, r = d[0,2].split(//)

      "#{ l } #{ nonterm_prefix }#{ @head } #{
        map do |child|
          if child.kind_of? Tree
            child.to_s(delim=d, nonterm_prefix=n)
          else
            child.to_s
          end
        end .join(' ')} #{ r }"
    end
    
  end

  def draw
    # TODO write or steal a graphical pretty-printer
    to_s
  end

  # 
  # Return a String representation for display in a LaTeX document with the Penn
  # QTree package.
  #
  def latex_qtree
    "\\Tree " + to_s(delim='[]', nonterm_prefix='.')
  end

  def penn_bracketed_tree
    to_s
  end

  #
  # Test this class. Somehow.
  #
  # This method probz shouldn't exist
  #
  def test
    sentence = "(S (NP (NNP John)) (VP (V runs)))"
    test = Tree.new(sentence)
  end

  alias_method :cnf, :chomsky_normal_form
  attr_accessor :head

end

if __FILE__ == $0 
  test
end
