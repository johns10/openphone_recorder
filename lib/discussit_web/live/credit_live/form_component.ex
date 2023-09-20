defmodule DiscussitWeb.CreditLive.FormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.Credits

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage credit records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="credit-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:account_id]} type="hidden" value={@current_user.selected_account_id} />
        <.input field={@form[:product_id]} type="text" label="Product" />
        <.input field={@form[:quantity]} type="number" label="Quantity" step="any" />
        <.input field={@form[:purchased_at]} type="hidden" value={NaiveDateTime.utc_now()} />
        <:actions>
          <.button phx-disable-with="Saving...">Save Credit</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{credit: credit} = assigns, socket) do
    changeset = Credits.change_credit(credit)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"credit" => credit_params}, socket) do
    changeset =
      socket.assigns.credit
      |> Credits.change_credit(credit_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"credit" => credit_params}, socket) do
    save_credit(socket, socket.assigns.action, credit_params)
  end

  defp save_credit(socket, :edit, credit_params) do
    case Credits.update_credit(socket.assigns.credit, credit_params) do
      {:ok, credit} ->
        notify_parent({:saved, credit})

        {:noreply,
         socket
         |> put_flash(:info, "Credit updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_credit(socket, :new, credit_params) do
    case Credits.create_credit(credit_params) do
      {:ok, credit} ->
        notify_parent({:saved, credit})

        {:noreply,
         socket
         |> put_flash(:info, "Credit created successfully")
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
