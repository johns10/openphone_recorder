defmodule Discussit.TokensTest do
  use ExUnit.Case
  alias Discussit.Tokens

  describe "tokens" do
    test "max_text_percentage_count" do
      # max = 100, prompt = 0, input = 80, output = 20
      assert 20 ==
               Tokens.max_text_output_count(
                 max_tokens: 100,
                 chunker: :test
               )
    end
  end
end
