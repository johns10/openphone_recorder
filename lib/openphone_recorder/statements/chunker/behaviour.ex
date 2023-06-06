defmodule OpenphoneRecorder.Statements.Chunker.Behaviour do
  @moduledoc false
  @callback prompt_fun(atom()) :: fun(binary())
end
