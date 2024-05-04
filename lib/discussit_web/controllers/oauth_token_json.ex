defmodule DiscussitWeb.OAuthTokenJSON do
  def show(%{
        access_token: token,
        expires_in: 7200,
        token_type: "bearer"
      }),
      do: %{
        access_token: token,
        expires_in: 7200,
        token_type: "bearer"
      }
end
