# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'spoctopus_wrapper'

class SpoctopusWrapperTest < Test::Unit::TestCase

  def test_no_tmd_result
    res = Bio::Spoctopus::Result.create_from_output([
        '>wrapperSeq',
        'gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg',
        'ggggggggggggggggggggggggggggggggggggg'
      ].join("\n"))

    assert_kind_of Transmembrane::SignalPeptideTransmembraneDomainProtein, res
    assert_equal [], res.transmembrane_domains
    assert_equal false, res.signal?
  end

  def test_two_tmd_result
    res = Bio::Spoctopus::Result.create_from_output([
        '>wrapperSeq',
        'iiiiiiiiiiMMMMMMMMMMMMMMMMMMMMMooooooooooooooooooooooooooooo',
        'ooooMMMMMMMMMMMMMMMMMMMMMiiiiiMMMMMMMMMMMMMMMMMMMMMo'
      ].join("\n"))

    assert_kind_of Transmembrane::SignalPeptideTransmembraneDomainProtein, res
    assert_equal 3, res.transmembrane_domains.length
    assert_equal 11, res.transmembrane_domains[0].start
    assert_equal 31, res.transmembrane_domains[0].stop
    assert_equal 112-1, res.transmembrane_domains[2].stop

    # test orientation
    assert_equal OrientedTransmembraneDomain::INSIDE_OUT, res.transmembrane_domains[0].orientation
    assert_equal OrientedTransmembraneDomain::OUTSIDE_IN, res.transmembrane_domains[1].orientation
    assert_equal OrientedTransmembraneDomain::INSIDE_OUT, res.transmembrane_domains[2].orientation
  end

  def test_all_tmd_result
    res = Bio::Spoctopus::Result.create_from_output([
        '>wrapperSeq',
        'MMMMMMMMMMMMMMMMMMMMM'
      ].join("\n"))

    assert_equal 1, res.transmembrane_domains.length
    assert_equal 1, res.transmembrane_domains[0].start
    assert_equal 21, res.transmembrane_domains[0].stop
    assert_equal OrientedTransmembraneDomain::UNKNOWN, res.transmembrane_domains[0].orientation
  end

  def test_tmd_at_end_result
    res = Bio::Spoctopus::Result.create_from_output([
        '>wrapperSeq',
        'oooMMMMMMMMMMMMMMMMMMMMM'
      ].join("\n"))

    assert_equal 1, res.transmembrane_domains.length
    assert_equal OrientedTransmembraneDomain::OUTSIDE_IN, res.transmembrane_domains[0].orientation
  end

  def test_signal_peptide
    res = Bio::Spoctopus::Result.create_from_output([
        '>wrapperSeq',
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnSSSSSSSSSSSSSSSoooooooooooooooooooooooooooooooooooooooooooooooooooo'
      ].join("\n"))

    assert res.signal?
    assert_equal false, res.has_domain?
    assert_equal 31, res.signal_peptide.start
    assert_equal 45, res.signal_peptide.stop
  end
end
