defmodule DiscussitWeb.TopicLive.TrainingFormComponent do
  use DiscussitWeb, :live_component

  alias DiscussitWeb.TopicLive.TrainingForm
  alias Discussit.{Statements}
  alias Discussit.TopicAnalyzer.Workers

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
              Train model on <%= @form[:statements_count].value %> of <%= @statements_counts.total %> statements
            </span>
          </label>
          <input
            id={@form[:statements_count].id}
            name={@form[:statements_count].name}
            value={@statements_counts.labelled}
            type="range"
            min="0"
            max={@statements_counts.unlabelled}
            class="range"
            phx-debounce="500"
          />
        </div>
        <div class="relative text-xs">
          <div class="overflow-hidden h-4 text-xs flex rounded">
            <div
              style={"width: #{labelled_percentage(@statements_counts)}%"}
              class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-primary"
            >
            </div>
            <div
              style={"width: #{unlabelled_percentage(@statements_counts)}%"}
              class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-secondary"
            >
            </div>
          </div>
        </div>
        <div class="badge badge-primary">Labelled</div>
        <div class="badge badge-secondary">Unlabelled</div>
        <:actions>
          <.button phx-disable-with="Training...">Train</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{model_id: model_id, account_id: account_id} = assigns, socket) do
    statements_counts = statement_counts(account_id)
    training_form = %TrainingForm{statements_count: statements_counts.labelled}
    changeset = TrainingForm.changeset(training_form, %{model_id: model_id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:statements_counts, statements_counts)
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

  defp statement_counts(account_id),
    do: %{
      labelled:
        Statements.list_statements(
          filters: [
            account_id: account_id,
            all_stopwords: false,
            unprocessable: false,
            labelled: true,
            trained: false
          ],
          count: true
        ),
      unlabelled:
        Statements.list_statements(
          filters: [
            account_id: account_id,
            all_stopwords: false,
            unprocessable: false,
            trained: false,
            labelled: false
          ],
          count: true
        ),
      total:
        Statements.list_statements(
          filters: [
            account_id: account_id,
            all_stopwords: false,
            unprocessable: false,
            trained: false
          ],
          count: true
        )
    }

  defp labelled_percentage(%{labelled: _labelled, unlabelled: 0}), do: 0

  defp labelled_percentage(%{labelled: labelled, unlabelled: unlabelled}),
    do: labelled / unlabelled * 100

  defp unlabelled_percentage(%{labelled: _labelled, unlabelled: 0}), do: 0

  defp unlabelled_percentage(%{labelled: labelled, unlabelled: unlabelled}),
    do: (1 - labelled / unlabelled) * 100

  defp submit_form(socket, _params) do
    %{account_id: socket.assigns.current_user.selected_account.id}
    |> Workers.Initialization.new()
    |> Oban.insert()

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
