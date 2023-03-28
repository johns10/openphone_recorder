defmodule OpenphoneRecorder.Calls do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Calls.Call

  def list_calls do
    Repo.all(Call)
  end

  def get_call!(id), do: Repo.get!(Call, id)

  def create_call(attrs \\ %{}) do
    %Call{}
    |> Call.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_call(attrs \\ %{}) do
    %Call{}
    |> Call.changeset(attrs)
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: :id,
      returning: true
    )
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
