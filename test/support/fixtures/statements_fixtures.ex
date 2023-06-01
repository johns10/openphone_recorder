defmodule OpenphoneRecorder.StatementsFixtures do
  import OpenphoneRecorder.ParticipantsFixtures

  def statement_fixture(attrs \\ %{}) do
    {:ok, statement} =
      attrs
      |> Enum.into(%{
        external_id: Ecto.UUID.generate(),
        source: :openphone,
        content: "some content",
        occurred_at: ~U[2023-03-28 10:21:00Z],
        type: :call,
        participant_id: participant_fixture() |> Map.get(:id)
      })
      |> OpenphoneRecorder.Statements.create_statement()

    statement
  end
end
