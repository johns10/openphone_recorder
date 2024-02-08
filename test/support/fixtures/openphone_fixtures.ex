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

  def call_completed_no_voicemail(attrs \\ %{}) do
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
          "voicemail": null,
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
    id = Map.get(attrs, :id, "ACbaee66e137f0467dbed5ad4bc8d60801")

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
    id = Map.get(attrs, :id, "ACbaee66e137f0467dbed5ad4bc8d60802")

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

  def message_received(type \\ nil)

  def message_received(nil) do
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

  def message_received(:multiple_recipients) do
    """
    {
      "id": "EV452cb5a95e44489f8235112715b9c3f7",
      "data": {
        "object": {
          "id": "ACdab71744ad3a4414a584fd45d61b80f2",
          "to": "+15032601493,+15036576960,+15039665948,+15039990213,+15093611926",
          "body": "While going about your daily activities, accept sticking the CORONA EXTRA BEER sticker on the Car, truck, bus, bike, or boat bumper.. $950 Bi-weekly salary. if you're interested click Below link to Apply..\\r\\n\\r\\nhttps: //forms.office.com/Pages/ResponsePage.aspx?id=DQSIkWdsW0yxEjajBLZtrQAAAAAAAAAAAAMAAE9z9_tUNkc5U0M2SUNEM08xSFZTSklGTVIySktUTi4u",
          "from": "+12243068171",
          "media": [],
          "object": "message",
          "status": "received",
          "userId": "USojtPrrVi",
          "createdAt": "2023-08-20T20:47:34.894Z",
          "createdBy": null,
          "direction": "incoming",
          "phoneNumberId": "PNzT5bK17C",
          "conversationId": "CN126b7e85e31a4a718eed14ab1147371e"
        }
      },
      "type": "message.received",
      "object": "event",
      "createdAt": "2023-08-20T20:47:35.016Z",
      "apiVersion": "v3"
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

  def contact_updated(attrs \\ %{})

  def contact_updated(%{phone_number: nil}) do
    """
    {
     "id": "EVf08755a27aed4b4dab904acbb27e1450",
     "data": {
       "object": {
         "id": "CT643452a4da87a11f79bbc55b",
         "notes": [],
         "fields": {},
         "object": "contact",
         "userId": "UShk0sCp2n",
         "clientId": "c89382ac-9f1b-4398-8a3c-639f26d23c64",
         "lastName": "",
         "createdAt": "2023-04-10T18:33:31.819Z",
         "firstName": "jhy",
         "updatedAt": "2023-04-10T18:33:31.819Z",
         "sharedWith": [
           "UShk0sCp2n",
           "OR60CD87vA"
         ]
       }
     },
     "type": "contact.updated",
     "object": "event",
     "createdAt": "2023-04-10T18:33:31.844Z",
     "apiVersion": "v3"
    }
    """
    |> Jason.decode!()
  end

  def contact_updated(attrs) do
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

  def contact_deleted(%{external_id: external_id}) do
    """
    {
      "apiVersion": "v3",
      "createdAt": "2024-02-07T16:16:34.076Z",
      "data": {
        "object": {
          "clientId": "5af42894-e51e-4c31-8e33-6775a466ce12",
          "createdAt": "2024-02-07T16:16:24.408Z",
          "firstName": "Leslie",
          "id": "#{external_id}",
          "lastName": "",
          "notes": [],
          "object": "contact",
          "sharedWith": [
            "UShk0sCp2n",
            "OR60CD87vA"
          ],
          "updatedAt": "2024-02-07T16:16:34.066Z",
          "userId": "UShk0sCp2n"
        }
      },
      "id": "EVb0f620f6907f48f1bf03545694023aeb",
      "object": "event",
      "type": "contact.deleted"
    }
    """
    |> Jason.decode!()
  end
end
