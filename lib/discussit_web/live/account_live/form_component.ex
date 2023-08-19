defmodule DiscussitWeb.AccountLive.FormComponent do
  use DiscussitWeb, :live_component

  alias Discussit.Accounts
  import DiscussitWeb.LiveSupport

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage account records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="account-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:openphone_signing_secret]} type="password" label="Signing Secret" />
        <.input field={@form[:openai_api_key]} type="password" label="OpenAI API Key" />
        <div class="dropdown w-full">
          <div phx-feedback-for={@form[:timezone].name} class="form-control w-full">
            <.label for={@form[:timezone].id}>Timezone</.label>
            <div class="flex flex-row">
              <.input
                field={@form[:timezone]}
                type="raw_input"
                prompt="Choose a value"
                class="input input-bordered w-full rounded-r-none"
                autocomplete="off"
              />
              <button
                type="button"
                class="btn btn-ghost rounded-l-none"
                phx-click={JS.focus(to: "#account_timezone") |> JS.push("reset-timezone")}
                phx-target={@myself}
              >
                <.icon name="hero-chevron-down" />
              </button>
            </div>
            <.error :for={msg <- Enum.map(@form[:timezone].errors, &translate_error(&1))}>
              <%= msg %>
            </.error>
          </div>
          <ul class="menu menu-compact dropdown-content bg-base-300 top-20 max-h-96 overflow-hidden flex-col rounded-md">
            <li
              :for={{key, value} <- filter_timezone_options(@form)}
              key={key}
              class="border-b border-b-base-content/10 w-full"
              phx-click="pick-timezone"
              phx-value-val={value}
              phx-target={@myself}
            >
              <button type="button"><%= value %></button>
            </li>
          </ul>
        </div>
        <.input
          field={@form[:plan]}
          type="select"
          label="Plan"
          prompt="Choose a value"
          options={Ecto.Enum.values(Discussit.Accounts.Account, :plan)}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{account: account} = assigns, socket) do
    changeset = Accounts.change_account(account)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"account" => account_params}, socket) do
    changeset =
      socket.assigns.account
      |> Accounts.change_account(account_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"account" => account_params}, socket) do
    save_account(socket, socket.assigns.action, account_params)
  end

  def handle_event("pick-timezone", %{"val" => value}, socket) do
    changeset =
      socket.assigns.account
      |> Accounts.change_account(%{"timezone" => value})
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("reset-timezone", _, socket) do
    changeset =
      socket.assigns.account
      |> Accounts.change_account(%{"timezone" => ""})
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp save_account(socket, :edit, account_params) do
    case Accounts.update_account(socket.assigns.account, account_params) do
      {:ok, account} ->
        notify_parent({:saved, account})

        {:noreply,
         socket
         |> put_flash(:info, "Account updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_account(socket, :new, account_params) do
    case Accounts.create_account(account_params) do
      {:ok, account} ->
        notify_parent({:saved, account})

        {:noreply,
         socket
         |> put_flash(:info, "Account created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp filter_timezone_options(form) do
    case form[:timezone].value do
      nil ->
        select_options(Discussit.Accounts.Account, :timezone)

      input_value when is_binary(input_value) ->
        select_options(Discussit.Accounts.Account, :timezone)
        |> Enum.filter(fn {_key, value} ->
          String.contains?(String.upcase(value), String.upcase(input_value))
        end)

      _ ->
        []
    end
  end
end
