defmodule Discussit.UsagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Usages` context.
  """

  @doc """
  Generate a usage.
  """
  def usage_fixture(attrs \\ %{}) do
    {:ok, usage} =
      attrs
      |> Enum.into(%{
        meta: %{},
        model: :"gpt-3.5-turbo",
        product: :chat_completions,
        provider: :openai,
        total: 120.5,
        account_id: Discussit.AccountsFixtures.account_fixture().id
      })
      |> Discussit.Usages.create_usage()

    usage
  end
end
