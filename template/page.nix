cfg:
{
  lib,
  title ? null,
  summary ? null,
  content ? "",
  head ? "",
  footer ? "",
}:
let
  summary' =
    if (summary != null) then
      ''
        <meta name="description" content="${summary}">
      ''
    else
      "";
  head' = ''
    <title>${if (title != null) then (title + " | ") else ""}${cfg.title}</title>
    ${summary'}
    ${head}
  '';
  page = ''
    <header>
      <a href="/index.html">home</a>
      <a href="/about/index.html">about</a>
      <a href="/blog/index.html">blog</a>
      <a href="/guestbook/index.html">guestbook</a>
      <a href="/contact/index.html">contact</a>
    </header>
    <div id="content">
      ${content}
    </div>
    <footer>
      <a href="/index.html">home</a>
      <a href="/about/index.html">about</a>
      <a href="/blog/index.html">blog</a>
      <a href="/now/index.html">now</a>
      <a href="/uses/index.html">uses</a>
      <a href="/guestbook/index.html">guestbook</a>
      <a href="/contact/index.html">contact</a>
      <a href="/rss.xml">rss</a>

      <p>
        Copyright &copy; 2026, Nathan Gill<br>
        Licensed under <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/">CC BY-NC-SA 4.0</a>
      </p>
    </footer>
  '';
in
lib.buildPage {
  name = "page";
  text = lib.buildTemplateText (import ./base.nix) {
    inherit page footer;
    head = head';
  };
}
