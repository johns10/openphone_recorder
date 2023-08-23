defmodule Discussit.TokensTest do
  use ExUnit.Case
  alias Discussit.Tokens

  describe "tokens" do
    test "max_text_percentage_count" do
      # max = 100, prompt = 0, input = 80, output = 20
      assert 20 ==
               Tokens.max_text_output_count(
                 max_tokens: 100,
                 percentage_reduction: 0.25,
                 prompt: ""
               )
    end

    test "max_text_fixed_count" do
      # max = 100, prompt = 0, input = 80, output = 20
      assert 20 ==
               Tokens.max_text_output_count(
                 max_tokens: 100,
                 fixed_reduction: 20,
                 prompt: ""
               )
    end
  end

  describe "all_stopwords?" do
    test "base case" do
      assert true ==
               "okay"
               |> Tokens.all_stopwords?()
    end
  end
end
