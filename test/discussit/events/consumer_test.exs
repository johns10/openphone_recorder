defmodule Discussit.Consumer do
  use ExUnit.Case, async: true
  use Discussit.DataCase
  import Discussit.EventsFixtures
  import Discussit.OpenphoneFixtures
  alias Discussit.Events
  alias Discussit.Events.Consumer

  @default_timeout 5000

  describe "Consumer" do
    setup do
      attrs = %{subscribed: [self()], name: Ecto.UUID.generate() |> String.to_atom()}
      consumer = start_supervised!({Consumer, attrs})
      Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), consumer)
      %{consumer: consumer}
    end

    test "set_count", %{consumer: consumer} do
      assert 1 == GenServer.call(consumer, {:set_count, 1})
    end

    test "consumes", %{consumer: consumer} do
      %{id: id} = event = event_fixture(%{payload: message_received()})
      GenServer.call(consumer, {:set_count, 1})
      GenServer.cast(consumer, {:start})
      assert_receive({:consumed, %{id: ^id}}, @default_timeout)
      assert %{processed: true} = Events.get_event!(event.id)
    end

    test "consumes 2", %{consumer: consumer} do
      %{id: id1} = event_fixture(%{payload: message_received()})
      %{id: id2} = event_fixture(%{payload: message_received()})
      GenServer.call(consumer, {:set_count, 2})
      GenServer.cast(consumer, {:start})
      assert_receive({:consumed, %{id: ^id1}}, @default_timeout)
      assert_receive({:consumed, %{id: ^id2}}, @default_timeout)
    end

    test "consumes inf", %{consumer: consumer} do
      %{id: id1} = event_fixture(%{payload: message_received()})
      %{id: id2} = event_fixture(%{payload: message_received()})
      GenServer.call(consumer, {:set_count, :inf})
      GenServer.cast(consumer, {:start})
      assert_receive({:consumed, %{id: ^id1}}, @default_timeout)
      assert_receive({:consumed, %{id: ^id2}}, @default_timeout)
    end

    test "start works", %{consumer: consumer} do
      %{id: id1} = event_fixture(%{payload: message_received()})
      %{id: id2} = event_fixture(%{payload: message_received()})
      GenServer.call(consumer, {:set_count, :inf})
      GenServer.cast(consumer, {:start})
      assert_receive({:consumed, %{id: ^id1}}, @default_timeout)
      assert_receive({:consumed, %{id: ^id2}}, @default_timeout)
    end

    test "schedules", %{consumer: consumer} do
      GenServer.call(consumer, {:set_count, :inf})
      event_fixture(%{payload: message_received()})
      refute_receive({:consumed, _event})
    end
  end
end
