defmodule DiscussitWeb.TranscriptionJSON do
  def show(args) do
    %{data: data(args)}
  end

  defp data(_) do
    %{}
  end
end
