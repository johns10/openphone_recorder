# How to Manage Summarizers in Discussit

This guide will walk you through the steps to manage your summarizers in Discussit. Summarizers are used to create content from conversations. Follow the instructions below to create a new summarizer or edit an existing one. 

1. Open the [Discussit web app by](https://app.discussit.ai).
2. Once you are on the Discussit homepage, locate the [Summarizers](https://app.discussit.ai/summarizers) menu in the main menu bar. 
3. To [create a new Summarizer](https://app.discussit.ai/summarizers/new), click on the plus button located in the upper right-hand corner of the page.
4. To edit an existing summarizer, locate the summarizer you want to edit and click on the "Edit" button next to it.
5. In the summarizer settings, enter a descriptive name for the summarizer. This name will be used throughout the application to refer to it.
6. In the "Prompt" section, enter the prompt that you want to send to the LLM. The prompt is the text that will be used to generate the summary.
7. Use template variables in your prompt to customize it. Currently, the only available template variable is called "context". This variable will contain the entire content of the conversation that you want to summarize.
8. Enclose your template variables in angle brackets, percent signs, and equals signs. For example, `<%= context %>`.
9. It is important to add template variables correctly, as any mistakes may cause your prompt to not work properly.
10. If your conversation is very large and exceeds the context window, you can use the "Reducer Prompt" option. The reducer prompt is used to reduce the size of the conversation before generating the final output.
11. If you want to break up the conversation into chunks, you can use the "Chunker" option. Choose the type of chunks you want to create, such as daily, weekly, monthly, or based on token count. 
12. If you select the token count option, the summarizer will use the length of the content to determine the chunks. If the content is too long, the reducer will be used to reduce its size before generating the final output.
13. Specify how much you want to reduce the size of the content. You can choose a percentage reduction (e.g., 50% or 25%) or a fixed number of tokens.
14. Once you have finished configuring your summarizer, click the "Save Summarizer" button to save your changes. 

Congratulations! You have successfully learned how to manage summarizers in Discussit. You can now create new summarizers or edit existing ones to generate content from your conversations.