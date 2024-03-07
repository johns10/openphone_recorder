defmodule Discussit.Files do
  def handle_user_upload(_, %{client_name: name}) do
    type = MIME.from_path(name)
    key = "/meetings/#{UUID.uuid5(:url, name)}"
    bucket = Application.get_env(:discussit, :bucket)

    {:ok,
     %{
       metadata: %{name: name, type: type},
       bucket: bucket,
       key: key
     }}
  end
end
