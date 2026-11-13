---
title: {{title}}
author: {{author}}
date: {{date}}
# One line on what the talk covers. It is the row this deck gets in the talks
# table on the site's index page, so write it for somebody deciding whether to
# read on.
description: {{description}}
---

<!-- This file was rendered from templates/presentation.md by `just new`, which
     filled in the front matter above. Fix anything it guessed wrong, starting
     with the description.

     Build it:  just build-presentation {{name}}.md
     One `#` heading starts a slide. Keep a slide to one point — if it needs
     scrolling, it is two slides. Delete the slides you do not use; this is an
     arc, not a form. -->

# The problem

<!-- Open on the problem the room already has, not on what you built. If they
     do not recognise the problem, nothing after this slide lands. -->

# {{title}} {.dark}

<!-- A dark slide marks the break between parts of a talk. Use it to move from
     the problem to your answer, and again before what you want from them. -->

# What it is

<!-- One sentence a listener could repeat to a colleague tomorrow. -->

# How it works

<!-- Replace this comment with a diagram:
     ```plantuml
     @startuml
     ...
     @enduml
     ```
     filters/diagram.lua renders it to an SVG embedded in the built deck. -->

# What it costs

|  | Needs |
|---|---|
| Hardware |  |
| Tooling |  |

# What to do next

<!-- End on the one action you want from the room, not on a summary. -->

::: handout
Speaker notes: hidden on screen, printed with the handout. Write the sentence
you will forget under pressure, not the slide you can already see. Use
`::: handout`, not `::: notes` — the slidy writer drops a notes block and the
text never reaches the page.
:::
