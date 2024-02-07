defmodule Discussit.Config do
  def ex_aws_s3_config() do
    case Application.get_env(:discussit, :use_ngrok, false) do
      false ->
        ExAws.Config.new(:s3)

      true ->
        host = Application.get_env(:discussit, :ngrok_host)

        ExAws.Config.new(:s3)
        |> Map.put(:host, host)
        |> Map.put(:port, nil)
    end
  end

  def public_url() do
    case Application.get_env(:discussit, :use_ngrok, false) do
      false -> DiscussitWeb.Endpoint.static_url()
      true -> "https://#{Application.get_env(:discussit, :ngrok_host)}"
    end
  end
end
