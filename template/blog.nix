cfg:
{
  lib,
  title,
  summary,
  author,
  date,
  path,
  ...
}:
let
  mdContent = lib.buildMarkdownText "blog-post" path;
  content = ''
    <h1>${title}</h1>
    <p><strong>${summary}</strong></p>
    <p>Author: <em>${author}</em></p>
    <p>Date Published: <em>${date}</em></p>
    <hr>
    ${mdContent}
  '';
in
lib.buildPage {
  name = "blog";
  text = lib.buildTemplateText (import ./page.nix cfg) {
    inherit title summary content;
  };
}
