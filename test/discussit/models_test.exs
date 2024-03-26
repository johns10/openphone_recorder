defmodule Discussit.ModelsTest do
  use Discussit.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @id "4989bedd-adf3-4a66-a1d0-86fce4f98e74"
  alias Discussit.Models

  describe "models" do
    alias Discussit.Models.Model

    import Discussit.ModelsFixtures

    @invalid_attrs %{id: nil}

    test "list_models/0 returns all models" do
      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("create_model") do
        model = model_fixture(%{id: @id})
        assert Models.list_models() == [model]
      end
    end

    test "get_model!/1 returns the model with given id" do
      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("create_model") do
        model = model_fixture(%{id: @id})
        assert Models.get_model!(model.id) == model
      end
    end

    test "create_model/1 with valid data creates a model" do
      valid_attrs = %{
        id: @id,
        merge_object: true,
        model_object: true
      }

      assert {:ok, %Model{} = model} = Models.create_model(valid_attrs)
      assert model.merge_object == "#{model.id}-merge-model"
      assert model.model_object == "#{model.id}-model"
    end

    test "create_model/1 specifying S3 objects works" do
      valid_attrs = %{
        id: @id,
        merge_object: true,
        model_object: false
      }

      assert {:ok, %Model{} = model} = Models.create_model(valid_attrs)
      assert model.merge_object
      refute model.model_object
    end

    test "create_model/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Models.create_model(@invalid_attrs)
    end

    test "update_model/2 with valid data updates the model" do
      use_cassette("create_model") do
        model = model_fixture(%{id: @id})

        update_attrs = %{
          merge_object: "some updated merge_object",
          model_object: "some updated model_object"
        }

        assert {:ok, %Model{} = model} = Models.update_model(model, update_attrs)
        assert model.merge_object == "some updated merge_object"
        assert model.model_object == "some updated model_object"
      end
    end

    test "update_model/2 with invalid data returns error changeset" do
      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("create_model") do
        model = model_fixture(%{id: @id})
        assert {:error, %Ecto.Changeset{}} = Models.update_model(model, @invalid_attrs)
        assert model == Models.get_model!(model.id)
      end
    end

    test "delete_model/1 deletes the model" do
      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("delete_model") do
        model = model_fixture(%{id: @id})
        assert {:ok, %Model{}} = Models.delete_model(model)
        assert_raise Ecto.NoResultsError, fn -> Models.get_model!(model.id) end
      end
    end

    test "change_model/1 returns a model changeset" do
      ExVCR.Config.filter_request_headers("Authorization")

      use_cassette("create_model") do
        model = model_fixture(%{id: @id})
        assert %Ecto.Changeset{} = Models.change_model(model)
      end
    end
  end
end
