defmodule DiscussitWeb.ContactLive.FormComponent do
  alias Discussit.ContactPhoneNumbers
  use DiscussitWeb, :live_component

  alias Discussit.Contacts
  alias Discussit.ContactPhoneNumbers.ContactPhoneNumber
  alias Discussit.ContactPhoneNumbers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage contact records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="contact-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:account_id]} type="hidden" value={@account_id} />
        <.input field={@form[:source]} type="hidden" value={:user} />
        <div class="flex flex-row space-x-4">
          <.input field={@form[:first_name]} type="text" placeholder="First name" />
          <.input field={@form[:last_name]} type="text" placeholder="Last name" />
        </div>
        <div class="flex flex-row space-x-4">
          <.input field={@form[:company]} type="text" placeholder="Company" />
          <.input field={@form[:role]} type="text" placeholder="Role" />
        </div>
        <.input
          field={@form[:relationship]}
          type="select"
          label="Relationship"
          prompt="Relationship"
          options={Ecto.Enum.values(Discussit.Contacts.Contact, :relationship)}
        />

        <div class="flex flex-row justify-between">
          <.label>Phone Numbers</.label>
          <.label>Delete</.label>
        </div>
        <.inputs_for :let={cpn} field={@form[:contact_phone_numbers]}>
          <div class="flex flex-row items-center !my-2">
            <.input field={cpn[:contact_id]} type="hidden" value={@contact.id} />
            <div class="w-full">
              <.inputs_for :let={pn} field={cpn[:phone_number]}>
                <.input field={pn[:source]} type="hidden" value={:user} />
                <.input field={pn[:value]} type="raw_input" placeholder="Enter phone number" />
                <.error :for={msg <- Enum.map(pn[:value].errors, &translate_error(&1))}>
                  <%= msg %>
                </.error>
              </.inputs_for>
            </div>
            <div :if={is_nil(cpn.data.temp_id) or cpn.data.temp_id == ""} class="mx-4">
              <.input field={cpn[:delete]} type="checkbox" class="ml-4" phx-target={@myself} />
            </div>
            <.input field={cpn[:temp_id]} type="hidden" />
            <.button
              :if={!(is_nil(cpn.data.temp_id) or cpn.data.temp_id == "")}
              id="remove-temporary-contact-phone-number"
              phx-click="remove-contact-phone-number"
              phx-target={@myself}
              phx-value-remove={cpn.data.temp_id}
              type="button"
              class="btn-error btn-sm ml-2"
            >
              <.icon name="hero-x-mark-solid" class="w-3 h-3" />
            </.button>
          </div>
        </.inputs_for>
        <.link href="#" id="add-phone-number" phx-click="add-phone-number" phx-target={@myself}>
          Add a phone number
        </.link>
        <:actions>
          <.button phx-disable-with="Saving...">Save Contact</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{contact: contact} = assigns, socket) do
    changeset = Contacts.change_contact(contact)
    attrs = Map.get(assigns, :attrs, %{})
    phone_number = Map.get(attrs, "phone_number", nil)

    changeset =
      if phone_number do
        Ecto.Changeset.put_change(changeset, :contact_phone_numbers, [
          %{contact_id: contact.id, phone_number: %{value: phone_number}}
        ])
      else
        changeset
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"contact" => contact_params}, socket) do
    changeset =
      socket.assigns.contact
      |> Contacts.change_contact(contact_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"contact" => contact_params}, socket) do
    save_contact(socket, socket.assigns.action, contact_params)
  end

  def handle_event("add-phone-number", _, socket) do
    existing_contact_phone_numbers =
      Map.get(
        socket.assigns.changeset.changes,
        :contact_phone_numbers,
        socket.assigns.contact.contact_phone_numbers
      )

    contact_phone_numbers =
      existing_contact_phone_numbers
      |> Enum.concat([
        ContactPhoneNumbers.change_contact_phone_number(%ContactPhoneNumber{
          temp_id: Ecto.UUID.generate()
        })
      ])

    changeset =
      Ecto.Changeset.put_assoc(
        socket.assigns.changeset,
        :contact_phone_numbers,
        contact_phone_numbers
      )

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("remove-contact-phone-number", %{"remove" => id}, socket) do
    contact_phone_numbers =
      socket.assigns.changeset.changes.contact_phone_numbers
      |> Enum.reject(fn %{data: contact_phone_number} ->
        contact_phone_number.temp_id == id
      end)

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_assoc(:contact_phone_numbers, contact_phone_numbers)

    {:noreply, assign_form(socket, changeset)}
  end

  defp save_contact(socket, :edit, contact_params) do
    case Contacts.update_nested_contact(socket.assigns.contact, contact_params) do
      {:ok, contact} ->
        notify_parent({:saved, contact})

        {:noreply,
         socket
         |> put_flash(:info, "Contact updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_contact(socket, :new, contact_params) do
    case Contacts.create_nested_contact(contact_params) do
      {:ok, contact} ->
        notify_parent({:saved, contact})

        {:noreply,
         socket
         |> put_flash(:info, "Contact created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    socket
    |> assign(:form, to_form(changeset))
    |> assign(:changeset, changeset)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
