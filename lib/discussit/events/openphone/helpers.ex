defmodule Discussit.Events.Openphone.Helpers do
  import Ecto.Changeset
  alias Discussit.Events.Openphone.Data.Call
  alias Discussit.Events.Openphone.Data.Message
  alias Discussit.Events.Openphone.Data.Contact

  alias Discussit.Events.Openphone.CallCompleted
  alias Discussit.Events.Openphone.CallRinging
  alias Discussit.Events.Openphone.CallRecordingCompleted

  alias Discussit.Events.Openphone.MessageReceived
  alias Discussit.Events.Openphone.MessageDelivered

  alias Discussit.Events.Openphone.ContactUpdated
  alias Discussit.Events.Openphone.ContactDeleted

  @call_schemas [
    CallCompleted,
    CallRinging,
    CallRecordingCompleted
  ]

  @message_schemas [
    MessageReceived,
    MessageDelivered
  ]

  @contact_schemas [
    ContactUpdated,
    ContactDeleted
  ]

  def cast_module_name("call.completed"), do: CallCompleted
  def cast_module_name("call.ringing"), do: CallRinging
  def cast_module_name("call.recording.completed"), do: CallRecordingCompleted

  def cast_module_name("message.delivered"), do: MessageDelivered
  def cast_module_name("message.received"), do: MessageReceived

  def cast_module_name("contact.updated"), do: ContactUpdated
  def cast_module_name("contact.deleted"), do: ContactDeleted

  def changeset(event, params \\ %{})

  def changeset(%schema{} = event, params) when schema in @call_schemas do
    event
    |> cast(params, [:id, :object, :api_version, :created_at])
    |> cast_embed(:data, with: &Call.changeset/2)
    |> ensure_created_at()
    |> validate_required([:id, :object, :api_version, :created_at])
  end

  def changeset(%schema{} = event, params) when schema in @message_schemas do
    event
    |> cast(params, [:id, :object, :api_version, :created_at])
    |> cast_embed(:data, with: &Message.changeset/2)
    |> ensure_created_at()
    |> validate_required([:id, :object, :api_version, :created_at])
  end

  def changeset(%schema{} = event, params) when schema in @contact_schemas do
    event
    |> cast(params, [:id, :object, :api_version, :created_at])
    |> cast_embed(:data, with: &Contact.changeset/2)
    |> ensure_created_at()
    |> validate_required([:id, :object, :api_version, :created_at])
  end

  def snake_cased_map_keys(map) when is_map(map) do
    for {key, val} <- map, into: %{} do
      {Inflex.underscore(key), snake_cased_map_keys(val)}
    end
  end

  def snake_cased_map_keys(val), do: val

  def rehome_data(%{"data" => %{"object" => data}} = attrs) do
    attrs
    |> Map.delete("data")
    |> Map.put("data", data)
  end

  def ensure_created_at(changeset) do
    case get_change(changeset, :created_at, nil) do
      nil -> put_change(changeset, :created_at, NaiveDateTime.utc_now())
      _ -> changeset
    end
  end
end
