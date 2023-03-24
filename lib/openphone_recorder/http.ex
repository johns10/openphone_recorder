defmodule OpenphoneRecorder.HTTP do
  @behaviour OpenphoneRecorder.HTTP.Behaviour

  def provider(), do: Application.get_env(:openphone_recorder, :http_provider, HTTPoison)

  @impl true
  def start(), do: provider().start()

  @impl true
  def get(url, headers \\ [], options \\ []), do: provider().get(url, headers, options)

  @impl true
  def put(url, body \\ "", headers \\ [], options \\ []),
    do: provider().put(url, body, headers, options)

  @impl true
  def post(url, body \\ "", headers \\ [], options \\ []),
    do: provider().post(url, body, headers, options)

  @impl true
  def delete(url, headers \\ [], options \\ []), do: provider().delete(url, headers, options)
end
