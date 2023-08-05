defmodule Discussit.Calls do
  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Calls.Call

  def list_calls(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Call
    |> maybe_filter_by_conversation_id(filters[:conversation_id])
    |> Repo.all()
  end

  defp maybe_filter_by_conversation_id(query, nil), do: query

  defp maybe_filter_by_conversation_id(query, conversation_id) do
    query
    |> where([p], p.conversation_id == ^conversation_id)
  end

  def get_call!(id), do: Repo.get!(Call, id)

  def create_call(attrs \\ %{}) do
    %Call{}
    |> Call.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_call(attrs \\ %{}) do
    changeset =
      %Call{}
      |> Call.changeset(attrs)

    changeset
    |> Repo.insert()
    |> case do
      {:error, %{errors: [id: {"has already been taken", _}]}} ->
        call =
          changeset
          |> Ecto.Changeset.get_field(:id)
          |> get_call!()

        {:ok, call}

      success ->
        success
    end
  end

  def update_call(%Call{} = call, attrs) do
    call
    |> Call.changeset(attrs)
    |> Repo.update()
  end

  def delete_call(%Call{} = call) do
    Repo.delete(call)
  end

  def change_call(%Call{} = call, attrs \\ %{}) do
    Call.changeset(call, attrs)
  end
end
