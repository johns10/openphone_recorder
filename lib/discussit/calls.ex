defmodule Discussit.Calls do
  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Calls.Call
  alias Discussit.Files.File

  def list_calls(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    preloads = Keyword.get(opts, :preloads, [])

    Call
    |> preload(^preloads)
    |> maybe_filter_by_conversation_id(filters[:conversation_id])
    |> maybe_filter_by_status(filters[:status])
    |> Repo.all()
  end

  def calls_status(%{conversation_id: conversation_id}) do
    Call
    |> where([c], c.conversation_id == ^conversation_id)
    |> group_by([c], c.status)
    |> select([c], %{status: c.status, count: count(c.status)})
    |> Repo.all()
  end

  defp maybe_filter_by_conversation_id(query, nil), do: query

  defp maybe_filter_by_conversation_id(query, conversation_id) do
    query
    |> where([p], p.conversation_id == ^conversation_id)
  end

  defp maybe_filter_by_status(query, nil), do: query

  defp maybe_filter_by_status(query, status) do
    query
    |> where([p], p.status == ^status)
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
    |> Call.update_changeset(attrs)
    |> Repo.update()
  end

  def update_call_recording(%Call{call_recording: nil} = call, attrs) do
    call
    |> Call.update_changeset(attrs)
    |> Repo.update()
  end

  def update_call_recording(
        %Call{call_recording: call_recording} = call,
        %{call_recording: %{metadata: metadata} = call_recording_attrs}
      ) do
    metadata_attrs =
      Map.new(metadata, fn
        {k, v} when is_binary(k) -> {k, v}
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      end)

    call_recording
    |> File.changeset(%{call_recording_attrs | metadata: metadata_attrs})
    |> case do
      %{changes: changes} when changes == %{} -> {:ok, call}
      _changed -> {:error, "Cannot change call recording"}
    end
  end

  def update_call_recording(%Call{} = call, %{status: :upload_empty}),
    do: update_call(call, %{status: :upload_empty})

  def update_voicemail(%Call{voicemail: nil} = call, attrs) do
    call
    |> Call.update_changeset(attrs)
    |> Repo.update()
  end

  def update_voicemail(
        %Call{voicemail: voicemail} = call,
        %{voicemail: %{metadata: metadata} = voicemail_attrs}
      ) do
    metadata_attrs =
      Map.new(metadata, fn
        {k, v} when is_binary(k) -> {k, v}
        {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      end)

    voicemail
    |> File.changeset(%{voicemail_attrs | metadata: metadata_attrs})
    |> case do
      %{changes: changes} when changes == %{} -> {:ok, call}
      _changed -> {:error, "Cannot change call recording"}
    end
  end

  def delete_call(%Call{} = call) do
    Repo.delete(call)
  end

  def change_call(%Call{} = call, attrs \\ %{}) do
    Call.changeset(call, attrs)
  end
end
