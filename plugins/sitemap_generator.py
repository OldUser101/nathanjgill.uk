#!/usr/bin/env python3

import os
import time
from pathlib import Path
from urllib.parse import urljoin
from xml.dom import minidom

SITE_URL = "https://nathanjgill.uk"
BUILD_DIR = Path("build")
SITEMAP_OUT = BUILD_DIR / Path("sitemap.xml")
INCL_GLOBS = ["*.html"]
EXCL_GLOBS = ["404.html"]

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
    print("\nRunning sitemap generator...")

    start = time.perf_counter()

    pages = find_pages()
    doc = generate_sitemap(pages)
    xml = doc.toxml(encoding="UTF-8")

    end = time.perf_counter()

    with open(SITEMAP_OUT, "wb") as f:
        f.write(xml)
        
    print(f"Generated {SITEMAP_OUT}")
    print(f"Generated sitemap for {len(pages)} pages in {end - start:.4f} seconds")

if __name__ == "__main__":
    main()

