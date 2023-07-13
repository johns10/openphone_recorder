defmodule Discussit.EventsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Events` context.
  """

  @doc """
  Generate a event.
  """
  import Discussit.AccountsFixtures

  def event_fixture(attrs \\ %{}) do
    account_id = Map.get(attrs, :account_id, nil) || account_fixture().id

    {:ok, event} =
      attrs
      |> Enum.into(%{
        account_id: account_id,
        payload: %{},
        processed: false
      })
      |> Discussit.Events.create_event()

    event
  end
end
