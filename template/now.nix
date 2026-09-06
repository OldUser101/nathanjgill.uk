cfg:
{
  lib,
  path,
  date ? null,
}:
let
  mdContent = lib.buildMarkdownText "now" path;
  content = ''
    ${mdContent}
    ${if (date != null) then "<p>Last Updated: ${date}</em></p>" else ""}
  '';
in
lib.buildPage {
  name = "now";
  text = lib.buildTemplateText (import ./page.nix cfg) {
    inherit content;
    title = "Now";
  };
}
