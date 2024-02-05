defmodule Discussit.Meetings do
  @moduledoc """
  The Meetings context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Meetings.Meeting

  def authorize(:get_meeting!, %{id: user_id}, %{user_id: user_id}), do: :ok
  def authorize(:get_meeting!, _user, _meeting), do: :error

  def list_meetings(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    offset = Keyword.get(opts, :offset, nil)
    limit = Keyword.get(opts, :limit, nil)

    Meeting
    |> maybe_filter_by_conversation_id(filters[:conversation_id])
    |> maybe_limit(limit)
    |> maybe_offset(offset)
    |> filter_by_user_id(filters[:user_id])
    |> Repo.all()
  end

  def get_meeting!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    Meeting
    |> preload(^preload)
    |> Repo.get!(id)
  end

  def get_meeting_summary!(id) do
    Meeting
    |> join(:left, [m], pn in assoc(m, :participants), as: :participant)
    |> join(:left, [participant: p], c in assoc(p, :contact), as: :contact)
    |> join(:left, [m], s in assoc(m, :statements), as: :statements)
    |> join(:left, [statements: s], p in assoc(s, :participant), as: :statement_participant)
    |> join(:left, [statement_participant: p], c in assoc(p, :contact), as: :statement_contact)
    |> order_by([statements: s], asc: s.occurred_at)
    |> preload(
      [
        participant: p,
        contact: c,
        statements: s,
        statement_participant: sp,
        statement_contact: sc
      ],
      participants: {p, contact: c},
      statements: {s, participant: {sp, contact: sc}}
    )
    |> Repo.get!(id)
  end

  defp maybe_filter_by_conversation_id(query, nil), do: query

  defp maybe_filter_by_conversation_id(query, conversation_id) do
    query
    |> where([p], p.conversation_id == ^conversation_id)
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, value), do: limit(query, ^value)
  defp maybe_offset(query, nil), do: query
  defp maybe_offset(query, limit), do: offset(query, ^limit)

  defp filter_by_user_id(query, nil), do: query

  defp filter_by_user_id(query, user_id) do
    query
    |> where([m], m.user_id == ^user_id)
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
end
