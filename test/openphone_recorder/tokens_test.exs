defmodule OpenphoneRecorder.TokensTest do
  use ExUnit.Case
  alias OpenphoneRecorder.Tokens

  describe "tokens" do
    test "max_text_percentage_count" do
      # max = 100, prompt = 0, input = 80, output = 20
      assert 20 ==
               Tokens.max_text_output_count(
                 max_tokens: 100,
                 margin: 0,
                 prompt_fun: fn text, _opts -> "#{text}" end
               )
    end
  end
end
