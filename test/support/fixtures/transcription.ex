defmodule OpenphoneRecorder.TranscriptionFixtures do
  def response() do
    %HTTPoison.Response{
      status_code: 200,
      body: "{\"text\":\"Hello.\"}",
      headers: [
        {"Date", "Fri, 24 Mar 2023 12:16:59 GMT"},
        {"Content-Type", "application/json"},
        {"Content-Length", "17"},
        {"Connection", "keep-alive"},
        {"Openai-Organization", "user-5x8uzxoc4fqkgcgg4tmmuuru"},
        {"Openai-Processing-Ms", "1641"},
        {"Openai-Version", "2020-10-01"},
        {"Strict-Transport-Security", "max-age=15724800; includeSubDomains"},
        {"X-Ratelimit-Limit-Requests", "60"},
        {"X-Ratelimit-Remaining-Requests", "59"},
        {"X-Ratelimit-Reset-Requests", "1s"},
        {"X-Request-Id", "eac6715799441dfc923b38c34fec119e"}
      ],
      request_url: "https://api.openai.com/v1/audio/transcriptions",
      request: %HTTPoison.Request{
        method: :post,
        url: "https://api.openai.com/v1/audio/transcriptions",
        headers: [
          {"Authorization", "Bearer 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"},
          {"Content-Type", "multipart/form-data"}
        ],
        body:
          {:multipart,
           [
             {"model", "whisper-1"},
             {:file,
              "/Users/johndavenport/Documents/github/openphone_recorder/test/support/fixtures/hello.mp3"}
           ]},
        params: %{},
        options: []
      }
    }
  end
end
