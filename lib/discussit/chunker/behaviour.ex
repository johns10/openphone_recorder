defmodule Discussit.Chunker.Behaviour do
  @moduledoc false
  @callback prompt(binary(), keyword()) :: binary()
  @callback prompt_count(keyword()) :: integer
end
