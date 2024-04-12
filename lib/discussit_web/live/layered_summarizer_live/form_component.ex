defmodule DiscussitWeb.LayeredSummarizerLive.FormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.LayeredSummarizers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage layered_summarizer records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="layered_summarizer-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:account_id]} type="hidden" value={@account_id} />
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Layered summarizer</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{layered_summarizer: layered_summarizer} = assigns, socket) do
    changeset = LayeredSummarizers.change_layered_summarizer(layered_summarizer)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"layered_summarizer" => layered_summarizer_params}, socket) do
    changeset =
      socket.assigns.layered_summarizer
      |> LayeredSummarizers.change_layered_summarizer(layered_summarizer_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"layered_summarizer" => layered_summarizer_params}, socket) do
    save_layered_summarizer(socket, socket.assigns.action, layered_summarizer_params)
  end

  defp save_layered_summarizer(socket, :edit, layered_summarizer_params) do
    case LayeredSummarizers.update_layered_summarizer(
           socket.assigns.layered_summarizer,
           layered_summarizer_params
         ) do
      {:ok, layered_summarizer} ->
        notify_parent({:saved, layered_summarizer})

        {:noreply,
         socket
         |> put_flash(:info, "Layered summarizer updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_layered_summarizer(socket, :new, layered_summarizer_params) do
    case LayeredSummarizers.create_layered_summarizer(layered_summarizer_params) do
      {:ok, layered_summarizer} ->
        notify_parent({:saved, layered_summarizer})

        {:noreply,
         socket
         |> put_flash(:info, "Layered summarizer created successfully")
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
