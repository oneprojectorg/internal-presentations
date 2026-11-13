--- talks.lua — list the decks in this repo, with a link to each built one.
--
-- A code block with the `talks` class becomes a table of every deck: its title,
-- its author, its date, and the one-line description in its front matter.
--
--   ```{.talks dir="*" built=build}
--   ```
--
-- The point is that the list cannot go stale. It is read from the deck files
-- themselves at build time, so a new deck appears in the next build and one
-- that is deleted stops appearing. Nothing is written twice.
--
-- Attributes, all optional:
--   dir=presentations   where to look for decks. `dir="*"` scans every
--                       top-level directory that holds a .md file (skipping
--                       build/, filters/, templates/ and hidden directories),
--                       so each person's folder is picked up automatically.
--   ext=html            the extension of the built deck each row links to
--   built=.             where built decks live. Links stay relative to the
--                       page (`ivan/foo.html`), but the existence check looks
--                       under this directory (`build/ivan/foo.html`).
--
-- Two things it warns about on stderr rather than hiding:
--   * a deck with no `description:`, because the listing then has a hole in it
--   * a deck that has not been built, because the row links to a file that is
--     not there. `just build-all` builds them all.

local DEFAULT_DIR = 'presentations'
local DEFAULT_EXT = 'html'

local function warn_about (message)
  io.stderr:write('[talks] ' .. message .. '\n')
end

local function read_file (path)
  local fh = io.open(path, 'r')
  if not fh then return nil end
  local text = fh:read('a')
  fh:close()
  return text
end

local function file_exists (path)
  local fh = io.open(path, 'r')
  if fh then fh:close() return true end
  return false
end

--- The title, author, date, and description a deck's front matter declares.
local function deck_meta (path)
  local text = read_file(path)
  if not text then return nil end
  local meta = pandoc.read(text, 'markdown').meta
  local function value (key)
    local held = meta[key]
    if not held then return nil end
    local flat = pandoc.utils.stringify(held)
    return flat ~= '' and flat or nil
  end
  return {
    title = value 'title',
    author = value 'author',
    date = value 'date',
    description = value 'description',
  }
end

--- Every deck in `dir`. Links are relative to the page; the existence check
--- looks under `built`, where the build writes its output.
local function decks (dir, ext, built)
  local found = {}
  local ok, names = pcall(pandoc.system.list_directory, dir)
  if not ok then
    warn_about('no such directory: ' .. dir)
    return found
  end

  for _, name in ipairs(names) do
    local slug = name:match('^(.+)%.md$')
    if slug then
      local meta = deck_meta(pandoc.path.join{ dir, name })
      if meta then
        local target = pandoc.path.join{ dir, slug .. '.' .. ext }
        local output = pandoc.path.join{ built, target }
        if not file_exists(output) then
          warn_about(output .. ' is not built yet — run `just build-all`')
        end
        if not meta.description then
          warn_about(name .. ' has no description: in its front matter')
        end
        found[#found + 1] = {
          slug = slug,
          title = meta.title or slug,
          author = meta.author,
          date = meta.date,
          description = meta.description,
          target = target,
        }
      end
    end
  end
  return found
end

--- Every top-level directory that holds at least one .md file — each person's
--- folder, without anyone maintaining a list of people.
local function deck_dirs ()
  local skip = { build = true, filters = true, templates = true,
                 node_modules = true }
  local dirs = {}
  local ok, names = pcall(pandoc.system.list_directory, '.')
  if not ok then return dirs end
  for _, name in ipairs(names) do
    if not name:match('^%.') and not skip[name] then
      local readable, entries = pcall(pandoc.system.list_directory, name)
      if readable then
        for _, entry in ipairs(entries) do
          if entry:match('%.md$') then
            dirs[#dirs + 1] = name
            break
          end
        end
      end
    end
  end
  table.sort(dirs)
  return dirs
end

--- A cell's text, safe to put between two pipes.
-- A description is prose the author wrote, so it can hold a pipe, and one pipe
-- would silently split the row into an extra column.
local function cell (text)
  return (text or '—'):gsub('|', '\\|')
end

--- The table, built as Markdown and then parsed.
-- Writing the Markdown is shorter and far more readable than assembling a
-- pandoc Table by hand, and it parses each description as Markdown, so a deck
-- can put a `code span` or a link in its own summary.
local function table_for (list)
  local rows = { '| Talk | Author | Date | What it covers |', '|---|---|---|---|' }
  for _, deck in ipairs(list) do
    rows[#rows + 1] = ('| [%s](%s) | %s | %s | %s |'):format(
      cell(deck.title),
      deck.target,
      cell(deck.author),
      cell(deck.date),
      cell(deck.description)
    )
  end
  return pandoc.read(table.concat(rows, '\n'), 'markdown').blocks
end

return {
  {
    CodeBlock = function (block)
      if not block.classes:includes('talks') then return nil end
      local dir = block.attributes.dir or DEFAULT_DIR
      local ext = block.attributes.ext or DEFAULT_EXT
      local built = block.attributes.built or '.'
      local dirs = dir == '*' and deck_dirs() or { dir }

      local list = {}
      for _, d in ipairs(dirs) do
        for _, deck in ipairs(decks(d, ext, built)) do
          list[#list + 1] = deck
        end
      end

      table.sort(list, function (a, b)
        -- Newest first. A deck with no date sorts last rather than crashing.
        local a_date, b_date = a.date or '', b.date or ''
        if a_date ~= b_date then return a_date > b_date end
        return a.title < b.title
      end)

      if #list == 0 then
        return pandoc.Para{ pandoc.Emph{ pandoc.Str 'No talks yet.' } }
      end
      return table_for(list)
    end,
  },
}
