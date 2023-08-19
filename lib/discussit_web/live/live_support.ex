defmodule DiscussitWeb.LiveSupport do
  def select_options(module, field) do
    Enum.zip(
      Ecto.Enum.values(module, field),
      Ecto.Enum.dump_values(module, field)
    )
  end
end
