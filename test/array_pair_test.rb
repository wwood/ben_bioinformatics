# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'rubygems'
require 'array_pair'


class ArrayPairTest < Test::Unit::TestCase
  def test_within
    me = [1,2,3]
    assert_equal [[1,2],[1,3],[2,3]], me.pairs
  end
  
  def test_between
    me = [1,2]
    you = [4,5,6]
    assert_equal [[1,4],[1,5],[1,6],[2,4],[2,5],[2,6]], me.pairs(you)
  end
  
  def test_normlise
    me = [[1,3,-1],[1,2,2]]
    assert_equal [[0,1,0],[0,0,1]], me.normalise_columns
    
    assert_equal [[0,nil],[nil,nil]], [[10,nil],[nil,nil]].normalise_columns
    
    assert_equal [[0,0,'meh']], [[1,2,'meh']].normalise_columns((0..1))
  end
  
  def test_to_hash
    hash = {'a' => 0, 'b' => 1, 'c' => 2}
    assert_equal hash, ['a','b','c'].to_hash
    
    hash = {'a' => 0, 'b' => 1, 'c' => 3}
    assert_equal hash, ['a','b',nil,'c'].to_hash
    
    assert_raise Exception do
      [1,2,3,2,4].to_hash
    end
    
    hash = {}
    assert_equal hash, [].to_hash
  end
  
  def test_pick
    # No picks
    assert_equal nil, [0,9].pick()
    
    # Single picks
    assert_equal [], [].pick(:zero?)
    assert_equal [true], [0].pick(:zero?)
    assert_equal [true, false, true], [0,1,0].pick(:zero?)
    
    # multiple picks
    assert_equal [[true, 0.0],[false, 2.0]], [0,2].pick(:zero?,:to_f)
  end
  
  def test_to_sql_in_string
    assert_equal '()', [].to_sql_in_string
    assert_equal "('a','bc')", ['a','bc'].to_sql_in_string
  end

  def test_median
    assert_equal nil, [].median
    assert_equal 1, [1].median
    assert_equal 1.5, [0,3,2,1].median
    assert_equal 2, [1,2,3].median
  end

  def test_each_lower_triangle_iterator
    gained = []
    [].each_lower_triangular_matrix() { |i,j| gained.push([i,j]) }
    assert_equal [], gained

    gained = []
    [1].each_lower_triangular_matrix() { |i,j| gained.push([i,j]) }
    assert_equal [], gained

    gained = []
    [1,2].each_lower_triangular_matrix() { |i,j| gained.push([i,j]) }
    assert_equal [1,2], gained[0]
    assert_equal 1, gained.length

    gained = []
    [1,2,3].each_lower_triangular_matrix() { |i,j| gained.push([i,j]) }
    assert_equal [1,2], gained[0]
    assert_equal [1,3], gained[1]
    assert_equal [2,3], gained[2]
    assert_equal 3, gained.length
  end

  def test_standard_deviation
    assert_nil [].standard_deviation
    assert_equal 1.0, [1,2,3].standard_deviation
    assert_equal 1.29, [1,2,3,4].standard_deviation.round(2)
  end

  def test_uniq_count
    assert_equal({}, [].uniq_count)
    assert_equal({'a' => 1}, ['a'].uniq_count)
    assert_equal({'a' => 2}, ['a','a'].uniq_count)
    assert_equal({'a' => 2, 'b' => 1}, ['a','b','a'].uniq_count)
  end
end
