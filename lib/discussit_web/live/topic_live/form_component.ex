defmodule DiscussitWeb.TopicLive.FormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.Topics

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage topic records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="topic-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:summary]} type="text" label="Summary" />
        <.input field={@form[:sentiment]} type="number" label="Sentiment" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Topic</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{topic: topic} = assigns, socket) do
    changeset = Topics.change_topic(topic)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"topic" => topic_params}, socket) do
    changeset =
      socket.assigns.topic
      |> Topics.change_topic(topic_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"topic" => topic_params}, socket) do
    save_topic(socket, socket.assigns.action, topic_params)
  end

  defp save_topic(socket, :edit, topic_params) do
    case Topics.update_topic(socket.assigns.topic, topic_params) do
      {:ok, topic} ->
        notify_parent({:saved, topic})

        {:noreply,
         socket
         |> put_flash(:info, "Topic updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_topic(socket, :new, topic_params) do
    case Topics.create_topic(topic_params) do
      {:ok, topic} ->
        notify_parent({:saved, topic})

        {:noreply,
         socket
         |> put_flash(:info, "Topic created successfully")
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
