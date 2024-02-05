defmodule Discussit.Transcription.SupportTest do
  alias Discussit.ParticipantsFixtures
  use Discussit.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias DialyxirVendored.Warnings.Call
  alias Discussit.ConversationsFixtures
  alias Discussit.CallsFixtures
  alias Discussit.Meetings.Meeting
  alias Discussit.AccountUsersFixtures
  alias Discussit.AccountsFixtures
  alias Discussit.MeetingsFixtures
  alias Discussit.UsersFixtures
  alias Discussit.Transcription.Support
  alias Discussit.Files.File
  alias Discussit.Calls.Call

  describe "prepare files" do
    setup do
      user = UsersFixtures.user_fixture()
      account = AccountsFixtures.account_fixture()
      AccountUsersFixtures.account_user_fixture(%{account_id: account.id, user_id: user.id})

      %{user: user, account: account}
    end

    test "meeting case", %{user: user} do
      meeting =
        MeetingsFixtures.meeting_fixture(%{user_id: user.id})
        |> Map.put(:files, [
          %File{bucket: "test", key: "test", metadata: %{"type" => "audio/mp4"}}
        ])

      assert %{recordings: [%File{}], chat: nil} = Support.prepare_files(%{data: meeting})
    end

    test "call case with voicemail", %{account: account} do
      conversation = ConversationsFixtures.conversation_fixture(%{account_id: account.id})

      call =
        CallsFixtures.call_fixture(%{conversation_id: conversation.id})
        |> Map.put(:voicemail, %File{
          bucket: "test",
          key: "test",
          metadata: %{"type" => "audio/mp4"}
        })

      assert %{recordings: [%File{}]} = Support.prepare_files(%{data: call})
    end

    test "call case with call_recording", %{account: account} do
      conversation = ConversationsFixtures.conversation_fixture(%{account_id: account.id})

      call =
        CallsFixtures.call_fixture(%{conversation_id: conversation.id})
        |> Map.put(:call_recording, %File{
          bucket: "test",
          key: "test",
          metadata: %{"type" => "audio/mp4"}
        })

      assert %{recordings: [%File{}]} = Support.prepare_files(%{data: call})
    end
  end

  describe "start_transcribing" do
    setup do
      user = UsersFixtures.user_fixture()
      account = AccountsFixtures.account_fixture()
      AccountUsersFixtures.account_user_fixture(%{account_id: account.id, user_id: user.id})

      url =
        use_cassette("256_to_623_aws_call") do
          "./test/support/fixtures/256_to_623.mp3"
          |> ExAws.S3.Upload.stream_file()
          |> ExAws.S3.upload("discussit", "256_to_623")
          |> ExAws.request()

          {:ok, url} =
            ExAws.Config.new(:s3)
            |> ExAws.S3.presigned_url(:get, "discussit", "256_to_623")

          url
        end

      %{user: user, account: account, url: url}
    end

    test "call case", %{url: url, account: account} do
      conversation = ConversationsFixtures.conversation_fixture(%{account_id: account.id})
      files = [%File{url: url}]
      call = CallsFixtures.call_fixture(%{conversation_id: conversation.id})

      use_cassette("256_to_623_dual_channel_aai_call") do
        assert %{status: :ok, data: %{transcript_ids: ["87231675-912d-4085-a53d-75a13059a58e"]}} =
                 Support.start_transcribing(%{status: :ok, data: call, recordings: files})
      end
    end

    test "meeting case", %{url: url, user: user} do
      meeting = MeetingsFixtures.meeting_fixture(%{user_id: user.id})
      files = [%File{url: url}]

      use_cassette("256_to_623_aai_call") do
        assert %{status: :ok, data: %{transcript_ids: ["684f7542-fa2f-496c-8bd0-f836117f2f98"]}} =
                 Support.start_transcribing(%{status: :ok, data: meeting, recordings: files})
      end
    end

    test "meeting case, multiple files", %{url: url, user: user} do
      meeting = MeetingsFixtures.meeting_fixture(%{user_id: user.id})
      files = [%File{url: url}, %File{url: url}]

      use_cassette("256_to_623_aai_call") do
        assert %{
                 status: :ok,
                 data: %{
                   transcript_ids: [
                     "684f7542-fa2f-496c-8bd0-f836117f2f98",
                     "684f7542-fa2f-496c-8bd0-f836117f2f98"
                   ]
                 }
               } = Support.start_transcribing(%{status: :ok, data: meeting, recordings: files})
      end
    end
  end

  describe "finish_transcribing" do
    setup do
      user = UsersFixtures.user_fixture()
      account = AccountsFixtures.account_fixture()
      AccountUsersFixtures.account_user_fixture(%{account_id: account.id, user_id: user.id})

      %{user: user, account: account}
    end

    test "meeting case", %{user: user, account: account} do
      meeting =
        MeetingsFixtures.meeting_fixture(%{
          user_id: user.id,
          transcript_ids: ["b3e6e793-2c07-407a-b9a7-bfab893d2973"]
        })

      use_cassette("256_to_623_retrieve_transcript_call") do
        assert %{segments: [%{"text" => "This is 256-65-8336 placing a call" <> _}]} =
                 Support.finish_transcribing(%{status: :ok, data: meeting, message: ""},
                   account_id: account.id
                 )
      end
    end

    test "call case", %{account: account} do
      conversation = ConversationsFixtures.conversation_fixture(%{account_id: account.id})

      call =
        CallsFixtures.call_fixture(%{
          conversation_id: conversation.id,
          transcript_ids: ["87231675-912d-4085-a53d-75a13059a58e"]
        })

      use_cassette("256_to_623_dual_channel_retrieve_transcript_call") do
        assert %{
                 segments: [
                   %{"text" => "This is 256-65-8336 placing a call" <> _, "channel" => "2"},
                   %{"text" => "This is 623-246-4213 receiving a call" <> _, "channel" => "1"}
                 ]
               } =
                 Support.finish_transcribing(%{status: :ok, data: call, message: ""},
                   account_id: account.id
                 )
      end
    end
  end

  describe "build_statement_attrs" do
    setup do
      user = UsersFixtures.user_fixture()
      account = AccountsFixtures.account_fixture()
      AccountUsersFixtures.account_user_fixture(%{account_id: account.id, user_id: user.id})

      %{user: user, account: account}
    end

    test "meeting case", %{user: user} do
      meeting =
        MeetingsFixtures.meeting_fixture(%{
          user_id: user.id,
          occurred_at: ~N[2020-10-31 00:00:00Z]
        })

      assert %{
               status: :ok,
               statement_attrs: [
                 %{
                   content: "This is 256-65-8336 placing a call" <> _,
                   occurred_at: ~N[2020-10-31 00:00:00.090000Z],
                   ts_range: %{
                     lower: ~N[2020-10-31 00:00:00.090000],
                     upper: ~N[2020-10-31 00:00:16.620000]
                   }
                 }
               ]
             } =
               Support.build_statement_attrs(%{
                 status: :ok,
                 segments: single_channel_segments(),
                 data: meeting,
                 message: ""
               })
    end

    test "call case", %{account: account} do
      conversation = ConversationsFixtures.conversation_fixture(%{account_id: account.id})
      %{id: p_one_id} = ParticipantsFixtures.participant_fixture()
      %{id: p_two_id} = ParticipantsFixtures.participant_fixture()

      call =
        CallsFixtures.call_fixture(%{
          conversation_id: conversation.id,
          transcript_ids: ["87231675-912d-4085-a53d-75a13059a58e"],
          answered_at: ~N[2020-10-31 00:00:00Z],
          from_participant_id: p_one_id,
          to_participant_id: p_two_id,
          from_channel: :left,
          to_channel: :right
        })

      assert %{
               status: :ok,
               statement_attrs: [
                 %{
                   content: "This is 256-65-8336 placing a call" <> _,
                   occurred_at: ~N[2020-10-31 00:00:00.090000Z],
                   ts_range: %{
                     lower: ~N[2020-10-31 00:00:00.090000],
                     upper: ~N[2020-10-31 00:00:06.700000]
                   },
                   participant_id: ^p_two_id
                 },
                 %{
                   content: "This is 623-246-4213 receiving a call" <> _,
                   occurred_at: ~N[2020-10-31 00:00:09.560000],
                   ts_range: %{
                     lower: ~N[2020-10-31 00:00:09.560000],
                     upper: ~N[2020-10-31 00:00:16.650000]
                   },
                   participant_id: ^p_one_id
                 }
               ]
             } =
               Support.build_statement_attrs(%{
                 status: :ok,
                 segments: dual_channel_segments(),
                 data: call,
                 conversation: conversation,
                 duration: 16,
                 message: ""
               })
    end
  end

  describe "create_statements" do
    setup do
      user = UsersFixtures.user_fixture()
      account = AccountsFixtures.account_fixture()
      AccountUsersFixtures.account_user_fixture(%{account_id: account.id, user_id: user.id})

      %{user: user, account: account}
    end

    test "single channel works" do
      %{id: meeting_id} = MeetingsFixtures.meeting_fixture()
      %{id: participant_id} = ParticipantsFixtures.participant_fixture()

      assert %{
               statements: [
                 %{
                   content: "This is 256-65-8336 placing a call to 623" <> _
                 }
               ]
             } =
               Support.create_statements(%{
                 status: :ok,
                 statement_attrs: single_channel_statement_attrs(participant_id, meeting_id)
               })
    end

    test "dual channel works", %{account: account} do
      conversation = ConversationsFixtures.conversation_fixture(%{account_id: account.id})
      %{id: p_one_id} = ParticipantsFixtures.participant_fixture()
      %{id: p_two_id} = ParticipantsFixtures.participant_fixture()

      call =
        CallsFixtures.call_fixture(%{
          conversation_id: conversation.id,
          transcript_ids: ["87231675-912d-4085-a53d-75a13059a58e"],
          answered_at: ~N[2020-10-31 00:00:00Z],
          from_participant_id: p_one_id,
          to_participant_id: p_two_id,
          from_channel: :left,
          to_channel: :right
        })

      assert %{
               statements: [
                 %{content: "This is 256-65-8336" <> _},
                 %{content: "This is 623-246-4213" <> _}
               ]
             } =
               Support.create_statements(%{
                 status: :ok,
                 statement_attrs:
                   dual_channel_statement_attrs(p_one_id, p_two_id, call.id, conversation.id)
               })
    end
  end

  defp single_channel_statement_attrs(participant_id, meeting_id),
    do: [
      %{
        content:
          "This is 256-65-8336 placing a call to 623-246-4213 this is 623-246-4213 receiving a call from 256-658-3236.",
        id: "aa5716a5-89f7-4bcd-b158-56e44cf2cfe7",
        inserted_at: ~N[2024-02-04 21:13:06.084509],
        meeting_id: meeting_id,
        occurred_at: ~N[2020-10-31 00:00:00.090000],
        participant_id: participant_id,
        source: :transcription,
        ts_range: %PgRanges.TsRange{
          lower: ~N[2020-10-31 00:00:00.090000],
          lower_inclusive: true,
          upper: ~N[2020-10-31 00:00:16.620000],
          upper_inclusive: false
        },
        type: :meeting,
        updated_at: ~N[2024-02-04 21:13:06.084509]
      }
    ]

  defp dual_channel_statement_attrs(pone_id, ptwo_id, call_id, conversation_id),
    do: [
      %{
        call_id: call_id,
        content: "This is 256-65-8336 placing a call to 623-246-4213.",
        conversation_id: conversation_id,
        id: "dda7b6f9-8bf7-44b6-a081-7dda8ca4c8f8",
        participant_id: pone_id,
        source: :transcription,
        ts_range: %PgRanges.TsRange{
          lower: ~N[2020-10-31 00:00:00.090000],
          lower_inclusive: true,
          upper: ~N[2020-10-31 00:00:06.700000],
          upper_inclusive: false
        },
        type: :call,
        inserted_at: ~N[2024-02-04 21:47:54.395413],
        updated_at: ~N[2024-02-04 21:47:54.395413],
        occurred_at: ~N[2020-10-31 00:00:00.090000]
      },
      %{
        call_id: call_id,
        content: "This is 623-246-4213 receiving a call from 256-65-8336.",
        conversation_id: conversation_id,
        id: "fe682235-c001-42e5-9985-651b33da270e",
        participant_id: ptwo_id,
        source: :transcription,
        ts_range: %PgRanges.TsRange{
          lower: ~N[2020-10-31 00:00:09.560000],
          lower_inclusive: true,
          upper: ~N[2020-10-31 00:00:16.650000],
          upper_inclusive: false
        },
        type: :call,
        inserted_at: ~N[2024-02-04 21:47:54.395413],
        updated_at: ~N[2024-02-04 21:47:54.395413],
        occurred_at: ~N[2020-10-31 00:00:00.090000]
      }
    ]

  defp single_channel_segments(),
    do: [
      %{
        "confidence" => 0.9734375,
        "end" => 16620,
        "speaker" => "A",
        "start" => 90,
        "text" =>
          "This is 256-65-8336 placing a call to 623-246-4213 this is 623-246-4213 receiving a call from 256-658-3236."
      }
    ]

  defp dual_channel_segments(),
    do: [
      %{
        "channel" => "2",
        "confidence" => 0.9497376,
        "end" => 6700,
        "speaker" => "2",
        "start" => 90,
        "text" => "This is 256-65-8336 placing a call to 623-246-4213."
      },
      %{
        "channel" => "1",
        "confidence" => 0.9595088000000002,
        "end" => 16650,
        "speaker" => "1",
        "start" => 9560,
        "text" => "This is 623-246-4213 receiving a call from 256-65-8336."
      }
    ]
end
