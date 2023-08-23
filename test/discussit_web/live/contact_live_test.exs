defmodule DiscussitWeb.ContactLiveTest do
  use DiscussitWeb.ConnCase

  import Phoenix.LiveViewTest
  import Discussit.ContactsFixtures

  @create_attrs %{
    first_name: "some first_name",
    last_name: "some last_name",
    source: :user
  }
  @update_attrs %{
    first_name: "some updated first_name",
    last_name: "some updated last_name",
    source: :user
  }
  @invalid_attrs %{first_name: nil, last_name: nil}

  defp create_contact(%{account: account}) do
    contact = contact_fixture(%{account_id: account.id})
    %{contact: contact}
  end

  describe "Index without permission" do
    setup [:register_and_log_in_user, :user_setup, :create_contact]

    test "lists all contacts", %{conn: conn, contact: contact} do
      {:ok, _index_live, html} = live(conn, ~p"/contacts")

      assert html =~ "Listing Contacts"
      assert html =~ contact.first_name
    end

    test "saves new contact", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert index_live |> element("a", "New Contact") |> render_click() =~
               "New Contact"

      assert_patch(index_live, ~p"/contacts/new")

      # assert index_live
      #        |> form("#contact-form", contact: @invalid_attrs)
      #        |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#contact-form", contact: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/contacts")

      html = render(index_live)
      assert html =~ "Contact created successfully"
      assert html =~ "some first_name"
      assert html =~ "some last_name"
    end

    test "updates contact in listing", %{conn: conn, contact: contact} do
      {:error,
       {:live_redirect, %{flash: %{"error" => "You cannot access this contact"}, to: "/home"}}} =
        live(conn, ~p"/contacts/#{contact}/edit")
    end

    test "deletes contact in listing", %{conn: conn, contact: contact} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert index_live |> element("#contacts-#{contact.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#contacts-#{contact.id}")
    end
  end

  describe "Index with permission" do
    setup [:register_and_log_in_user, :user_setup, :permit, :create_contact]

    test "updates contact in listing", %{conn: conn, contact: contact} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert index_live |> element("#contacts-#{contact.id} a", "Edit") |> render_click() =~
               "Edit Contact"

      assert_patch(index_live, ~p"/contacts/#{contact}/edit")

      # assert index_live
      #        |> form("#contact-form", contact: @invalid_attrs)
      #        |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#contact-form", contact: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/contacts")

      html = render(index_live)
      assert html =~ "Contact updated successfully"
      assert html =~ "some updated last_name"
    end

    test "handles contact phone numbers listing", %{conn: conn, contact: contact} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts/#{contact}/edit")

      invalid_attrs =
        Map.put(@update_attrs, :contact_phone_numbers,
          "0": %{phone_number: %{value: "notaphonenumber"}}
        )

      assert index_live
             |> element("#add-phone-number", "Add a phone number")
             |> render_click() =~ "Enter phone number"

      refute index_live
             |> element("#remove-temporary-contact-phone-number")
             |> render_click() =~ "Enter phone number"

      assert index_live
             |> element("#add-phone-number", "Add a phone number")
             |> render_click() =~ "Enter phone number"

      assert index_live
             |> element("#contact-form")
             |> render_change(contact: invalid_attrs) =~ "invalid"

      valid_attrs =
        Map.put(@update_attrs, :contact_phone_numbers,
          "0": %{phone_number: %{value: "12566583331"}}
        )

      assert index_live
             |> form("#contact-form", contact: valid_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/contacts")

      html = render(index_live)
      assert html =~ "Contact updated successfully"
      assert html =~ "some updated last_name"
    end

    test "upserts contact phone numbers listing", %{conn: conn, contact: contact} do
      Discussit.PhoneNumbersFixtures.phone_number_fixture(%{value: "12566581234"})
      {:ok, index_live, _html} = live(conn, ~p"/contacts/#{contact}/edit")

      attrs =
        Map.put(@update_attrs, :contact_phone_numbers,
          "0": %{phone_number: %{value: "12566581234"}}
        )

      index_live
      |> element("#add-phone-number", "Add a phone number")
      |> render_click() =~ "Enter phone number"

      index_live
      |> form("#contact-form", contact: attrs)
      |> render_submit()

      # TODO: assert on html

      assert_patch(index_live, ~p"/contacts")
    end

    test "deletes contact in listing", %{conn: conn, contact: contact} do
      {:ok, index_live, _html} = live(conn, ~p"/contacts")

      assert index_live |> element("#contacts-#{contact.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#contacts-#{contact.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :user_setup, :permit, :create_contact]

    test "displays contact", %{conn: conn, contact: contact} do
      {:ok, _show_live, html} = live(conn, ~p"/contacts/#{contact}")

      assert html =~ "Show Contact"
      assert html =~ contact.external_id
    end

    test "updates contact within modal", %{conn: conn, contact: contact} do
      {:ok, show_live, _html} = live(conn, ~p"/contacts/#{contact}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Contact"

      assert_patch(show_live, ~p"/contacts/#{contact}/show/edit")

      # assert show_live
      #        |> form("#contact-form", contact: @invalid_attrs)
      #        |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#contact-form", contact: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/contacts/#{contact}")

      html = render(show_live)
      assert html =~ "Contact updated successfully"
      assert html =~ "some updated last_name"
    end
  end
end
