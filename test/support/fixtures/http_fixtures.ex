defmodule Discussit.HTTPFixtures do
  def openai_speech(attrs \\ %{})

  def openai_speech(%{response_format: "json"}) do
    {:ok,
     %HTTPoison.Response{
       status_code: 200,
       body: "{\"text\":\"Hellloメ\"}",
       headers: [
         {"Date", "Wed, 29 Mar 2023 11:20:58 GMT"},
         {"Content-Type", "application/json"},
         {"Content-Length", "20"},
         {"Connection", "keep-alive"},
         {"Openai-Organization", "user-5x8uzxoc4fqkgcgg4tmmuuru"},
         {"Openai-Processing-Ms", "1277"},
         {"Openai-Version", "2020-10-01"},
         {"Strict-Transport-Security", "max-age=15724800; includeSubDomains"},
         {"X-Ratelimit-Limit-Requests", "60"},
         {"X-Ratelimit-Remaining-Requests", "59"},
         {"X-Ratelimit-Reset-Requests", "1s"},
         {"X-Request-Id", "1bcd49da7f537b002b3f2e6693b836b0"}
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
              {"response_format", "json"},
              {:file,
               "/Users/johndavenport/Documents/github/discussit/test/support/fixtures/hello.mp3"}
            ]},
         params: %{},
         options: []
       }
     }}
  end

  def openai_speech(_attrs) do
    {:ok,
     %HTTPoison.Response{
       status_code: 200,
       body:
         "{\"task\":\"transcribe\",\"language\":\"english\",\"duration\":4.08,\"segments\":[{\"id\":0,\"seek\":0,\"start\":0.0,\"end\":2.0,\"text\":\" Hello.\",\"tokens\":[2425,13],\"temperature\":0.0,\"avg_logprob\":-0.5720185173882378,\"compression_ratio\":0.6521739130434783,\"no_speech_prob\":0.04684533178806305,\"transient\":false},{\"id\":1,\"seek\":200,\"start\":2.0,\"end\":4.0,\"text\":\" Goodbye.\",\"tokens\":[50364,15528,13,50464],\"temperature\":0.0,\"avg_logprob\":-0.4808974266052246,\"compression_ratio\":0.5,\"no_speech_prob\":0.014955926686525345,\"transient\":false}],\"text\":\"Hello. Goodbye.\"}",
       headers: [
         {"Date", "Wed, 29 Mar 2023 08:20:31 GMT"},
         {"Content-Type", "application/json"},
         {"Content-Length", "543"},
         {"Connection", "keep-alive"},
         {"Openai-Organization", "user-5x8uzxoc4fqkgcgg4tmmuuru"},
         {"Openai-Processing-Ms", "726"},
         {"Openai-Version", "2020-10-01"},
         {"Strict-Transport-Security", "max-age=15724800; includeSubDomains"},
         {"X-Ratelimit-Limit-Requests", "60"},
         {"X-Ratelimit-Remaining-Requests", "59"},
         {"X-Ratelimit-Reset-Requests", "1s"},
         {"X-Request-Id", "05e8f29b68015f70de6d9a0883eefad9"}
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
              {"response_format", "verbose_json"},
              {:file,
               "/Users/johndavenport/Documents/github/discussit/test/support/fixtures/hello_goodbye.mp3"}
            ]},
         params: %{},
         options: []
       }
     }}
  end

  def left_openai_speech(_attrs \\ %{}) do
    {:ok,
     %HTTPoison.Response{
       status_code: 200,
       body:
         "{\"task\":\"transcribe\",\"language\":\"english\",\"duration\":4.08,\"segments\":[{\"id\":0,\"seek\":0,\"start\":0.0,\"end\":2.0,\"text\":\" Hello.\",\"tokens\":[2425,13],\"temperature\":0.0,\"avg_logprob\":-0.5720185173882378,\"compression_ratio\":0.6521739130434783,\"no_speech_prob\":0.04684533178806305,\"transient\":false}],\"text\":\"Hello.\"}",
       headers: [
         {"Date", "Wed, 29 Mar 2023 08:20:31 GMT"},
         {"Content-Type", "application/json"},
         {"Content-Length", "543"},
         {"Connection", "keep-alive"},
         {"Openai-Organization", "user-5x8uzxoc4fqkgcgg4tmmuuru"},
         {"Openai-Processing-Ms", "726"},
         {"Openai-Version", "2020-10-01"},
         {"Strict-Transport-Security", "max-age=15724800; includeSubDomains"},
         {"X-Ratelimit-Limit-Requests", "60"},
         {"X-Ratelimit-Remaining-Requests", "59"},
         {"X-Ratelimit-Reset-Requests", "1s"},
         {"X-Request-Id", "05e8f29b68015f70de6d9a0883eefad9"}
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
              {"response_format", "verbose_json"},
              {:file,
               "/Users/johndavenport/Documents/github/discussit/test/support/fixtures/hello_goodbye.mp3"}
            ]},
         params: %{},
         options: []
       }
     }}
  end

  def right_openai_speech(_attrs \\ %{}) do
    {:ok,
     %HTTPoison.Response{
       status_code: 200,
       body:
         "{\"task\":\"transcribe\",\"language\":\"english\",\"duration\":4.08,\"segments\":[{\"id\":1,\"seek\":200,\"start\":2.0,\"end\":4.0,\"text\":\" Goodbye.\",\"tokens\":[50364,15528,13,50464],\"temperature\":0.0,\"avg_logprob\":-0.4808974266052246,\"compression_ratio\":0.5,\"no_speech_prob\":0.014955926686525345,\"transient\":false}],\"text\":\"Goodbye.\"}",
       headers: [
         {"Date", "Wed, 29 Mar 2023 08:20:31 GMT"},
         {"Content-Type", "application/json"},
         {"Content-Length", "543"},
         {"Connection", "keep-alive"},
         {"Openai-Organization", "user-5x8uzxoc4fqkgcgg4tmmuuru"},
         {"Openai-Processing-Ms", "726"},
         {"Openai-Version", "2020-10-01"},
         {"Strict-Transport-Security", "max-age=15724800; includeSubDomains"},
         {"X-Ratelimit-Limit-Requests", "60"},
         {"X-Ratelimit-Remaining-Requests", "59"},
         {"X-Ratelimit-Reset-Requests", "1s"},
         {"X-Request-Id", "05e8f29b68015f70de6d9a0883eefad9"}
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
              {"response_format", "verbose_json"},
              {:file,
               "/Users/johndavenport/Documents/github/discussit/test/support/fixtures/hello_goodbye.mp3"}
            ]},
         params: %{},
         options: []
       }
     }}
  end

  def bogus_openai_speech(_attrs \\ %{}) do
    {:ok,
     %HTTPoison.Response{
       status_code: 200,
       body:
         "{\"task\":\"transcribe\",\"language\":\"english\",\"duration\":4.08,\"segments\":[{\"id\":1,\"seek\":200,\"start\":2.0,\"end\":4.0,\"text\": 1234,\"tokens\":[50364,15528,13,50464],\"temperature\":0.0,\"avg_logprob\":-0.4808974266052246,\"compression_ratio\":0.5,\"no_speech_prob\":0.014955926686525345,\"transient\":false}],\"text\":\"Goodbye.\"}",
       headers: [
         {"Date", "Wed, 29 Mar 2023 08:20:31 GMT"},
         {"Content-Type", "application/json"},
         {"Content-Length", "543"},
         {"Connection", "keep-alive"},
         {"Openai-Organization", "user-5x8uzxoc4fqkgcgg4tmmuuru"},
         {"Openai-Processing-Ms", "726"},
         {"Openai-Version", "2020-10-01"},
         {"Strict-Transport-Security", "max-age=15724800; includeSubDomains"},
         {"X-Ratelimit-Limit-Requests", "60"},
         {"X-Ratelimit-Remaining-Requests", "59"},
         {"X-Ratelimit-Reset-Requests", "1s"},
         {"X-Request-Id", "05e8f29b68015f70de6d9a0883eefad9"}
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
              {"response_format", "verbose_json"},
              {:file,
               "/Users/johndavenport/Documents/github/discussit/test/support/fixtures/hello_goodbye.mp3"}
            ]},
         params: %{},
         options: []
       }
     }}
  end
end
