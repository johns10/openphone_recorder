defmodule DiscussitWeb.SummarizerLive.FormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.Summarizers

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
        <.input field={@form[:account_id]} type="hidden" value={@current_user.selected_account_id} />
        <.input field={@form[:name]} type="text" label="Name" />
        <.input phx-hook="MaintainAttrs" field={@form[:prompt]} type="textarea" label="Prompt" />
        <.input
          phx-hook="MaintainAttrs"
          field={@form[:reducer_prompt]}
          type="textarea"
          label="Reducer Prompt"
        />
        <.input
          field={@form[:chunker]}
          type="select"
          label="Chunker"
          options={Ecto.Enum.values(Discussit.Summarizers.Summarizer, :chunker)}
        />
        <label class="flex items-center gap-4 text-sm leading-6 ">
          <%= "Reduce Text Length To #{cast_reduction(@form[:reduction_mode].value, @form[:percentage_reduction].value, @form[:fixed_reduction].value)}" %>
        </label>
        <div class="flex flex-row items-center">
          <div phx-feedback-for={@form[:reduction_mode].name}>
            <select
              name={@form[:reduction_mode].name}
              id={@form[:reduction_mode].id}
              type="select"
              class="select select-bordered w-full join-item"
            >
              <%= Phoenix.HTML.Form.options_for_select(
                Ecto.Enum.values(Discussit.Summarizers.Summarizer, :reduction_mode),
                @form[:reduction_mode].value || :percentage
              ) %>
            </select>
          </div>
          <input
            :if={
              @form[:reduction_mode].value == :percentage ||
                @form[:reduction_mode].value == "percentage" || !@form[:reduction_mode].value
            }
            name={@form[:percentage_reduction].name}
            id={@form[:percentage_reduction].id}
            value={@form[:percentage_reduction].value}
            type="range"
            min="0.01"
            max="1"
            step="0.01"
            class="range range-lg mx-4"
          />
          <input
            :if={@form[:reduction_mode].value == :fixed || @form[:reduction_mode].value == "fixed"}
            name={@form[:fixed_reduction].name}
            id={@form[:fixed_reduction].id}
            value={@form[:fixed_reduction].value}
            class={[
              "input input-bordered w-full mx-4",
              @form[:fixed_reduction].errors != [] && "border-error"
            ]}
            type="number"
          />
        </div>
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

    reduction_mode =
      case summarizer do
        %{fixed_reduction: nil} -> :percentage
        %{percentage_reduction: nil} -> :fixed
        _ -> nil
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> assign(:reduction_mode, reduction_mode)}
  end

  @impl true
  def handle_event("percentage", _, socket) do
    changeset =
      socket.assigns.summarizer
      |> Summarizers.change_summarizer(%{fixed_reduction: nil})
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset) |> assign(:reduction_mode, :percentage)}
  end

  def handle_event("fixed", _, socket) do
    changeset =
      socket.assigns.summarizer
      |> Summarizers.change_summarizer(%{percentage_reduction: nil})
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset) |> assign(:reduction_mode, :fixed)}
  end

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

  defp cast_reduction("fixed", _, fixed), do: "#{fixed} tokens"
  defp cast_reduction(:fixed, _, fixed), do: "#{fixed} tokens"
  defp cast_reduction("percentage", nil, _), do: "50 %"
  defp cast_reduction(:percentage, nil, _), do: "50 %"
  defp cast_reduction(:percentage, percentage, _), do: cast_percent(percentage)
  defp cast_reduction("percentage", percentage, _), do: cast_percent(percentage)
  defp cast_reduction(_, _, _), do: ""

  defp cast_percent(""), do: "0%"

  defp cast_percent(percentage) when is_binary(percentage),
    do: percentage |> String.to_float() |> cast_percent()

  defp cast_percent(percentage) when is_float(percentage), do: "#{floor(percentage * 100)} %"
end
