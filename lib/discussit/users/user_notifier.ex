defmodule Discussit.Users.UserNotifier do
  import Swoosh.Email
  alias Discussit.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, template, assigns) do
    email =
      new()
      |> to(recipient)
      |> from({"Discussit", "contact@discussit.app"})
      |> subject(subject)
      |> Mailer.render_body(template, assigns)
      |> Mailer.premail()

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(
      user.email,
      "Confirmation instructions",
      "confirmation_instructions.html",
      %{user: user, url: url}
    )
  end

  @doc """
  Deliver instructions to accept invitation.
  """
  def deliver_invitation_instructions(user, url) do
    deliver(
      user.email,
      "Invitation instructions",
      "invitation_instructions.html",
      %{user: user, url: url}
    )
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(
      user.email,
      "Reset password instructions",
      "reset_password.html",
      %{user: user, url: url}
    )
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(
      user.email,
      "Update email instructions",
      "update_email.html",
      %{user: user, url: url}
    )
  end
end
