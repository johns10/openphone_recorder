defmodule Discussit.Chunker.Behaviour do
  @moduledoc false
  @callback chunk_items(map(), keyword()) :: map() | list()
end
