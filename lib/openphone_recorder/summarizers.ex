defmodule OpenphoneRecorder.Summarizers do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Summarizers.Summarizer

  def list_summarizers do
    Repo.all(Summarizer)
  end

  def get_summarizer!(id), do: Repo.get!(Summarizer, id)

  def create_summarizer(attrs \\ %{}) do
    %Summarizer{}
    |> Summarizer.changeset(attrs)
    |> Repo.insert()
  end

  def update_summarizer(%Summarizer{} = summarizer, attrs) do
    summarizer
    |> Summarizer.changeset(attrs)
    |> Repo.update()
  end

  def delete_summarizer(%Summarizer{} = summarizer) do
    Repo.delete(summarizer)
  end

  def change_summarizer(%Summarizer{} = summarizer, attrs \\ %{}) do
    Summarizer.changeset(summarizer, attrs)
  end
end
