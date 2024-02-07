defmodule DiscussitWeb.TranscriptionJSON do
  alias Discussit.Events.Event

  def show(args) do
    %{data: data(args)}
  end

  defp data(_) do
    %{}
  end
end
