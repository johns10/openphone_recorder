defmodule DiscussitWeb.TopicLive.TrainingFormComponent do
  use DiscussitWeb, :live_component

  alias DiscussitWeb.TopicLive.TrainingForm
  alias Discussit.{Statements}

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to start a training run on your model.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="training-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div phx-feedback-for={@form[:statements_count].name} class="form-control w-full">
          <label class="label">
            <span class="label-text">
              Train model on <%= @form[:statements_count].value %> statements
            </span>
          </label>
          <input
            id={@form[:statements_count].id}
            name={@form[:statements_count].name}
            value={@form[:statements_count].value}
            type="range"
            min="0"
            max={@statements_count}
            class="range"
            phx-debounce="500"
          />
          <div class="w-full flex justify-between text-xs px-2">
            <span>|</span>
            <span>|</span>
            <span>|</span>
            <span>|</span>
            <span>|</span>
          </div>
        </div>
        <:actions>
          <.button phx-disable-with="Training...">Train</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{model_id: model_id, account_id: account_id} = assigns, socket) do
    training_form = %TrainingForm{statements_count: 0}
    changeset = TrainingForm.changeset(training_form, %{model_id: model_id})
    statements_count = Statements.list_statements(filters: [account_id: account_id], count: true)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:statements_count, statements_count)
     |> assign(:training_form, training_form)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"training_form" => topic_params}, socket) do
    changeset =
      socket.assigns.training_form
      |> TrainingForm.changeset(topic_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"training_form" => params}, socket) do
    submit_form(socket, params)
  end

  defp submit_form(socket, params) do
    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
