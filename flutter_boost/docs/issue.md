# How to Submit an Issue

1. Briefly describe your scenario and the bug in the issue using language


2. After that, you can fork a branch, then on your branch, in `example3.0`, add an entry for your bug reproduction case
   - If your entry is on the native side, just add a button on the native page to add the operation.
   - If your entry is on the flutter side, just add a Model to the flutter's `main_page` list to add the case, see the code for details

**<font color='red'> Note: Other methods of submitting reproduction code are not supported here (The reason is that if everyone uses their own code, it's easy to include usage errors and their own business logic. We won't be clear whether it's a business problem or a framework issue. We've encountered some cases where debugging revealed that the inconsistent results were caused by their own business code issues, so please understand) </font>**

3. Provide your branch link in the issue and submit. When we debug, we will directly go to the case you provided in your branch's `example3.0` for bug reproduction
