defmodule OpenphoneRecorder.Statements.ChunkerTest do
  use ExUnit.Case
  import OpenphoneRecorder.TimestampFixtures
  alias OpenphoneRecorder.Statements.Statement
  alias OpenphoneRecorder.Statements.Chunker

  def prompt(string, opts \\ []), do: "Here's the prompt #{string}"

  describe "integration" do
    test "works" do
      queue = [
        %Statement{content: Faker.Lorem.sentence(15), occurred_at: ten_minutes_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: thirty_minutes_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: forty_minutes_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: twenty_hours_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: fifty_hours_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: sixty_hours_ago()}
      ]

      chunks =
        [chunk1, chunk2, chunk3, chunk4] =
        queue
        |> Chunker.chunk(max_tokens: 50, prompt_fun: &prompt/2)

      assert Enum.count(chunks) == 4
      assert Enum.count(chunk1) == 2
      assert Enum.count(chunk2) == 1
      assert Enum.count(chunk3) == 1
      assert Enum.count(chunk4) == 2
    end
  end

  describe "temporal_chunk" do
    test "chunks together" do
      queue = [
        %Statement{content: Faker.Lorem.sentence(15), occurred_at: ten_minutes_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: thirty_minutes_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: forty_minutes_ago()}
      ]

      [chunk] =
        chunks =
        Chunker.acc(queue)
        |> Chunker.temporal_chunks(max_tokens: 25)

      assert Enum.count(chunks) == 1
      assert Enum.count(chunk) == 3
    end

    test "chunks apart" do
      queue = [
        %Statement{content: Faker.Lorem.sentence(15), occurred_at: ten_minutes_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: thirty_minutes_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: twenty_hours_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: fifty_hours_ago()},
        %Statement{content: Faker.Lorem.sentence(20), occurred_at: sixty_hours_ago()}
      ]

      chunks =
        [chunk1, chunk2, chunk3] =
        Chunker.acc(queue)
        |> Chunker.temporal_chunks(max_tokens: 25)

      assert Enum.count(chunks) == 3
      assert Enum.count(chunk1) == 2
      assert Enum.count(chunk2) == 1
      assert Enum.count(chunk3) == 2
    end
  end

  describe "token_count_chunks" do
    test "chunks together" do
      queue = [
        %Statement{content: Faker.Lorem.sentence(15)},
        %Statement{content: Faker.Lorem.sentence(20)},
        %Statement{content: Faker.Lorem.sentence(20)}
      ]

      chunks =
        [chunk1] =
        Chunker.acc(queue)
        |> Chunker.token_count_chunks(max_tokens: 60, prompt_fun: &prompt/2)

      assert Enum.count(chunks) == 1
      assert Enum.count(chunk1) == 3
    end

    test "chunks apart" do
      queue = [
        %Statement{content: Faker.Lorem.sentence(15)},
        %Statement{content: Faker.Lorem.sentence(20)},
        %Statement{content: Faker.Lorem.sentence(20)}
      ]

      chunks =
        [chunk1, chunk2] =
        Chunker.acc(queue)
        |> Chunker.token_count_chunks(max_tokens: 50, prompt_fun: &prompt/2)

      assert Enum.count(chunks) == 2
      assert Enum.count(chunk1) == 1
      assert Enum.count(chunk2) == 2
    end
  end
end
