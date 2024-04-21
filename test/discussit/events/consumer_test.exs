defmodule Discussit.Consumer do
  use ExUnit.Case, async: true
  use Discussit.DataCase
  import Discussit.EventsFixtures
  import Discussit.OpenphoneFixtures
  alias Discussit.Events.Consumer

  describe "Consumer" do
    test "consumes" do
      event_fixture(%{payload: message_received()})
      Consumer.consume()
      assert [%{processed: true}] = Discussit.Events.list_events()
    end

    test "consumes 2" do
      event_fixture(%{payload: message_received()})
      event_fixture(%{payload: message_received()})

      Consumer.consume_all()
      [%{processed: true}, %{processed: true}] = Discussit.Events.list_events()
    end
  end
end
