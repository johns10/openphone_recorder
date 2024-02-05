defmodule Discussit.Config do
  def ex_aws_s3_config() do
    case Application.get_env(:discussit, :use_ngrok, false) do
      false ->
        ExAws.Config.new(:s3)

      true ->
        host = Ngrok.public_url(Discussit.MinioNgrok) |> String.replace("https://", "")

        ExAws.Config.new(:s3)
        |> Map.put(:host, host)
    end
  end
end
