defmodule OpenphoneRecorder.Consumer do
  use ExUnit.Case, async: true
  use OpenphoneRecorder.DataCase
  import OpenphoneRecorder.EventsFixtures
  import OpenphoneRecorder.OpenphoneFixtures
  alias OpenphoneRecorder.Events
  alias OpenphoneRecorder.Events.Consumer

  @default_timeout 200

  describe "Consumer" do
    setup do
      attrs = %{delay: 1000, subscribed: [self()], name: Ecto.UUID.generate() |> String.to_atom()}
      consumer = start_supervised!({Consumer, attrs})

      Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), consumer)
      %{consumer: consumer}
    end

    test "set_count", %{consumer: consumer} do
      assert 1 == GenServer.call(consumer, {:set_count, 1})
    end

    test "consumes", %{consumer: consumer} do
      event = event_fixture(%{payload: message_received()})
      GenServer.call(consumer, {:set_count, 1})
      assert_receive({:consumed, updated_event}, @default_timeout)
      assert event.id == updated_event.id
      assert %{processed: true} = Events.get_event!(event.id)
    end

    test "consumes 2", %{consumer: consumer} do
      event_1 = event_fixture(%{payload: message_received()})
      event_2 = event_fixture(%{payload: message_received()})
      GenServer.call(consumer, {:set_count, 2})
      assert_receive({:consumed, updated_event_1}, @default_timeout)
      assert_receive({:consumed, updated_event_2}, @default_timeout)
      assert event_1.id == updated_event_1.id
      assert event_2.id == updated_event_2.id
    end

    test "consumes inf", %{consumer: consumer} do
      event_1 = event_fixture(%{payload: message_received()})
      event_2 = event_fixture(%{payload: message_received()})
      GenServer.call(consumer, {:set_count, :inf})
      assert_receive({:consumed, updated_event_1}, @default_timeout)
      assert_receive({:consumed, updated_event_2}, @default_timeout)
      assert event_1.id == updated_event_1.id
      assert event_2.id == updated_event_2.id
    end

    test "schedules", %{consumer: consumer} do
      GenServer.call(consumer, {:set_count, :inf})
      GenServer.call(consumer, {:set_delay, 2000})
      event_fixture(%{payload: message_received()})
      refute_receive({:consumed, _event})
    end
  end
end
