defmodule OpenphoneRecorderWeb.SummarizerLive.FormComponent do
  use OpenphoneRecorderWeb, :live_component

  alias OpenphoneRecorder.Summarizers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage summarizer records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="summarizer-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:prompt]} type="text" label="Prompt" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Summarizer</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{summarizer: summarizer} = assigns, socket) do
    changeset = Summarizers.change_summarizer(summarizer)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"summarizer" => summarizer_params}, socket) do
    changeset =
      socket.assigns.summarizer
      |> Summarizers.change_summarizer(summarizer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"summarizer" => summarizer_params}, socket) do
    save_summarizer(socket, socket.assigns.action, summarizer_params)
  end

  defp save_summarizer(socket, :edit, summarizer_params) do
    case Summarizers.update_summarizer(socket.assigns.summarizer, summarizer_params) do
      {:ok, summarizer} ->
        notify_parent({:saved, summarizer})

        {:noreply,
         socket
         |> put_flash(:info, "Summarizer updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_summarizer(socket, :new, summarizer_params) do
    case Summarizers.create_summarizer(summarizer_params) do
      {:ok, summarizer} ->
        notify_parent({:saved, summarizer})

        {:noreply,
         socket
         |> put_flash(:info, "Summarizer created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
