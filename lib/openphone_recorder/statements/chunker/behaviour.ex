defmodule OpenphoneRecorder.Statements.Chunker.Behaviour do
  @moduledoc false
  @callback prompt_fun(atom(), binary(), keyword()) :: binary()
  @callback prompt_count(atom(), keyword()) :: integer
end
