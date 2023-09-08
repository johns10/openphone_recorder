defmodule Discussit.Meetings do
  @moduledoc """
  The Meetings context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Meetings.Meeting

  def list_meetings do
    Meeting
    |> select([s], ^only())
    |> Repo.all()
  end

  def get_meeting!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    Meeting
    |> preload(^preload)
    |> select([s], ^only())
    |> Repo.get!(id)
  end

  def create_meeting(attrs \\ %{}) do
    %Meeting{}
    |> Meeting.changeset(attrs)
    |> Repo.insert()
  end

  def update_meeting(%Meeting{} = meeting, attrs) do
    meeting
    |> Meeting.changeset(attrs)
    |> Repo.update()
  end

  def delete_meeting(%Meeting{} = meeting) do
    Repo.delete(meeting)
  end

  def change_meeting(%Meeting{} = meeting, attrs \\ %{}) do
    Meeting.changeset(meeting, attrs)
  end

  def only(), do: Meeting.__schema__(:fields) -- [:segments]
end
