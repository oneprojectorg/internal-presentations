--- talks.lua — list the decks in presentations/, with a link to each built one.
--
-- A code block with the `talks` class becomes a table of every deck: its title,
-- its date, and the one-line description in its front matter.
--
--   ```{.talks}
--   ```
--
-- The point is that the list cannot go stale. It is read from the deck files
-- themselves at build time, so a deck started with `just talk` appears in the
-- next build and one that is deleted stops appearing. Nothing is written twice.
--
-- Attributes, both optional:
--   dir=presentations   where to look for decks
--   ext=html            the extension of the built deck each row links to
--
-- Two things it warns about on stderr rather than hiding:
--   * a deck with no `description:`, because the listing then has a hole in it
--   * a deck that has not been built, because the row links to a file that is
--     not there. `just build-presentations` builds them all.

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

--- The title, date, and description a deck's front matter declares.
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
    date = value 'date',
    description = value 'description',
  }
end

--- Every deck in `dir`, newest first, then by title.
local function decks (dir, ext)
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
        local built = pandoc.path.join{ dir, slug .. '.' .. ext }
        if not file_exists(built) then
          warn_about(built .. ' is not built yet — run `just build-presentations`')
        end
        if not meta.description then
          warn_about(name .. ' has no description: in its front matter')
        end
        found[#found + 1] = {
          slug = slug,
          title = meta.title or slug,
          date = meta.date,
          description = meta.description,
          target = built,
        }
      end
    end
  end

  table.sort(found, function (a, b)
    -- Newest first. A deck with no date sorts last rather than crashing.
    local a_date, b_date = a.date or '', b.date or ''
    if a_date ~= b_date then return a_date > b_date end
    return a.title < b.title
  end)
  return found
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
  local rows = { '| Talk | Date | What it covers |', '|---|---|---|' }
  for _, deck in ipairs(list) do
    rows[#rows + 1] = ('| [%s](%s) | %s | %s |'):format(
      cell(deck.title),
      deck.target,
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
      local list = decks(dir, ext)
      if #list == 0 then
        return pandoc.Para{ pandoc.Emph{ pandoc.Str 'No talks yet.' } }
      end
      return table_for(list)
    end,
  },
}
