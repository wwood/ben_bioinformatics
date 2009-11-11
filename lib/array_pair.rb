require 'rsruby'

class Object
  def pick(*method_symbols)
    method_symbols.collect do |symbol|
      self.send(symbol)
    end
  end
end

class String
  def wrap(col=80)
    gsub(/(.{1,#{col}})( +|$\n?)|(.{1,#{col}})/,
      "\\1\\3\n") 
  end
end

# An added method for an array class that return the pairs of classes
class Array
  # Return an array of all pairs of elements from this array (each is an array).
  # If another_array is not nil, then do pairwise between this array and that (but not within each)
  #
  # NOT thread safe.
  def pairs(another_array = nil)
    pairs = []
    
    if another_array #between this array and the next
      (0..length-1).each do |index1|
        (0..another_array.length-1).each do |index2|
          pairs.push [self[index1], another_array[index2]]
        end
      end       
    else # within this array only
      (0..length-1).each do |index1|
        index2 = index1+1
        while index2 < length
          pairs.push [self[index1], self[index2]]
          index2 += 1
        end
      end      
    end

    return pairs
  end
  
  # Array#sum is not included in Ruby, but is in Rails.
  # Redefining it has problems somehow, so I'm going to
  # use Array#total instead
  # Defining this method seems to make rails fail. Is it defined in Rails
  # somehow as well?
  #  def sum; inject( nil ) { |sum,x| sum ? sum+x : x }; end;
  def total; inject( nil ) { |sum,x| sum ? sum+x : x }; end;
  
  def average
    if Array.new.respond_to?(:sum)
      sum.to_f / length.to_f
    else
      total = 0.0; each{|e| total+=e}
      total / length.to_f
    end
  end
  
  #  Run the method given on each member of the array, then
  #  collect and return the results
  def pick(*method_symbols)
    if method_symbols.empty?
      return nil
    elsif method_symbols.length > 1
      return collect{|element|
        method_symbols.collect{|meth|
          element.send(meth)
        }
      }
    else
      return collect{|element|
        element.send(method_symbols[0])
      }
    end
    
  end
  
  # so intuitively the opposite of Array.reject
  alias_method(:accept, :select)
  
  # Assuming this array is an array of array of numeric/nil values,
  # return the array with each of the columns normalised
  #
  # This is simple linear scaling to [0,1], so each value v is transformed by
  # transformed = (v-minima)/(maxima_minima)
  # nil values are ignored.
  #
  # Doesn't modify the underlying array of arrays in any way, but returns
  # the normalised array
  def normalise_columns(columns_to_normalise=nil)
    column_maxima = []
    column_minima = []
    
    # work out how to normalise the array
    each do |row|
      row.each_with_index do |col, index|
        next unless columns_to_normalise.nil? or columns_to_normalise.include?(index)
        raise Exception, "Unexpected entry class found in array to normalise - expected numeric or nil: #{col}" unless col.nil? or col.kind_of?(Numeric)
        
        # maxima
        if column_maxima[index]
          if !col.nil? and col > column_maxima[index]
            column_maxima[index] = col
          end
        else
          # set it - doesn't matter if it is nil in the end
          column_maxima[index] = col
        end
        
        #minima
        if column_minima[index]
          if !col.nil? and col < column_minima[index]
            column_minima[index] = col
          end
        else
          # set it - doesn't matter if it is nil in the end
          column_minima[index] = col
        end
      end
    end
    
    # now do the actual normalisation
    to_return = []
    each do |row|
      new_row = []
      row.each_with_index do |col, index|
        # if nil, normalise everything
        # if not nil and include, normalise
        # if not nil and not include, don't normalise
        if columns_to_normalise.nil? or columns_to_normalise.include?(index)
          minima = column_minima[index]
          maxima = column_maxima[index]
      
          if col.nil?
            new_row.push nil
          elsif minima == maxima
            new_row.push 0.0
          else
            new_row.push((col.to_f-minima.to_f)/((maxima-minima).to_f))
          end
        else
          new_row.push(col)
        end
      end
      to_return.push new_row
    end
    return to_return
  end
  
  # make a hash out the array by mapping [element0, element1] to
  # {element0 => 0, element1 => 1}. Raises an Exception if 2 elements
  # are the same. nil elements are ignored.
  def to_hash
    hash = {}
    each_with_index do |element, index|
      next if element.nil?
      raise Exception, "Multiple elements for #{element}" if hash[element]
      hash[element] = index
    end
    hash
  end
  
  # For SQL conditions
  # ['a','bc'] => "('a','bc')" 
  def to_sql_in_string
    return '()' if empty?
    return "('#{join("','")}')"
  end

  # For SQL conditions. In [] brackets, single quotes don't work.
  # ['a','bc'] => "(a,bc)"
  def to_sql_in_string_no_quotes
    return '()' if empty?
    return "(#{join(",")})"
  end


  def median
    return nil unless length>0
    a = sort
    if length%2 == 0
      return [a[length/2-1],a[length/2]].average
    else
      return a[length/2]
    end
  end

  def standard_deviation
    return nil if empty?
    RSRuby.instance.sd(self)
  end

  # Similar to pairs(another_array) iterator, in that you iterate over 2
  # pairs of elements. However, here only the one array (the 'this' Enumerable)
  # and the names of these are from the names
  def each_lower_triangular_matrix
    each_with_index do |e1, i|
      if i < length-1
        self[i+1..length-1].each do |e2|
          yield e1, e2
        end
      end
    end
  end

  # like uniq -c for unix
  def uniq_count
    hash = {}
    each do |e|
      hash[e] ||= 0
      hash[e] += 1
    end
    hash
  end

  def no_nils
    reject do |element|
      element.nil?
    end
  end
end
