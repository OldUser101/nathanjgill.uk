{
  pkgs,
}:
let
  lib = {
    buildPage = pg: pkgs.writeText pg.name pg.text;

    buildTemplate =
      tmpl: opts:
      tmpl ((builtins.intersectAttrs (builtins.functionArgs tmpl) { inherit lib pkgs; }) // opts);

    buildTemplateText = tmpl: opts: builtins.readFile (lib.buildTemplate tmpl opts);

    buildMarkdown =
      name: path:
      pkgs.runCommand name
        {
          nativeBuildInputs = [ pkgs.cmark-gfm ];
        }
        ''
          cmark-gfm \
            -e footnotes \
            -e table \
            -e strikethrough \
            -e autolink \
            ${path} > $out
        '';

    buildMarkdownText = name: path: builtins.readFile (lib.buildMarkdown name path);

    buildSite =
      s:
      let
        site = s { inherit lib pkgs; };
        c = pkgs.lib.mapAttrsToList (name: page: ''
          echo "building ${name}..."
          mkdir -p "$out/$(dirname '${name}')"
          cp "${page}" "$out/${name}"
        '') (site.pages or { });
      in
      pkgs.stdenv.mkDerivation {
        pname = site.name;
        version = site.version;

        inherit (site) src;
        nativeBuildInputs = site.nativeBuildInputs or [ ];

        installPhase = ''
          ${site.preBuild or ""}
          ${pkgs.lib.concatStringsSep "\n" c}
          ${site.postBuild or ""}
        '';
      };

    getBlogPath =
      prefix: path:
      let
        path' = builtins.toString path;
        xs = pkgs.lib.splitString "/" (builtins.replaceStrings [ ".md" ] [ ".html" ] path');
        length = builtins.length xs;
      in
      "${prefix}/${builtins.elemAt xs (length - 2)}/${builtins.elemAt xs (length - 1)}";

    # this is probably good enough
    sanitisePath = path: builtins.replaceStrings [ "/" "\\" " " ":" ] [ "_" "_" "-" "-" ] path;
  };
in
lib
