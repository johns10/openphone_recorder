defmodule OpenphoneRecorder.Statements.Chunker.Test do
  def prompt_count(_opts), do: 0

  def prompt_fun(text, _opts), do: "#{text}"
end
