defmodule OpenphoneRecorder.ChunkerTest do
  use OpenphoneRecorder.DataCase
  import OpenphoneRecorder.TimestampFixtures
  alias OpenphoneRecorder.Statements.Statement
  alias OpenphoneRecorder.Chunker
  alias OpenphoneRecorder.Chunker.Queue
  alias OpenphoneRecorder.Chunker.Daily
  alias OpenphoneRecorder.Chunker.TokenCount
  alias OpenphoneRecorder.Participants.Participant
  alias OpenphoneRecorder.PhoneNumbers.PhoneNumber
  alias OpenphoneRecorder.Summaries.Summary

  def prompt(string, _opts \\ []), do: "Here's the prompt #{string}"

  def participant() do
    %Participant{phone_number: %PhoneNumber{contact: nil}}
  end

  describe "integration" do
    test "works" do
      queue =
        [
          %Statement{content: Faker.Lorem.sentence(15), occurred_at: NaiveDateTime.utc_now()},
          %Statement{content: Faker.Lorem.sentence(20), occurred_at: NaiveDateTime.utc_now()},
          %Statement{content: Faker.Lorem.sentence(20), occurred_at: NaiveDateTime.utc_now()},
          %Statement{content: Faker.Lorem.sentence(20), occurred_at: yesterday()},
          %Statement{content: Faker.Lorem.sentence(10), occurred_at: two_days_ago()},
          %Statement{content: Faker.Lorem.sentence(10), occurred_at: two_days_ago()},
          %Statement{content: Faker.Lorem.sentence(10), occurred_at: two_days_ago()}
        ]
        |> Enum.map(&Map.put(&1, :participant, participant()))

      chunks =
        [chunk1, chunk2, chunk3, chunk4] =
        queue
        |> Chunker.apply(max_tokens: 50, chunkers: [:daily, :token_count])

      assert Enum.count(chunks) == 4
      assert Enum.count(chunk1) == 3
      assert Enum.count(chunk2) == 1
      assert Enum.count(chunk3) == 1
      assert Enum.count(chunk4) == 2
    end
  end

  describe "Weekly" do
    test "chunks together" do
      day_of_week =
        Date.utc_today()
        |> Date.day_of_week()

      queue = [
        %Summary{
          content: Faker.Lorem.sentence(15),
          summary_interval: days_ago_range(day_of_week + 1),
          time_zone: "Etc/UTC"
        },
        %Summary{
          content: Faker.Lorem.sentence(20),
          summary_interval: days_ago_range(day_of_week + 2),
          time_zone: "Etc/UTC"
        },
        %Summary{
          content: Faker.Lorem.sentence(20),
          summary_interval: days_ago_range(day_of_week + 5),
          time_zone: "Etc/UTC"
        }
      ]

      chunks = [chunk1] = queue |> Chunker.apply(max_tokens: 50, chunkers: [:weekly])

      assert Enum.count(chunks) == 1
      assert Enum.count(chunk1) == 3
    end

    test "chunks apart" do
      day_of_week =
        Date.utc_today()
        |> Date.day_of_week()

      queue = [
        %Summary{
          content: Faker.Lorem.sentence(15),
          summary_interval: days_ago_range(day_of_week + 3),
          time_zone: "Etc/UTC"
        },
        %Summary{
          content: Faker.Lorem.sentence(20),
          summary_interval: days_ago_range(day_of_week + 4),
          time_zone: "Etc/UTC"
        },
        %Summary{
          content: Faker.Lorem.sentence(20),
          summary_interval: days_ago_range(day_of_week + 8),
          time_zone: "Etc/UTC"
        },
        %Summary{
          content: Faker.Lorem.sentence(20),
          summary_interval: days_ago_range(day_of_week + 16),
          time_zone: "Etc/UTC"
        }
      ]

      chunks =
        [chunk1, chunk2, chunk3] = queue |> Chunker.apply(max_tokens: 50, chunkers: [:weekly])

      assert Enum.count(chunks) == 3
      assert Enum.count(chunk1) == 1
      assert Enum.count(chunk2) == 1
      assert Enum.count(chunk3) == 2
    end
  end

  describe "Daily" do
    test "chunks together" do
      queue =
        [
          %Statement{content: Faker.Lorem.sentence(15), occurred_at: NaiveDateTime.utc_now()},
          %Statement{content: Faker.Lorem.sentence(20), occurred_at: NaiveDateTime.utc_now()},
          %Statement{content: Faker.Lorem.sentence(20), occurred_at: NaiveDateTime.utc_now()}
        ]
        |> Enum.map(&Map.put(&1, :participant, participant()))

      [chunk] =
        chunks =
        Queue.acc(queue)
        |> Daily.chunk_items()

      assert Enum.count(chunks) == 1
      assert Enum.count(chunk) == 3
    end

    test "chunks apart" do
      queue =
        [
          %Statement{content: Faker.Lorem.sentence(15), occurred_at: NaiveDateTime.utc_now()},
          %Statement{content: Faker.Lorem.sentence(20), occurred_at: NaiveDateTime.utc_now()},
          %Statement{content: Faker.Lorem.sentence(20), occurred_at: two_days_ago()},
          %Statement{content: Faker.Lorem.sentence(20), occurred_at: three_days_ago()},
          %Statement{content: Faker.Lorem.sentence(20), occurred_at: three_days_ago()}
        ]
        |> Enum.map(&Map.put(&1, :participant, participant()))

      chunks =
        [chunk1, chunk2, chunk3] =
        Queue.acc(queue)
        |> Daily.chunk_items()

      assert Enum.count(chunks) == 3
      assert Enum.count(chunk1) == 2
      assert Enum.count(chunk2) == 1
      assert Enum.count(chunk3) == 2
    end
  end

  describe "token_count_chunks" do
    test "chunks together" do
      queue =
        [
          %Statement{content: Faker.Lorem.sentence(15)},
          %Statement{content: Faker.Lorem.sentence(20)},
          %Statement{content: Faker.Lorem.sentence(20)}
        ]
        |> Enum.map(&Map.put(&1, :participant, participant()))

      chunks =
        [chunk1] =
        Queue.acc(queue)
        |> TokenCount.chunk_items(max_tokens: 60)

      assert Enum.count(chunks) == 1
      assert Enum.count(chunk1) == 3
    end

    test "chunks apart" do
      queue =
        [
          %Statement{content: Faker.Lorem.sentence(20)},
          %Statement{content: Faker.Lorem.sentence(20)},
          %Statement{content: Faker.Lorem.sentence(15)}
        ]
        |> Enum.map(&Map.put(&1, :participant, participant()))

      chunks =
        [chunk1, chunk2] =
        Queue.acc(queue)
        |> TokenCount.chunk_items(max_tokens: 50)

      assert Enum.count(chunks) == 2
      assert Enum.count(chunk1) == 1
      assert Enum.count(chunk2) == 2
    end
  end
end
