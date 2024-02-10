defmodule DiscussitWeb.MeetingLive.Index do
  use DiscussitWeb, :live_view

  alias Discussit.Meetings
  alias Discussit.Meetings.Meeting
  alias Discussit.Transcription
  alias Discussit.Transcription.Resolver

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    DiscussitWeb.Endpoint.subscribe("user_#{user_id}")
    meetings = Meetings.list_meetings(limit: 20, filters: [user_id: user_id])
    Resolver.audit_meetings(meetings, socket.assigns.current_user.selected_account_id)

    {:ok,
     socket
     |> stream(:meetings, meetings)
     |> assign(
       per_page: 20,
       page: 1,
       end_of_timeline?: false,
       uploaded: nil,
       directories: nil
     ), layout: {DiscussitWeb.Layouts, :full_screen}}
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

  defp apply_action(socket, :show, %{"id" => id}) do
    meeting = Meetings.get_meeting!(id, preload: [participants: :contact])

    case Bodyguard.permit(Meetings, :get_meeting!, socket.assigns.current_user, meeting) do
      :ok ->
        socket
        |> assign(:page_title, "Show Meeting")
        |> assign(:meeting, meeting)

      {:error, _} ->
        socket
        |> push_redirect(to: ~p"/home")
        |> put_flash(:error, "You cannot access this meeting")
    end
  end

  @impl true

  def handle_info(%{event: "meeting_updated", payload: meeting}, socket) do
    {:noreply, stream_insert(socket, :meetings, meeting)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting = Meetings.get_meeting!(id)
    {:ok, _} = Meetings.delete_meeting(meeting)

    {:noreply, stream_delete(socket, :meetings, meeting)}
  end

  @impl true
  def handle_event("upload-started", %{"directories" => directories}, socket) do
    {:noreply, socket |> assign(:directories, directories) |> assign(:uploaded, 0)}
  end

  def handle_event("create-meeting", %{"name" => name, "files" => files} = attrs, socket) do
    [date_string, time_string | rest] = String.split(name, " ")
    {:ok, date} = Date.from_iso8601(date_string)
    {:ok, time} = time_string |> String.replace(".", ":") |> Time.from_iso8601()
    {:ok, occurred_at} = NaiveDateTime.new(date, time)
    name = Enum.join(rest, " ")
    bucket = Application.get_env(:discussit, :bucket)

    file_attrs =
      Enum.map(files, fn %{"name" => name, "key" => incoming_key} ->
        key = "/meetings/#{incoming_key}"

        {:ok, url} =
          ExAws.Config.new(:s3)
          |> ExAws.S3.presigned_url(:put, bucket, key)

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
    |> Map.put("projector_status", :not_started)
    |> Meetings.create_meeting()
    |> case do
      {:ok, meeting} ->
        {:noreply,
         socket
         |> stream_insert(:meetings, meeting)
         |> push_event("meeting-created", meeting)
         |> assign(:uploaded, socket.assigns.uploaded + 1)}

      {:error, %{errors: [name: {"has already been taken", [{:constraint, :unique} | _]}]}} ->
        {:noreply,
         socket
         |> push_event("meeting-exists", %{})
         |> assign(:directories, socket.assigns.directories - 1)}

      {:error, _changeset} ->
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

  def handle_event("transcribe", %{"id" => id}, socket) do
    with %Meeting{} = meeting <- Meetings.get_meeting!(id),
         {:ok, meeting} <- Meetings.update_meeting(meeting, %{projector_status: :in_progress}) do
      Transcription.start(meeting, account_id: socket.assigns.current_user.selected_account_id)
      {:noreply, socket |> stream_insert(:meetings, meeting)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("next-page", _, socket) do
    {:noreply, append(socket, socket.assigns.page + 1)}
  end

  defp append(socket, new_page) when new_page >= 1 do
    %{per_page: per_page} = socket.assigns
    new_page = socket.assigns.page + 1

    meetings =
      Meetings.list_meetings(
        filters: [user_id: socket.assigns.current_user.id],
        offset: (new_page - 1) * per_page,
        limit: per_page
      )

    case meetings do
      [] ->
        assign(socket, end_of_timeline?: true)

      [_ | _] = meetings ->
        socket =
          socket
          |> assign(:page, new_page)
          |> stream(:meetings, meetings, at: -1)
          |> assign(:end_of_timeline?, false)

        if Enum.count(meetings) < per_page do
          assign(socket, :end_of_timeline?, true)
        else
          socket
        end
    end
  end

  defp progress(nil, nil), do: 100
  defp progress(_, 0), do: 100
  defp progress(uploaded, directories), do: uploaded / directories * 100
end
