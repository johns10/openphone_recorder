defmodule Discussit.StubHTTP do
  @behaviour Discussit.HTTP.Behaviour

  @impl true
  def start(), do: :ok

  @impl true
  def get(_, _, _), do: {:ok, %{status_code: 200, body: ""}}

  @impl true
  def post(_, _, _, _), do: {:ok, %{status_code: 200, body: ""}}

  @impl true
  def put(_, _, _, _), do: {:ok, %{status_code: 200, body: ""}}

  @impl true
  def delete(_, _, _), do: {:ok, %{status_code: 204, body: ""}}
end
