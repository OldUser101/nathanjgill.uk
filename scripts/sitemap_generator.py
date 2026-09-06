#!/usr/bin/env python3

# XML sitemap generator
# Copyright (C) 2026 Nathan Gill
# Licensed under the MIT license
# See LICENSE_MIT for details

import os
import sys
import time
import tomllib
from pathlib import Path
from urllib.parse import urljoin
from xml.dom import minidom

SITE_URL = None
BUILD_DIR = None
SITEMAP = None
INCL_GLOBS = None
EXCL_GLOBS = None

for arg in sys.argv:
    try:
        data = tomllib.loads(arg)
        key, value = next(iter(data.items()))
    except ValueError:
        continue

    if key == "url":
        SITE_URL = str(value)
    elif key == "build_dir":
        BUILD_DIR = Path(value)
    elif key == "sitemap":
        SITEMAP = Path(value)
    elif key == "incl":
        INCL_GLOBS = list(value)
    elif key == "excl":
        EXCL_GLOBS = list(value)
    else:
        sys.exit(1)

def page_to_url(page):
    page = Path(page).relative_to(BUILD_DIR)
    url = urljoin(SITE_URL, page.as_posix())
    return url

def find_pages():
    pages = []

    for glob in INCL_GLOBS:
        paths = BUILD_DIR.rglob(glob)
        for path in paths:
            url = page_to_url(path)
            if url not in pages:
                pages.append(url)

    for glob in EXCL_GLOBS:
        paths = BUILD_DIR.rglob(glob)
        for path in paths:
            url = page_to_url(path)
            if url in pages:
                pages = list(filter(lambda p: p != url, pages))

    return pages

def generate_sitemap(pages):
    doc = minidom.Document()
    
    urlset = doc.createElement("urlset")
    urlset.setAttribute("xmlns", "http://www.sitemaps.org/schemas/sitemap/0.9")
    urlset.setAttribute("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
    urlset.setAttribute("xsi:schemaLocation", "http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd")

    for page in pages:
        url = doc.createElement("url")

        loc = doc.createElement("loc")
        loc.appendChild(doc.createTextNode(page))
        
        url.appendChild(loc)
        urlset.appendChild(url)

    doc.appendChild(urlset)

    return doc
    
def main():
    pages = find_pages()
    doc = generate_sitemap(pages)
    xml = doc.toxml(encoding="UTF-8")

    sys.stdout.buffer.write(xml)
    sys.stdout.buffer.flush()

if __name__ == "__main__":
    main()

