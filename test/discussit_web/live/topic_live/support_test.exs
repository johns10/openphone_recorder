defmodule DiscussitWeb.TopicLive.SupportTest do
  use ExUnit.Case
  doctest DiscussitWeb.TopicLive.Support
  alias DiscussitWeb.TopicLive.Support
  alias Discussit.Topics.Topic

  describe "Support" do
    test "nest topics" do
      test_topics = [
        %Topic{
          id: 5,
          hierarchy?: true
        },
        %Topic{
          id: 12,
          parent_id: 5,
          hierarchy?: true
        },
        %Topic{
          id: 27,
          parent_id: 5,
          hierarchy?: true
        },
        %Topic{
          id: 32,
          parent_id: 12,
          hierarchy?: false
        },
        %Topic{
          id: 34,
          parent_id: 12,
          hierarchy?: false
        },
        %Topic{
          id: 44,
          parent_id: 27,
          hierarchy?: false
        },
        %Topic{
          id: 48,
          parent_id: 27,
          hierarchy?: false
        }
      ]

      assert %{
               id: 5,
               child_topics: [
                 %{id: 12, child_topics: [%{id: 32}, %{id: 34}]},
                 %{id: 27, child_topics: [%{id: 44}, %{id: 48}]}
               ]
             } = Support.nest_topics(test_topics)
    end
  end
end
