defmodule DiscussitWeb.MeetingLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Meetings
  alias Discussit.Meetings.Meeting

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :meetings, Meetings.list_meetings())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Meetings")
    |> assign(:meeting, nil)
  end

  @impl true
  def handle_info({DiscussitWeb.MeetingLive.FormComponent, {:saved, meeting}}, socket) do
    {:noreply, stream_insert(socket, :meetings, meeting)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting = Meetings.get_meeting!(id)
    {:ok, _} = Meetings.delete_meeting(meeting)

    {:noreply, stream_delete(socket, :meetings, meeting)}
  end

  @impl true
  def handle_event("create-meeting", %{"name" => name, "files" => files} = attrs, socket) do
    [date_string, time_string | rest] = String.split(name, " ")
    {:ok, date} = Date.from_iso8601(date_string)
    {:ok, time} = time_string |> String.replace(".", ":") |> Time.from_iso8601()
    {:ok, occurred_at} = NaiveDateTime.new(date, time)
    name = Enum.join(rest, " ")
    bucket = Application.get_env(:discussit, :bucket)

    file_attrs =
      Enum.map(files, fn %{"name" => name, "key" => key} ->
        {:ok, url} =
          ExAws.Config.new(:s3)
          |> ExAws.S3.presigned_url(:put, bucket, "/meetings/#{key}")

        %{
          metadata: %{name: name, type: MIME.from_path(name)},
          bucket: bucket,
          key: key,
          url: url
        }
      end)

    attrs
    |> Map.put("name", name)
    |> Map.put("occurred_at", occurred_at)
    |> Map.put("files", file_attrs)
    |> Map.put("user_id", socket.assigns.current_user.id)
    |> IO.inspect()
    |> Meetings.create_meeting()
    |> case do
      {:ok, meeting} ->
        {:noreply,
         socket |> stream_insert(:meetings, meeting) |> push_event("meeting-created", meeting)}

      {:error, %{errors: [name: {"has already been taken", [{:constraint, :unique} | _]}]}} ->
        {:noreply, socket}

      {:error, changeset} ->
        IO.inspect(changeset)
        {:noreply, put_flash(socket, :error, "Failed to create meeting")}
    end
  end

  def handle_event("meeting-uploading", %{"id" => id}, socket) do
    {:ok, meeting} =
      id
      |> Meetings.get_meeting!()
      |> Meetings.update_meeting(%{upload_status: :files_uploading})

    {:noreply, socket |> stream_insert(:meetings, meeting)}
  end

  def handle_event("meeting-uploaded", %{"id" => id}, socket) do
    {:ok, meeting} =
      id
      |> Meetings.get_meeting!()
      |> Meetings.update_meeting(%{upload_status: :files_uploaded})

    {:noreply, socket |> stream_insert(:meetings, meeting)}
  end
end
