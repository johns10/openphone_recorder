defmodule Discussit.Mailer do
  use Swoosh.Mailer, otp_app: :discussit
  import Swoosh.Email, only: [new: 0, from: 2, html_body: 2, text_body: 2]

  # Base email function should contain all common features
  def base_email do
    new()
    |> from(from_email())
  end

  def render_body(email, template), do: render_body(email, template, %{})

  def render_body(email, template, args) when is_atom(template) and is_map(args) do
    heex = apply(DiscussitWeb.Emails, template, [args])
    html_with_layout = render_component(DiscussitWeb.Emails.layout_html(%{inner_content: heex}))

    html_body(
      email,
      html_with_layout
    )
  end

  def render_body(email, "" <> template, args) do
    template = template |> String.split(".") |> List.first() |> String.to_atom()
    render_body(email, template, args)
  end

  def render_body(email, template, args) when is_list(args) do
    render_body(email, template, Map.new(args))
  end

  # Inline CSS so it works in all browsers
  def premail(email) do
    html = Premailex.to_inline_css(email.html_body)
    text = Premailex.to_text(email.html_body)
    text_with_layout = render_component(DiscussitWeb.Emails.layout_text(%{inner_content: text}))

    email
    |> html_body(html)
    |> text_body(text_with_layout)
  end

  defp render_component(heex) do
    heex |> Phoenix.HTML.Safe.to_iodata() |> IO.chardata_to_string()
  end

  defp from_email, do: "noreply@example.com"
end
