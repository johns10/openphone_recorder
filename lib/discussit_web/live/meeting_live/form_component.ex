defmodule DiscussitWeb.MeetingLive.FormComponent do
  alias Discussit.Files
  use DiscussitWeb, :live_component

  alias Discussit.Meetings
  alias Discussit.Meetings.Meeting

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage meeting records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="meeting-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:user_id]} type="hidden" value={@current_user.id} />
        <.input field={@form[:source]} type="hidden" value={:user} />
        <.input field={@form[:upload_status]} type="hidden" value={:files_uploaded} />
        <.input field={@form[:projector_status]} type="hidden" value={:not_started} />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:occurred_at]} type="datetime-local" label="Occurred At" />
        <section phx-drop-target={@uploads.files.ref} class="border-dashed">
          <%= for entry <- @uploads.files.entries do %>
            <article class="upload-entry">
              <%= entry.client_name %>

              <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                aria-label="cancel"
              >
                &times;
              </button>
              <%= for err <- upload_errors(@uploads.files, entry) do %>
                <p class="alert alert-danger"><%= error_to_string(err) %></p>
              <% end %>
            </article>
          <% end %>
          <%= for err <- upload_errors(@uploads.files) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
          <div class="flex items-center justify-center w-full" id="ffmpeg-wrapper">
            <label class="flex flex-col items-center justify-center w-full h-64 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 dark:hover:bg-bray-800 dark:bg-gray-700 hover:bg-gray-100 dark:border-gray-600 dark:hover:border-gray-500 dark:hover:bg-gray-600">
              <div class="flex flex-col items-center justify-center pt-5 pb-6">
                <.icon name="hero-cloud-arrow-up" class="w-12 h-12" />
                <p class="mb-2 text-sm text-gray-500 dark:text-gray-400">
                  <span class="font-semibold">Click to upload</span> or drag and drop
                </p>
                <p class="text-xs text-gray-500 dark:text-gray-400">
                  M4A or MP4 (MAX. 500MB)
                </p>
              </div>
              <.live_file_input data-file="meeting" class="hidden" upload={@uploads.files} />
            </label>
          </div>
        </section>
        <:actions>
          <.button phx-disable-with="Saving...">Save Meeting</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{meeting: meeting} = assigns, socket) do
    changeset = Meetings.change_meeting(meeting)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:uploaded_files, [])
     |> allow_upload(:files,
       accept: ~w(.m4a .mp4),
       max_entries: 5,
       max_file_size: 10_000_000_000,
       external: &presign_upload/2
     )}
  end

  @impl true
  def handle_event("validate", %{"meeting" => meeting_params}, socket) do
    changeset =
      socket.assigns.meeting
      |> Meetings.change_meeting(meeting_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"meeting" => meeting_params}, socket) do
    save_meeting(socket, socket.assigns.action, meeting_params)
  end

  defp save_meeting(socket, :edit, meeting_params) do
    case Meetings.update_meeting(socket.assigns.meeting, meeting_params) do
      {:ok, meeting} ->
        notify_parent({:saved, meeting})

        {:noreply,
         socket
         |> put_flash(:info, "Meeting updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_meeting(socket, :new, meeting_params) do
    files = consume_uploaded_entries(socket, :files, &Files.handle_user_upload/2)
    params = Map.put(meeting_params, "files", files)

    case Meetings.create_meeting(params) do
      {:ok, meeting} ->
        notify_parent({:saved, meeting})
        handle_videos(meeting, socket.assigns.current_user.selected_account_id)

        {:noreply,
         socket
         |> put_flash(:info, "Meeting created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp presign_upload(%{client_name: name}, socket) do
    bucket = Application.get_env(:discussit, :bucket)
    key = "/meetings/#{UUID.uuid5(:url, name)}"

    {:ok, url} =
      ExAws.Config.new(:s3)
      |> ExAws.S3.presigned_url(:put, bucket, key)

    {:ok, %{uploader: "S3", endpoint: url}, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:external_client_failure), do: "Upload failed"
  defp error_to_string(other), do: to_string(other)

  defp handle_videos(%Meeting{files: []}, _account_id), do: nil

  defp handle_videos(%Meeting{files: files, id: id}, account_id) do
    Enum.filter(files, &(&1.metadata.type == "video/mp4"))
    |> case do
      [] ->
        nil

      _videos ->
        %{
          "meeting_id" => id,
          "account_id" => account_id
        }
        |> Discussit.Files.ConvertVideoTask.new()
        |> Oban.insert()
    end
  end
end
