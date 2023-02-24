defmodule ElvenGard.Protocol.Binary.IntegerTypeTest do
  use ExUnit.Case, async: true

  alias ElvenGard.Protocol.Binary.IntegerType

  # describe "Encode binary integer type:" do
  #   @tag :skip
  #   test "default behaviour (unsigned + big)" do
  #     got = IntegerType.encode(0x1337)
  #     expected = <<0x1337::size(32)>>

  #     assert got == expected
  #   end

  #   @tag :skip
  #   test "default behaviour with overflow (unsigned + big)" do
  #     got = IntegerType.encode(0x1337133700)
  #     expected = <<0x37133700::size(32)>>

  #     assert got == expected
  #   end

  #   test "signed + little" do
  #     got = IntegerType.encode(0x1337, signed: true, endian: :little)
  #     expected = <<0x1337::signed-little-size(32)>>

  #     assert got == expected
  #   end

  #   test "unsigned + little" do
  #     got = IntegerType.encode(0x1337, signed: false, endian: :little)
  #     expected = <<0x1337::unsigned-little-size(32)>>

  #     assert got == expected
  #   end

  #   @tag :skip
  #   test "signed + big" do
  #     got = IntegerType.encode(0x1337, signed: true, endian: :big)
  #     expected = <<0x1337::signed-big-size(32)>>

  #     assert got == expected
  #   end

  #   @tag :skip
  #   test "unsigned + big" do
  #     got = IntegerType.encode(0x1337, signed: false, endian: :big)
  #     expected = <<0x1337::unsigned-big-size(32)>>

  #     assert got == expected
  #   end

  #   test "signed + native" do
  #     got = IntegerType.encode(0x1337, signed: true, endian: :native)
  #     expected = <<0x1337::signed-native-size(32)>>

  #     assert got == expected
  #   end

  #   test "unsigned + native" do
  #     got = IntegerType.encode(0x1337, signed: false, endian: :native)
  #     expected = <<0x1337::unsigned-native-size(32)>>

  #     assert got == expected
  #   end
  # end

  describe "Decode binary integer type:" do
    @tag :skip
    test "default behaviour without rest (unsigned + big)" do
      got = IntegerType.decode(<<0x1337::size(32)>>)
      expected = {0x1337, <<>>}

      assert got == expected
    end

    @tag :skip
    test "default behaviour with rest (unsigned + big)" do
      got = IntegerType.decode(<<0x1337::size(32), 0x42::signed-size(32), 0x01::little-size(32)>>)
      expected = {0x1337, <<0x42::signed-size(32), 0x01::little-size(32)>>}

      assert got == expected
    end

    test "signed + little" do
      got = IntegerType.decode(<<0x1337::signed-little-size(32)>>, signed: true, endian: :little)
      expected = {0x1337, <<>>}

      assert got == expected
    end

    test "unsigned + little" do
      got =
        IntegerType.decode(<<0x1337::unsigned-little-size(32)>>, signed: false, endian: :little)

      expected = {0x1337, <<>>}

      assert got == expected
    end

    @tag :skip
    test "signed + big" do
      got = IntegerType.decode(<<0x1337::signed-big-size(32)>>, signed: true, endian: :big)
      expected = {0x1337, <<>>}

      assert got == expected
    end

    @tag :skip
    test "unsigned + big" do
      got = IntegerType.decode(<<0x1337::unsigned-big-size(32)>>, signed: false, endian: :big)
      expected = {0x1337, <<>>}

      assert got == expected
    end

    test "signed + native" do
      got = IntegerType.decode(<<0x1337::signed-native-size(32)>>, signed: true, endian: :native)
      expected = {0x1337, <<>>}

      assert got == expected
    end

    test "unsigned + native" do
      got =
        IntegerType.decode(<<0x1337::unsigned-native-size(32)>>, signed: false, endian: :native)

      expected = {0x1337, <<>>}

      assert got == expected
    end
  end
end
