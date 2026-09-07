cfg:
{
  lib,
  pkgs,
  posts ? { },
  prefix ? "",
}:
let
  postIndex = builtins.map (post: ''
    <li>
      <a href="/${post.finalPath}">${post.title}</a> - <em>${post.date}</em>
      <p style="margin-top: 0; margin-bottom: 0; margin-left: 1em; font-size: 16px;">${post.summary}</p>
    </li>
  '') posts;
  content = ''
    <ul>
      ${prefix}
      <hr>
      ${pkgs.lib.concatStringsSep "\n" postIndex}
    </ul>
  '';
in
lib.buildPage {
  name = "blog_list";
  text = lib.buildTemplateText (import ./page.nix cfg) {
    inherit content;
    title = "Blog Posts";
  };
}
