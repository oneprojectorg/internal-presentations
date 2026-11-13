filters := "--lua-filter filters/include.lua \
    --lua-filter filters/diagram.lua \
    --lua-filter filters/not-in-format.lua \
    --lua-filter filters/pagebreak.lua \
    --lua-filter filters/check-links.lua"

build-presentation FILE:
    #!/usr/bin/env bash
    set -euo pipefail
    out="build/{{replace(FILE, ".md", ".html")}}"
    mkdir -p "$(dirname "$out")"
    pandoc -t slidy \
    --embed-resources \
    --standalone \
    --css templates/oneproject.css \
    {{filters}} --citeproc \
    "{{FILE}}" \
    -o "$out"

build-all:
    #!/usr/bin/env bash
    set -euo pipefail
    for file in */*.md; do
        [ -e "$file" ] || continue
        case "$file" in build/*|filters/*) continue ;; esac
        just build-presentation "$file"
    done

# Build build/index.html — the site's front door, listing every built deck.
# filters/talks.lua generates the table from each deck's front matter.
build-index:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p build
    pandoc index.md \
    -f markdown -t html \
    --standalone \
    --embed-resources \
    --css templates/oneproject.css \
    --css templates/index.css \
    --lua-filter filters/talks.lua \
    --lua-filter filters/include.lua \
    -o build/index.html

# Build the whole site into build/: every deck, then the index that links them.
build-site: build-all build-index

clean:
    rm -rf build

default:
    @just --list
