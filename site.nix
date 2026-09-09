{
  lib,
  pkgs,
}:
let
  cfg = {
    title = "Nathan Gill";
    url = "https://ngill.net";
  };

  templates = {
    base = import ./template/base.nix;
    page = import ./template/page.nix cfg;
    home = import ./template/home.nix cfg;
    now = import ./template/now.nix cfg;
    blog = import ./template/blog.nix cfg;
    blog_list = import ./template/blog_list.nix cfg;
  };

  buildMarkdownPage =
    path: meta:
    lib.buildTemplate templates.page (
      {
        content = lib.buildMarkdownText (lib.sanitisePath "${path}") path;
      }
      // meta
    );

  processPosts =
    prefix: posts:
    map (
      post:
      (
        post
        // {
          finalPath = lib.getBlogPath prefix post.path;
        }
      )
    ) (builtins.sort (a: b: a.date > b.date) posts);

  buildBlogPosts =
    prefix: posts:
    builtins.listToAttrs (
      map (post: {
        name = post.finalPath;
        value = lib.buildTemplate templates.blog post;
      }) (processPosts prefix posts)
    );

  posts = [
    {
      title = "MySQL Database Connection Tester";
      summary = "Write a VB.NET application to test the connection of MySQL databases";
      author = "Nathan Gill";
      date = "2021-03-09";
      path = ./content/blog/posts/2021/00-mysql-database-connection-tester.md;
    }
    {
      title = "Writing Tiny Code - Part 1";
      summary = "Write a tiny hello world program in x86-64 assembly";
      author = "Nathan Gill";
      date = "2025-11-16";
      path = ./content/blog/posts/2025/00-writing-tiny-code-pt1.md;
    }
    {
      title = "Writing Tiny Code - Part 2";
      summary = "Optimise the program from part 1 to produce an even smaller binary";
      author = "Nathan Gill";
      date = "2026-01-02";
      path = ./content/blog/posts/2026/00-writing-tiny-code-pt2.md;
    }
    {
      title = "Who needs GUIs anyway?";
      summary = "My frustrations with desktop UI, especially GUI toolkits";
      author = "Nathan Gill";
      date = "2026-02-02";
      path = ./content/blog/posts/2026/02-who-needs-gui-anyway.md;
    }
    {
      title = "Writing Wayland screen lockers \"for fun\"";
      summary = "Yes, I wrote (or at least tried to write) more than one";
      author = "Nathan Gill";
      date = "2026-03-05";
      path = ./content/blog/posts/2026/03-writing-wayland-screen-lockers.md;
    }
  ];

  rssConfig = pkgs.writeText "rss-config" (
    builtins.toJSON ({
      inherit (cfg) url;
      title = "Nathan Gill's Blog";
      desc = "Nathan Gill's blog on various topics";
      outName = "rss.xml";
      posts = processPosts "blog/posts" posts;
    })
  );

  site = {
    name = "personal-site";
    version = "1.0";

    src = ./.;

    nativeBuildInputs = with pkgs; [
      python314
      python3Packages.beautifulsoup4
      python3Packages.pygments
      python3Packages.catppuccin
    ];

    pages = {
      "404.html" = buildMarkdownPage ./content/404.md { title = "Not Found"; };
      "index.html" = lib.buildTemplate templates.home { };
      "about/index.html" = buildMarkdownPage ./content/about/index.md { title = "About"; };
      "blog/index.html" = lib.buildTemplate templates.blog_list {
        posts = processPosts "blog/posts" posts;
        prefix = lib.buildMarkdownText "blog-prefix" ./content/blog/index.md;
      };
      "contact/index.html" = buildMarkdownPage ./content/contact/index.md { title = "Contact"; };
      "now/index.html" = lib.buildTemplate templates.now {
        path = ./content/now/index.md;
        date = "2026-06-25";
      };
      "uses/index.html" = buildMarkdownPage ./content/uses/index.md { title = "Uses"; };
    }
    // (buildBlogPosts "blog/posts" posts);

    postBuild = ''
      mkdir -p $out
      patchShebangs ./scripts/*

      echo "copying static..."
      cp -r ./static/* $out/
      chmod +w -R $out

      echo "generating rss xml..."
      ./scripts/rss_generator.py ${rssConfig} > $out/rss.xml

      echo "generating sitemap xml..."
      ./scripts/sitemap_generator.py \
        incl="[\"*.html\"]" \
        excl="[\"404/html\"]" \
        url=\"${cfg.url}\" \
        build_dir=\"$out\" > $out/sitemap.xml

      echo "highlighting..."
      ./scripts/highlight.py \
        incl="[\"*.html\"]" \
        excl="[]" \
        build_dir=\"$out\"
    '';
  };
in
site
