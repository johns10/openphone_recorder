defmodule Discussit.Config do
  def ex_aws_s3_config() do
    case Application.get_env(:discussit, :ngrok_host, nil) do
      nil ->
        ExAws.Config.new(:s3)

      host ->
        ExAws.Config.new(:s3)
        |> Map.put(:host, host)
        |> Map.put(:port, nil)
    end
  end
end
