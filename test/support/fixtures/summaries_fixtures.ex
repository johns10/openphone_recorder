defmodule Discussit.SummariesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Discussit.Summaries` context.
  """

  @doc """
  Generate a summary.
  """
  def summary_fixture(attrs \\ %{}) do
    {:ok, summary} =
      attrs
      |> Enum.into(%{
        content: "some content",
        params: %{},
        chunker: :daily
      })
      |> Discussit.Summaries.create_summary()

    summary
  end

  def long_daily_summaries(conversation_summarizer_id) do
    [
      %{
        content:
          "The conversation is between Jen Rose and a customer with the phone number +1 623-326-6968. The customer thanks Jen Rose and says goodbye. The customer then asks about payment for a job and Jen Rose apologizes and says she will follow up with Josh the next morning. The customer continues to say \"okay\" multiple times. Jen Rose mentions something about tomorrow and asks if the customer has signed an invoice for a previous job. The customer says they haven't been paid yet and mentions doing a job yesterday. Jen Rose asks if the customer is looking for a job order and asks about a walkthrough for cleaning. The customer asks if there are any jobs available for the day and Jen Rose apologizes for not being able to answer calls because it's her day off. The conversation ends with a message from Desert First Cleaning asking the customer to send information about the type of clean they want and providing links to cleaning checklists and online booking. The customer then asks if there is any work available for the day.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-26 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-26 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:36:33.675053],
        updated_at: ~N[2023-08-19 18:36:33.675053]
      },
      %{
        content:
          "The conversation is between two individuals, Jen Rose and +1 623-326-6968. They are discussing various topics related to work and payments.\n\n+1 623-326-6968 asks about the status of their pay. Jen Rose responds that she doesn't think the person they are referring to will close and mentions that she was complaining about the price.\n\nJen Rose then asks if +1 623-326-6968 wants a same-day booking. +1 623-326-6968 responds with \"ok.\"\n\nJen Rose informs +1 623-326-6968 that they don't have a booking for them that day and will let them know if there is a same-day booking later.\n\n+1 623-326-6968 asks about yesterday's payment. Jen Rose replies that she will follow up on that with Josh and explains that they usually send the payment information the day after the cleaning to ensure they received the payment from the customer.\n\n+1 623-326-6968 asks if invoices are being done that day.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-17 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-17 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:37:18.230896],
        updated_at: ~N[2023-08-19 18:37:18.230896]
      },
      %{
        id: "d8f07e75-19fb-4b2d-8482-a0fff1b81fcc",
        content:
          "The conversation is between Jen Rose and +1 623-326-6968. Jen Rose asks +1 623-326-6968 to call someone, but +1 623-326-6968 says not yet. Jen Rose reminds +1 623-326-6968 to take before and after pictures. Jen Rose asks if +1 623-326-6968 has met the customer, and +1 623-326-6968 says they are there. Jen Rose updates the customer and says goodbye. +1 623-326-6968 says they will be there in 45 minutes. Jen Rose provides the address and job notes. They say goodbye and thank each other. Jen Rose asks +1 623-326-6968 to check their inbox and suggests a time for the job. +1 623-326-6968 says they got it. Jen Rose sends the address again. +1 623-326-6968 says okay. Jen Rose asks +1 623-326-6968 to confirm the job. +1 623-326-6968 says they can't confirm because they are sleeping. They confirm they will be there and ask how many hours the job is. They say they confirmed last night and didn't know they had to confirm multiple times. Jen Rose says they need to confirm two hours before the job. +1 623-326-6968 says they were sleeping and didn't know about the multiple confirmations. Jen Rose says she will assign another crew since +1 623-326-6968 is not responding. +1 623-326-6968 says they used to respond. Jen Rose says goodbye. +1 623-326-6968 says goodbye and peace. Jen Rose asks for confirmation for the cleaning job. +1 623-326-6968 says bye. Jen Rose thanks +1 623-326-6968. +1 623-326-6968 asks how they risk. Jen Rose says goodbye. Jen Rose informs +1 623-326-6968 that the payment has been sent. +1 623-326-6968 says they still haven't received payment.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-15 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-15 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:37:41.982569],
        updated_at: ~N[2023-08-19 18:37:41.982569]
      },
      %{
        id: "11578688-09a8-43a8-bb7a-cc2504ef7990",
        content:
          "The conversation is between Jen Rose and a person with the phone number +1 623-326-6968, referred to as Kayla. Jen Rose informs Kayla that she spoke with Josh, who will send her payment later that night. Kayla confirms that she understands. Jen Rose then provides Kayla with the details of a cleaning job for the next day, including the address, time, and job requirements. Kayla confirms her availability and agrees to invoice them for her cleaning services. However, Kayla mentions that she drove a long distance for a job and needs gas to continue working. Jen Rose informs Kayla that Josh will make the payment in the morning and apologizes for the delay. Kayla asks for details about an Airbnb job, and Jen Rose promises to update her once she has the information. Kayla mentions that the walk-through for a job went well. Jen Rose informs Kayla that they are waiting for a call back from Josh's boss for more details about the Airbnb job. Kayla asks for the address of the job before confirming her availability. Jen Rose apologizes for not having the details yet and promises to send the address once she has it. Kayla mentions that she needs to look at the address before confirming her availability. Jen Rose asks if Kayla is available for cleaning in the afternoon, and Kayla says she will let her know after looking at the address. There is then a series of unintelligible messages from Kayla. Jen Rose thanks Kayla and promises to tell Josh to process her payment. Kayla mentions that she has resent something and then confirms that she is at the job location. Jen Rose thanks Kayla and asks if she has met the customer. Kayla confirms that she is there and asks for clarification on an invoice and payment. Jen Rose asks for Kayla's ETA for a morning cleaning job and Kayla says she is getting ready to head over. Jen Rose informs Kayla that she has scheduled the morning job and asks her to let them know when she is on the move. Jen Rose greets Kayla and asks about a referral bonus. The conversation ends there.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-14 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-14 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:37:52.927968],
        updated_at: ~N[2023-08-19 18:37:52.927968]
      },
      %{
        id: "2b395e9d-60c5-43a3-b819-570d2cd9bf06",
        content:
          "In this conversation, Jen Rose and +1 623-326-6968 are discussing various tasks and appointments. Jen Rose informs +1 623-326-6968 that Kayla needs to be present at 9am for Annie Burkheimer. +1 623-326-6968 responds that the walk-through is complete but needs to be scheduled for after 1pm the next day. Jen Rose provides an invoice number and total amount of $150.26. +1 623-326-6968 asks for the invoice and total for this particular job. Jen Rose thanks +1 623-326-6968 and suggests calling Troy for a video call walk-through. +1 623-326-6968 mentions before pictures. Jen Rose expresses gratitude and confirms that Kayla is available for Annie Burkheimer's appointment. +1 623-326-6968 confirms today's job.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-27 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-27 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:36:29.692174],
        updated_at: ~N[2023-08-19 18:36:29.692174]
      },
      %{
        id: "1b7400a8-760f-4d7c-93a3-3042cce3eafa",
        content:
          "The conversation is between +1 623-326-6968 and Jen Rose from Desert First Cleaning. +1 623-326-6968 is asking for the invoice number and sending before and after pictures. Jen Rose apologizes for missing the call and asks for information about the type of clean, number of bedrooms and bathrooms, and square footage of the home. She also provides links to cleaning checklists and an online booking option. +1 623-326-6968 confirms that they have completed the task and Jen Rose mentions that they are on the phone with another customer. +1 623-326-6968 says they are on their way and greets Jen Rose. Jen Rose asks if they have arrived and mentions that the customer needs to pick up his daughter. +1 623-326-6968 confirms their arrival and Jen Rose provides the address and details of the cleaning job. +1 623-326-6968 confirms the payment and Jen Rose thanks them. Jen Rose asks for the payment before proceeding and +1 623-326-6968 agrees. Jen Rose mentions that the job should take less than two hours and clarifies that it is not an hourly rate. +1 623-326-6968 asks for the duration of the job and Jen Rose explains that it is a studio with 400 square feet. +1 623-326-6968 confirms their availability for the next morning and Jen Rose provides the address again. The conversation ends with +1 623-326-6968 mentioning that they use Kayla with KKClean and Jen Rose thanks them.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-25 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-25 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:36:40.136605],
        updated_at: ~N[2023-08-19 18:36:40.136605]
      },
      %{
        id: "8e52d558-47ce-4be7-a4e4-8ad25a4eaf6c",
        content:
          "The conversation is between +1 623-326-6968 and Jen Rose. +1 623-326-6968 asks if they need to wait for payment before paying the cleaners. Jen Rose confirms that they need to receive the payment first before paying the cleaners. +1 623-326-6968 then asks if they need to wait until Monday to receive payment for a job they did yesterday.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-24 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-24 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:36:42.279158],
        updated_at: ~N[2023-08-19 18:36:42.279158]
      },
      %{
        id: "9af5fd40-312d-4b0f-a48d-9515fc0a6a14",
        content:
          "The conversation is between two individuals, +1 623-326-6968 and Jen Rose. They are discussing rebooking bonuses and payments for completed jobs.\n\n+1 623-326-6968 mentions that the boys they did a job for two days ago were return customers. Jen Rose acknowledges this and mentions a different customer who also received a bonus.\n\nJen Rose then asks if what John told +1 623-326-6968 last time is accurate. +1 623-326-6968 responds by saying they have an invoice for the rebooking bonus.\n\nJen Rose thanks +1 623-326-6968 and says she will inform Josh. +1 623-326-6968 responds with \"ufh resent.\"\n\nJen Rose then mentions a payment of $120 with the job number #20230319-95183. However, +1 623-326-6968 points out that the job number is incomplete.\n\n+1 623-326-6968 reassures Jen Rose by saying \"there there\" and mentions that they sent the request two days ago.\n\nJen Rose then greets Kayla and informs her that Josh is trying to send her payment but she needs to create a new Cashapp request. Jen Rose also asks Kayla to invoice them and complete the job number.\n\nJen Rose provides the details of the jobs completed, including the amount and job numbers.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-21 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-21 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:36:55.498063],
        updated_at: ~N[2023-08-19 18:36:55.498063]
      },
      %{
        id: "60089773-1a2b-4ea5-bf48-628f55e655bd",
        content:
          "The conversation is between +1 623-326-6968 and Jen Rose. +1 623-326-6968 is complaining about the small pay and the long travel time for a job. Jen Rose explains that the customer is a biweekly regular and the assigned cleaner is unavailable. Jen Rose then offers +1 623-326-6968 a job for the next day, but +1 623-326-6968 refuses because the customer is difficult and she dislikes her cleaning supplies. Jen Rose asks about the cleaning that +1 623-326-6968 did that day and +1 623-326-6968 provides details. Jen Rose mentions that she will inform John about the extended time it took. +1 623-326-6968 expresses disinterest in the job Jen Rose offered and complains about the customer. The conversation ends with +1 623-326-6968 expressing frustration about the customer's request for biweekly cleaning.\n\nJen Rose and +1 623-326-6968 discuss the payment for a cleaning job, with +1 623-326-6968 expressing that three hours is not enough for the payment. They also discuss the distance of the job from where +1 623-326-6968 lives. Jen Rose informs +1 623-326-6968 that she will inform John about the payment issue. They discuss the specific cleaning tasks that the customer wants, including laundry and cleaning the wood floors. Jen Rose provides +1 623-326-6968 with the details for the job and asks if she will take it. +1 623-326-6968 agrees to take the job and confirms the details. They discuss the need for a video call with the customer after the cleaning. Jen Rose asks if +1 623-326-6968 is at the Airbnb yet, and +1 623-326-6968 says she will be there in 15 minutes. They discuss the door code for the Airbnb and +1 623-326-6968 has trouble with it. Jen Rose provides a new code and +1 623-326-6968 is able to enter. They discuss the progress of the cleaning and +1 623-326-6968 mentions that she is in a meeting with the customer. Jen Rose asks +1 623-326-6968 to do a video call with the customer, and +1 623-326-6968 confirms that she has done it and the customer is happy. Jen Rose thanks +1 623-326-6968 and asks her to invoice them for the job.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-16 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-16 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:37:33.101960],
        updated_at: ~N[2023-08-19 18:37:33.101960]
      },
      %{
        id: "84f20310-40f7-4aec-bf3e-cfca553f518a",
        content:
          "The conversation is very short and consists of only two messages. The sender, with the phone number +1 623-326-6968, sends two messages. The first message simply says \"ok,\" and the second message says \"yes.\" There is no further context or information provided in the conversation.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-31 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-31 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:36:26.888163],
        updated_at: ~N[2023-08-19 18:36:26.888163]
      },
      %{
        id: "3eeaa6be-a0af-4874-86ff-700f79a33718",
        content:
          "In this conversation, Jen Rose and +1 623-326-6968 are discussing a payment through Cashapp. Jen Rose informs +1 623-326-6968 that there may be a delay in receiving the payment. +1 623-326-6968 responds with \"bope.\" Jen Rose then reassures +1 623-326-6968 that Josh has already sent the payment. However, +1 623-326-6968 states that they are still waiting for the payment and mentions that it is a big amount of $50. Jen Rose responds with a celebratory message, wishing Kayla a happy birthday and mentioning that it is already the 22nd in the Philippines. +1 623-326-6968 responds by saying they are available and that tomorrow is their own birthday. Jen Rose then informs +1 623-326-6968 that Josh will pay the amount in the morning. +1 623-326-6968 asks if Josh will also pay for Sunday.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-22 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-22 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:36:49.815886],
        updated_at: ~N[2023-08-19 18:36:49.815886]
      },
      %{
        id: "fc4bbb71-ebfc-47a6-82e2-895ef02d45b9",
        content:
          "The conversation begins with +1 623-326-6968 mentioning that they tried to get someone named \"wm\" to tip, but it was messy. They also mention that they are done with something and had a helper. Jen Rose then reminds Kayla to update them and thanks her. Jen Rose informs Kayla that a customer wants to add a fridge cleaning to their job, which includes the kitchen and living area. Jen Rose asks Kayla to let them know how many hours it will take so they can adjust the payment if it is completed in 3 hours. Jen Rose says goodbye and mentions that they will inform the customer. They also mention that it is a small unit. +1 623-326-6968 acknowledges this and says they know. Jen Rose mentions that the customer has used their services before for the kitchen and living room area. They confirm this and Jen Rose says they will inform the customer. They mention some times, and +1 623-326-6968 says they can be there by 2:30. They mention that they have done the customer's Airbnb before. Jen Rose asks if they mean today, and +1 623-326-6968 confirms. Jen Rose says they will inform the customer and asks +1 623-326-6968 what time they are available. +1 623-326-6968 says they can be done by 3:30 and mentions that the customer's location is in Tempe. Jen Rose confirms the address and says +1 623-326-6968 is only 11 minutes away. They mention that they have already sent the address and ask if +1 623-326-6968 is interested. Jen Rose also mentions that the customer has used their services before. They mention that they have another customer with a same-day booking. Jen Rose introduces themselves as Jen and asks if +1 623-326-6968 can hear them. +1 623-326-6968 confirms and asks how to use a killer. Jen Rose says goodbye and then asks if +1 623-326-6968 is interested in a same-day booking. +1 623-326-6968 says okay. Jen Rose then informs +1 623-326-6968 about a job for Monday, with an ETA of 1-2pm. They provide the address and details of the job, including the hourly rate and tasks to be completed. They mention that they will add more payment if the job takes longer than 2 hours.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-19 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-19 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:37:14.103593],
        updated_at: ~N[2023-08-19 18:37:14.103593]
      },
      %{
        id: "920712a9-8e31-451a-adc8-724284d14643",
        content:
          "In this conversation, Jen Rose is communicating with someone using the phone number +1 623-326-6968. Jen Rose informs the person that they have booked them for a job on Monday, March 27th. The person sends pictures and Jen Rose reminds them to also send an after picture. Jen Rose provides a code for the front door and gives instructions for the bedrooms in the house. The person asks for clarification on the code and says they will send pictures. Jen Rose asks for an update and says goodbye. The person thanks Jen Rose and the conversation ends. Later, Jen Rose contacts the person again and asks if they are available for a cleaning job. They discuss the details of the job, including the price and tasks to be done. The person says they just got out of the shower and haven't checked their phone yet. Jen Rose asks if they received her message and the person says they are doing well. Jen Rose then asks if they are available for the cleaning job.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-23 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-23 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:36:46.177938],
        updated_at: ~N[2023-08-19 18:36:46.177938]
      },
      %{
        id: "0f203d49-c630-4b70-b1f1-a97fd1414630",
        content:
          "The conversation is between Jen Rose and +1 623-326-6968 (referred to as Kayla). Jen Rose informs Kayla that a customer gave a five-star review and they will give a $25 bonus to the cleaner. Jen Rose mentions that she always sends a follow-up message to customers asking if they are satisfied. Kayla asks if Jen Rose told the customer where to leave the review and mentions a previous customer in North Scottsdale who should have given a five-star review. Jen Rose says that if the customer is happy, they will add extra to the payment. Kayla asks if the customer tipped and Jen Rose says no. They discuss contacting the customer to negotiate the price. Jen Rose mentions that if the cleaner finishes the job in more than two hours, they will charge an additional $7 per hour. Kayla mentions that she had a helper with her and Jen Rose asks if they finished the job in one and a half hours. Kayla confirms and Jen Rose thanks her. Jen Rose reminds Kayla about the payment process and mentions that Josh tried to pay her but the job number she provided was incomplete. Kayla says she didn't get paid for the previous day's job. Jen Rose says she will follow up on that. They discuss Kayla's schedule for the day and Jen Rose asks her to update when she is on her way to her afternoon clean. Jen Rose sends a job reminder to Kayla for the day and provides the details of the job. Kayla asks for the invoice number and total.",
        level: 1,
        summary_interval: %PgRanges.TsRange{
          lower: ~N[2023-03-20 00:00:00.000000],
          lower_inclusive: true,
          upper: ~N[2023-03-20 23:59:59.000000],
          upper_inclusive: false
        },
        inserted_at: ~N[2023-08-19 18:37:01.020434],
        updated_at: ~N[2023-08-19 18:37:01.020434]
      }
    ]
    |> Enum.map(&Map.put(&1, :conversation_summarizer_id, conversation_summarizer_id))
    |> Enum.map(&summary_fixture/1)
  end
end
