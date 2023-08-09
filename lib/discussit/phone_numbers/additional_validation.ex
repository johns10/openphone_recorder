defmodule Discussit.PhoneNumbers.AdditionalValidation do
  import Ecto.Changeset

  @shortcode_regexes [
    ~r/[1-9]\\d{2,5}/,
    ~r/11(?:2|5[1-47]|[68]\d|7[0-57]|98)|[2-9]\d{3,5}|[2-8]11|9(?:11|33|88)/,
    ~r/112|611|9(?:11|33|88)/,
    ~r/2(?:3333|(?:4224|7562|900)2|56447|6688)|3(?:1010|2665|7404)|40404|560560|6(?:0060|22639|5246|7622)|7(?:0701|3822|4666)|8(?:(?:3825|7226)5|4816)|99099/,
    ~r/24280|(?:381|968)35|4(?:3355|7553|8221)|5(?:(?:489|934)2|5928)|72078|(?:323|960)40|(?:276|414)63|(?:2(?:520|744)|7390|9968)9|(?:693|732|976)88|(?:3(?:556|825)|5294|8623|9729)4|(?:3378|4136|7642|8961|9979)6|(?:4(?:6(?:15|32)|827)|(?:591|720)8|9529)7/,
    ~r/336\d\d|[2-9]\d{3}|[2356]11/,
    ~r/112|911/,
    ~r/9(?:33|88)/,
    ~r/1(?:0[4-9]|1[2368]|2[0-3568]|787)|911/,
    ~r/128|911/
  ]

  def handle_no_caller_id(%{errors: errors} = changeset, attrs) do
    Keyword.get(errors, :value)
    |> case do
      nil ->
        changeset

      {"is invalid", [type: EctoPhoneNumber, validation: :cast]} ->
        key = if Enum.at(attrs, 0) |> elem(0) |> is_atom(), do: :value, else: "value"
        invalid_value = Map.get(attrs, key)

        case is_no_caller_id?(invalid_value) do
          true ->
            force_invalid_phone_number(changeset, attrs, invalid_value)

          false ->
            changeset
        end
    end
  end

  def handle_shortcode(%{errors: errors} = changeset, attrs) do
    Keyword.get(errors, :value)
    |> case do
      nil ->
        changeset

      {"is invalid", [type: EctoPhoneNumber, validation: :cast]} ->
        key = if Enum.at(attrs, 0) |> elem(0) |> is_atom(), do: :value, else: "value"
        invalid_value = Map.get(attrs, key)

        case is_shortcode?(invalid_value) && String.length(invalid_value) in [5, 6] do
          true ->
            force_invalid_phone_number(changeset, attrs, invalid_value)

          false ->
            changeset
        end
    end
  end

  defp force_invalid_phone_number(changeset, attrs, invalid_value) do
    changeset.data
    |> cast(attrs, [:external_id, :source])
    |> put_change(:value, %EctoPhoneNumber{
      e164: String.to_integer(invalid_value)
    })
    |> Discussit.PhoneNumbers.PhoneNumber.cast_id()
    |> handle_shortcode(attrs)
    |> validate_required([:source])
    |> unique_constraint([:id], name: :phone_numbers_pkey)
  end

  def is_shortcode?(phone_number_value) do
    @shortcode_regexes
    |> Enum.any?(fn regex ->
      Regex.match?(regex, phone_number_value)
    end)
  end

  def is_no_caller_id?(phone_number_value) do
    phone_number_value == "+266696687" or phone_number_value == "266696687"
  end
end
