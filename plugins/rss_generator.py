#!/usr/bin/env python3

# Tars RSS feed generator
# Copyright (C) 2025-6, Nathan Gill
# Licensed under the MIT license
# See LICENSE_MIT for details

import os
import time
import frontmatter
from pathlib import Path
from urllib.parse import urljoin
from xml.dom.minidom import Document
from email.utils import format_datetime
from datetime import datetime, time as dt_time, timezone

BUILD_DIR = Path("build")
RSS_FILE = Path("static/rss.xml")
ATOM_FILE = Path("static/atom.xml")
RSS_OUT = BUILD_DIR / RSS_FILE
ATOM_OUT = BUILD_DIR / ATOM_FILE

CONTENT_DIR = Path("content")
POST_DIR = Path("posts")
RSS_SRC = CONTENT_DIR / POST_DIR

SITE_TITLE = "Nathan Gill's Blog"
SITE_URL = "https://nathanjgill.uk/"
SITE_DESC = "Nathan Gill's blog posts on various topics"

BUILD_DATE = datetime.now()

def index_posts():
    sources = []

    for root, dirs, files in os.walk(RSS_SRC):
        for f in files:
            src = os.path.join(root, f)
            sources.append(src)
            print(f"Including {src}")
    
    return sources

def sort_sources_by_date(sources):
    def get_date(src):
        with open(src) as f:
            meta, _ = frontmatter.parse(f.read())
            return meta["date"]
    return sorted(sources, key=get_date, reverse=True)

def rss_pubdate_from_date(d, t = dt_time(0, 0)):
    dt = datetime.combine(d, t, tzinfo=timezone.utc);
    return format_datetime(dt)

def src_to_url(src):
    p = Path(src).with_suffix(".html")
    r = p.relative_to(CONTENT_DIR)

    return urljoin(SITE_URL, r.as_posix())

def generate_rss_items(doc, sources):
    items = []

    for src in sources:
        with open(src) as f:
            meta, _ = frontmatter.parse(f.read())
        
            item = doc.createElement("item")

            title = doc.createElement("title")
            title.appendChild(doc.createTextNode(meta["title"]))

            link = doc.createElement("link")
            l = str(src_to_url(src))
            link.appendChild(doc.createTextNode(l))

            desc = doc.createElement("description")
            desc.appendChild(doc.createTextNode(meta["summary"]))

            pubDate = doc.createElement("pubDate")
            date = rss_pubdate_from_date(meta["date"])
            pubDate.appendChild(doc.createTextNode(date))

            guid = doc.createElement("guid")
            guid.setAttribute("isPermaLink", "true")
            guid.appendChild(doc.createTextNode(l))

            item.appendChild(title)
            item.appendChild(link)
            item.appendChild(desc)
            item.appendChild(pubDate)
            item.appendChild(guid)
            
            items.append(item)

    return items

def generate_rss(sources):
    doc = Document()

    rss = doc.createElement("rss")
    rss.setAttribute("version", "2.0")
    rss.setAttribute("xmlns:atom", "http://www.w3.org/2005/Atom")
    rss.setAttribute("xmlns:content", "http://purl.org/rss/1.0/modules/content/")

    channel = doc.createElement("channel")

    siteTitle = doc.createElement("title")
    siteTitle.appendChild(doc.createTextNode(SITE_TITLE))

    siteLink = doc.createElement("link")
    siteLink.appendChild(doc.createTextNode(SITE_URL))

    siteDesc = doc.createElement("description")
    siteDesc.appendChild(doc.createTextNode(SITE_DESC))
    
    lastBuildDate = doc.createElement("lastBuildDate")
    buildDate = rss_pubdate_from_date(BUILD_DATE, t=BUILD_DATE.time())
    lastBuildDate.appendChild(doc.createTextNode(buildDate))

    atomLink = doc.createElement("atom:link")
    atomLink.setAttribute("href", urljoin(SITE_URL, RSS_FILE.as_posix()))
    atomLink.setAttribute("rel", "self")
    atomLink.setAttribute("type", "application/rss+xml")

    items = generate_rss_items(doc, sources)

    channel.appendChild(siteTitle)
    channel.appendChild(siteLink)
    channel.appendChild(siteDesc)
    channel.appendChild(lastBuildDate)
    channel.appendChild(atomLink)

    for item in items:
        channel.appendChild(item)

    rss.appendChild(channel)
    doc.appendChild(rss)

    return doc

print("\n=== TARS RSS GENERATOR ===")
print("    Made by Nathan Gill   \n")

print(f"Source Directory: {RSS_SRC}")
print(f"RSS XML Output: {RSS_OUT}\n")

start = time.perf_counter()

sources = index_posts()
sources = sort_sources_by_date(sources)

rss = generate_rss(sources)
xml = rss.toxml(encoding="UTF-8")

end = time.perf_counter()

with open(RSS_OUT, "wb") as f:
    f.write(xml)

print(f"\nGenerated {RSS_OUT}")
print(f"Generated RSS for {len(sources)} pages in {end - start:.4f} seconds")
