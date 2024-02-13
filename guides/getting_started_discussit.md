# Getting Started with Discussit 

This guide will walk you through the steps to get started with Discussit, a general purpose conversation intelligence application. 

Follow the instructions below to log in, create an account, set up your account settings, import meetings, transcribe conversations, and summarize content. 

## Logging In 

* Go to the [Discussit application](https://app.discussit.ai).
* If you are not logged in, you will be redirected to the [sign-in page](https://app.discussit.ai/users/log_in).
* If you don't have an account, click on "Sign up" to go to the [sign-up page](https://app.discussit.ai/users/register) and enter your name, email address, and a password that is at least twelve characters long.
* After creating an account, you will be automatically logged in and redirected to the application.
* Check your email and confirm your registration by following the instructions in the email. 

## Creating a New Account

* Click on the small menu icon on the left side of the screen to expand the menu.
* Look for the pulsing icon with three people, which represents "Accounts".
* Click on "Create New Account" and enter the name of the account (your team or company).
* Leave the "Signing Secret" field blank. It's only used for the OpenPhone Integration.
* Leave the "OpenAI API Key" field blank.
* Select the billing user (it's you by default).
* Select a plan from the options available.
* Do not click on "Embeddings" for now.
* Click on "Save Account" to create your account. Ignore any error messages, as your account should be created successfully.
* Click on the three users icon again to see your new account in the list. 

## Account Settings 

* Click on the gear icon next to your email address.
* Select "Account Settings" from the menu.
* Scroll down to view your account settings.
* To add new users to your account, enter their email addresses and click "Invite".
* To add a payment method, click on "Add Payment Method" and enter your payment information. 

## Importing Meetings 

* Click on the two people icon to navigate to the [Meetings](https://app.discussit.ai/meetings).
* Click on the plus icon next to "Meetings" in the title bar.
* Navigate to your Zoom folder and click "Select".
* Click on "View Files" to grant browser permission to access the files.
* The application will import all of your Zoom meetings one by one. 

## Adding a Custom Summarizer

* Click on the [Summarizers](https://app.discussit.ai/summarizers) menu option.
* Click on the plus button to Add a Custom Summarizer.
* Enter a name for the summarizer.
* Enter your prompt with the context template variable.
* If you are not familiar with chunkers, select "Token Count".
* Choose a fixed reduction, such as 1000 tokens.
* Click on "Save Summarizer". 

## Transcribing Conversations

* Go to the [Meetings](https://app.discussit.ai/meetings) section.
* Find the meeting you want to transcribe.
* Click on the microphone button.
* Wait for the meeting to transcribe. A spinner will appear while it's transcribing, and a green checkbox will appear when it's finished.
* Click on the meeting to load the transcript. 

## Labeling Participants

* If you want the LLM (Language Model) to know who said what in the conversation, you need to create contacts for each participant.
* Click on the conversation to open it.
* Click on the dropdown menu next to "Participants".
* Use the search bar to find and assign participants, if you don't see them in the list.
* Click on the "Create Conversation" button to move all the data into a conversation. 

## Summarizing Content

* Click on the conversation name to open the conversation.
* In the summarizer dropdown, select your custom summarizer.
* Click on the spinning arrows icon to start the summarization process.
* Wait for the summarizer to finish running. The button will be disabled during this time.
* If the UI does not update, refresh the page.
* Once the summarizer completes, click on the magnifying glass icon next to the summarizer dropdown to view the conversation summaries. Note that there may be more than one summary depending on the conversation length. 
* Congratulations! You have now completed the basic steps to get started with Discussit. Explore the application further to make the most of its conversation intelligence features.