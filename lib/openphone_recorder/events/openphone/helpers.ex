defmodule OpenphoneRecorder.Events.Openphone.Helpers do
  import Ecto.Changeset
  alias OpenphoneRecorder.Events.Openphone.Data.Call
  alias OpenphoneRecorder.Events.Openphone.Data.Message
  alias OpenphoneRecorder.Events.Openphone.Data.Contact

  alias OpenphoneRecorder.Events.Openphone.CallCompleted
  alias OpenphoneRecorder.Events.Openphone.CallRinging
  alias OpenphoneRecorder.Events.Openphone.CallRecordingCompleted

  alias OpenphoneRecorder.Events.Openphone.MessageReceived
  alias OpenphoneRecorder.Events.Openphone.MessageDelivered

  alias OpenphoneRecorder.Events.Openphone.ContactCreated
  alias OpenphoneRecorder.Events.Openphone.ContactUpdated

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
    ContactCreated,
    ContactUpdated
  ]

  def cast_module_name("call.completed"), do: CallCompleted
  def cast_module_name("call.ringing"), do: CallRinging
  def cast_module_name("call.recording.completed"), do: CallRecordingCompleted

  def cast_module_name("message.delivered"), do: MessageDelivered
  def cast_module_name("message.received"), do: MessageReceived

  def cast_module_name("contact.created"), do: ContactCreated
  def cast_module_name("contact.updated"), do: ContactUpdated

  def changeset(event, params \\ %{})

  def changeset(%schema{} = event, params) when schema in @call_schemas do
    event
    |> cast(params, [:id, :object, :api_version, :created_at])
    |> cast_embed(:data, with: &Call.changeset/2)
    |> validate_required([:id, :object, :api_version, :created_at])
  end

  def changeset(%schema{} = event, params) when schema in @message_schemas do
    event
    |> cast(params, [:id, :object, :api_version, :created_at])
    |> cast_embed(:data, with: &Message.changeset/2)
    |> validate_required([:id, :object, :api_version, :created_at])
  end

  def changeset(%schema{} = event, params) when schema in @contact_schemas do
    event
    |> cast(params, [:id, :object, :api_version, :created_at])
    |> cast_embed(:data, with: &Contact.changeset/2)
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
end
