defmodule OpenphoneRecorder.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OpenphoneRecorder.Events` context.
  """

  @doc """
  Generate a event.
  """
  import OpenphoneRecorder.AccountsFixtures

  def event_fixture(attrs \\ %{}) do
    account_id = Map.get(attrs, :account_id, nil) || account_fixture().id

    {:ok, event} =
      attrs
      |> Enum.into(%{
        account_id: account_id,
        payload: %{},
        processed: false
      })
      |> OpenphoneRecorder.Events.create_event()

    event
  end
end
