defmodule Discussit.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Users` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      name: Faker.Person.name()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Discussit.Users.register_user()

    user
  end

  def administrator_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Map.merge(%{email: "johns10@gmail.com"})
      |> valid_user_attributes()
      |> Discussit.Users.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
