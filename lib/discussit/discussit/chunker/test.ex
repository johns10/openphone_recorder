defmodule Discussit.Chunker.Test do
  def prompt_count(_opts), do: 0

  def prompt(text, _opts), do: "#{text}"
end
