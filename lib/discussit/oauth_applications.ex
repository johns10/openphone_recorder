defmodule Discussit.OauthApplications do
  alias Discussit.OauthApplications.OauthApplication
  alias Insurance.Repo

  def get_oauth_application_by(filters \\ []) do
    OauthApplication
    |> Repo.get_by(filters)
  end
end
