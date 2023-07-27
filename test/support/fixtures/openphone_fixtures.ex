defmodule Discussit.OpenphoneFixtures do
  def call_completed(attrs \\ %{}) do
    id = Map.get(attrs, :id, "ACbaee66e137f0467dbed5ad4bc8d60800")

    """
    {
      "id": "EVd39d3c8d6f244d21a9131de4fc9350d0",
      "object": "event",
      "apiVersion": "v2",
      "createdAt": "2022-01-24T19:22:25.427Z",
      "type": "call.completed",
      "data": {
        "object": {
          "id": "#{id}",
          "object": "call",
          "from": "+18005550100",
          "to": "+18885550101",
          "direction": "incoming",
          "media": [],
          "voicemail": {
            "url": "https://storage.googleapis.com/opstatics/a1e0818a737e40258d59b9b400e1dbdd.mp3",
            "type": "audio/mpeg",
            "duration": 7
          },
          "status": "completed",
          "createdAt": "2022-01-24T19:21:59.545Z",
          "answeredAt": null,
          "completedAt": "2022-01-24T19:22:19.000Z",
          "userId": "USu5AsEHuQ",
          "phoneNumberId": "PNtoDbDhuz",
          "conversationId": "CN78ba0373683c48fd8fd96bc836c51f79"
        }
      }
    }
    """
    |> Jason.decode!()
  end

  def call_ringing(attrs \\ %{}) do
    id = Map.get(attrs, :id, "ACbaee66e137f0467dbed5ad4bc8d60800")

    """
    {
      "id": "EV95c3708f9112412a834cc8d415470cd8",
      "object": "event",
      "apiVersion": "v2",
      "createdAt": "2022-01-23T17:07:51.454Z",
      "type": "call.ringing",
      "data": {
        "object": {
          "id": "#{id}",
          "object": "call",
          "from": "+18005550100",
          "to": "+18885550101",
          "direction": "incoming",
          "media": [],
          "voicemail": null,
          "status": "ringing",
          "createdAt": "2022-01-23T17:07:51.116Z",
          "answeredAt": null,
          "completedAt": null,
          "userId": "USu5AsEHuQ",
          "phoneNumberId": "PNtoDbDhuz",
          "conversationId": "CN78ba0373683c48fd8fd96bc836c51f79"
        }
      }
    }
    """
    |> Jason.decode!()
  end

  def call_recording_completed(attrs \\ %{}) do
    id = Map.get(attrs, :id, "ACbaee66e137f0467dbed5ad4bc8d60800")

    """
    {
      "id": "EVda6e196255814311aaac1983005fa2d9",
      "object": "event",
      "apiVersion": "v2",
      "createdAt": "2022-01-24T19:30:55.400Z",
      "type": "call.recording.completed",
      "data": {
        "object": {
          "id": "#{id}",
          "object": "call",
          "from": "+18005550100",
          "to": "+18885550101",
          "direction": "incoming",
          "media": [
            {
              "url": "https://storage.googleapis.com/opstatics-dev/a5f839bc72a24b33a7fc032f78777146.mp3",
              "type": "audio/mpeg",
              "duration": 7
            }
          ],
          "voicemail": null,
          "status": "completed",
          "createdAt": "2022-01-24T19:30:34.675Z",
          "answeredAt": "2022-01-24T19:30:38.000Z",
          "completedAt": "2022-01-24T19:30:48.000Z",
          "userId": "USu5AsEHuQ",
          "phoneNumberId": "PNtoDbDhuz",
          "conversationId": "CN78ba0373683c48fd8fd96bc836c51f79"
        }
      }
    }
    """
    |> Jason.decode!()
  end

  def message_received() do
    """
    {
      "id": "EVc67ec998b35c41d388af50799aeeba3e",
      "object": "event",
      "apiVersion": "v2",
      "createdAt": "2022-01-23T16:55:52.557Z",
      "type": "message.received",
      "data": {
        "object": {
          "id": "AC24a8b8321c4f4cf2be110f4250793d51",
          "object": "message",
          "from": "+18005550100",
          "to": "+18885550101",
          "direction": "incoming",
          "body": "af",
          "media": [
            {
              "url": "https://storage.googleapis.com/opstatics-dev/5c908000ada94d9fb206649ecb8cc928",
              "type": "image/jpeg"
            }
          ],
          "status": "received",
          "createdAt": "2022-01-23T16:55:52.420Z",
          "userId": "USu5AsEHuQ",
          "phoneNumberId": "PNtoDbDhuz",
          "conversationId": "CN78ba0373683c48fd8fd96bc836c51f79"
        }
      }
    }
    """
    |> Jason.decode!()
  end

  def message_delivered() do
    """
    {
      "id": "EVdefd85c2c3b740429cf28ade5b69bcba",
      "object": "event",
      "apiVersion": "v2",
      "createdAt": "2022-01-23T17:05:56.220Z",
      "type": "message.delivered",
      "data": {
        "object": {
          "id": "ACcdcc2668c4134c3cbfdacb9e273cac6f",
          "object": "message",
          "from": "+18005550100",
          "to": "+18885550101",
          "direction": "outgoing",
          "body": "za",
          "media": [
            {
              "url": "https://opstatics-dev.s3.amazonaws.com/i/bb6084db-5259-42c0-93c1-e17fb2628567.jpeg",
              "type": "image/jpeg"
            }
          ],
          "status": "delivered",
          "createdAt": "2022-01-23T17:05:45.195Z",
          "userId": "USu5AsEHuQ",
          "phoneNumberId": "PNtoDbDhuz",
          "conversationId": "CN78ba0373683c48fd8fd96bc836c51f79"
        }
      }
    }
    """
    |> Jason.decode!()
  end

  # def contact_updated_old(attrs \\ %{}) do
  #   phone_numbers =
  #     Map.get(attrs, :phone_numbers, [])
  #     |> Enum.map(&%{value: &1, name: "Phone", type: "phone-number"})

  #   fields = [
  #     %{
  #       name: "Email",
  #       type: "email",
  #       value: nil
  #     },
  #     %{
  #       name: "Prop1",
  #       type: "string",
  #       value: "Value12"
  #     }
  #   ]

  #   """
  #   {
  #     "id": "EVe844e47e9fa4494d9acfa1144839ed94",
  #     "object": "event",
  #     "createdAt": "2022-01-24T19:44:09.579Z",
  #     "apiVersion": "v3",
  #     "type": "contact.updated",
  #     "data": {
  #       "object": {
  #         "id": "CT61eeff33f3b14cfe6358cb52",
  #         "object": "contact",
  #         "firstName": "Jane",
  #         "lastName": "Smith",
  #         "company": "Comp Inc",
  #         "role": "Agent",
  #         "pictureUrl": null,
  #         "fields": #{Jason.encode!(phone_numbers ++ fields)},
  #         "notes": [
  #           {
  #             "text": "@USu5AsEHuQ mynote 🙂",
  #             "enrichment": {
  #               "taggedIds": {
  #                 "groupIds": [],
  #                 "userIds": [
  #                   "USu5AsEHuQ"
  #                 ],
  #                 "orgIds": []
  #               },
  #               "tokens": {
  #                 "USu5AsEHuQ": {
  #                   "token": "USu5AsEHuQ",
  #                   "replacement": "Chris Scott",
  #                   "type": "mention",
  #                   "locations": [
  #                     {
  #                       "startIndex": 1,
  #                       "endIndex": 11
  #                     }
  #                   ]
  #                 }
  #               }
  #             },
  #             "createdAt": "2022-01-24T19:35:38.323Z",
  #             "updatedAt": "2022-01-24T19:35:38.323Z",
  #             "userId": "USu5AsEHuQ"
  #           }
  #         ],
  #         "sharedWith": [
  #           "USu5AsEHuQ"
  #         ],
  #         "createdAt": "2022-01-24T19:35:38.318Z",
  #         "updatedAt": "2022-01-24T19:44:09.565Z",
  #         "userId": "USu5AsEHuQ"
  #       }
  #     }
  #   }
  #   """
  #   |> Jason.decode!()
  # end

  def contact_updated(attrs \\ %{}) do
    phone_number_string =
      Map.get(attrs, :phone_number, "12566581234")
      |> case do
        [first | phone_numbers] = list when is_list(list) ->
          Enum.reduce(
            phone_numbers,
            "[\"+#{first}\"",
            fn pn, acc ->
              acc <> ", \"+" <> pn <> "\""
            end
          ) <> "]"

        phone_number ->
          "\"+#{phone_number}\""
      end

    """
    {
      "apiVersion": "v3",
      "createdAt": "2023-03-30T22:32:12.339Z",
      "data": {
        "object": {
          "clientId": "81b91794-7604-4731-8aab-0cfc5ce44449",
          "createdAt": "2023-03-30T22:32:12.319Z",
          "fields": {"Phone": #{phone_number_string}},
          "firstName": "Jayson",
          "id": "CT64260c5cd1c90ca558ff6edb",
          "lastName": "",
          "notes": [],
          "object": "contact",
          "sharedWith": ["USh6vAGqVi", "OR60CD87vA", "GRkhNXRGuN"],
          "updatedAt": "2023-03-30T22:32:12.319Z",
          "userId": "USh6vAGqVi"
        }
      },
      "id": "EVe1cb0b9c96a34a239fc8cdfd9085863b",
      "object": "event",
      "type": "contact.updated"
    }
    """
    |> Jason.decode!()
  end
end
