```
meeting_id = 8
{:ok, participant} = Discussit.Participants.create_participant(%{meeting_id: 8, name: "speaker b"})
{:ok, participant} = Discussit.Participants.update_participant(participant, %{name: "speaker a"}) 
```