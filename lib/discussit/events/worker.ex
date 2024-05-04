defmodule Discussit.Events.Worker do
  use Oban.Worker, queue: :events
  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Discussit.Events.Consumer.consume_all()

    :ok
  end
end
