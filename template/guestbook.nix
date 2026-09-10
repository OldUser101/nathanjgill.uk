cfg:
{
  lib,
}:
let
  head = ''
    <script src="/static/guestbook.js"></script>
    <link href="/static/guestbook.css" rel="stylesheet">
  '';

  content = ''
    <h1>Guestbook</h1>
    <p>Leave a public message here!</p>
    <p><b>NOTE:</b> This feature requires a browser with <b>JavaScript</b>
      support. Why? I couldn't be bothered to implement it in any other way.</p>
    <div id="submit">
      <p><b>Submit a message</b></p>
      <input type="text" name="name" id="msg-name" placeholder="enter your name.. (max 100 chars)"></input>
      <textarea rows="7" name="message" id="msg-message" placeholder="enter your message.. (max 1000 chars)"></textarea>
      <input type="button" name="submit" id="msg-submit" value="submit"></input>
      <p id="submit-error" hidden></p>
      <p id="submit-confirm" hidden>submission success!</p>
    </div>
    <hr>
    <h2>Messages</h2>
    <p>Currently, messages posted here don't go through any filters of any kind, if you
      see something that looks like it probably shouldn't be here, please
      <a href="/contact/index.html">contact me</a>!!!</p>
    <div id="messages">
    </div>
    <p id="fetch-no-msgs" hidden><i>no messages yet.. please add one!!!</i></p>
    <p id="fetch-error" hidden></p>
  '';
in
lib.buildPage {
  name = "guestbook";
  text = lib.buildTemplateText (import ./page.nix cfg) {
    inherit content head;
  };
}
