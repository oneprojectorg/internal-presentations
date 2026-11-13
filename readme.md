# Internal Presentations

A collection of tools for build reproducible technical
presentations. This project uses pandoc to process markdown files into
slidy presentations. We use plantuml or mermaid to build digrams.

## Install

```shell
brew bundle
```

## Usage

Add your presentations as markdown files in a folder named after you
(e.g. `ivan/`, `alex/`). `just build-all` builds every `*.md` file in
every top-level folder. Output HTML goes to `build/`, mirroring the
source layout (e.g. `ivan/notifications-storage.md` builds to
`build/ivan/notifications-storage.html`).

```shell
just --list
just build-all
just build-presentation ivan/notifications-storage.md
just clean
```


## Pandoc

Pandoc provides us a build pipeline where we translate raw digram code
blocks into SVGs
