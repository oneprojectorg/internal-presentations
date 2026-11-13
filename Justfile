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

clean:
    rm -rf build

default:
    @just --list
