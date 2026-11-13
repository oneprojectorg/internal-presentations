--- if-built.lua — link a build output only once it has been built.
--
-- Mark a link whose target is generated:
--
--   [The same thing as a PDF](index.pdf){.if-built}
--
-- If the file is there, the link stays a link and the class is dropped. If it
-- is not, the link becomes its own text followed by *(not built)*, so the page
-- says what is true rather than pointing at nothing.
--
-- This exists because intro.html lists the other outputs, and two of them are
-- not always present. `index.pdf` needs a LaTeX engine, which the Brewfile
-- leaves optional, and `index.html` is not built by `just intro` on its own.
-- Without this, the front door shipped four dead links and only warned.
--
-- Run it BEFORE check-links.lua. Order is what stops check-links from
-- reporting a link this filter was about to remove.
--
-- A link with a scheme, or one that is only an `#anchor`, is left alone: this
-- filter knows about files, and neither of those is one.

local function search_roots ()
  local roots = { '.' }
  for _, f in ipairs(PANDOC_STATE.input_files or {}) do
    local dir = pandoc.path.directory(f)
    if dir and dir ~= '' then roots[#roots + 1] = dir end
  end
  return roots
end

local function file_exists (path)
  local fh = io.open(path, 'r')
  if fh then fh:close() return true end
  return false
end

--- True if `target` names a file that is on disk under one of the roots.
local function built (target)
  -- `index.html#about` is a link to a file with a fragment on the end. The
  -- fragment is not part of the path, and dropping it is what makes an
  -- in-document anchor into the built page resolve here.
  local path = target:gsub('[#?].*$', '')
  if path == '' then return true end
  for _, root in ipairs(search_roots()) do
    if file_exists(pandoc.path.join{ root, path }) then return true end
  end
  return false
end

local function is_local (target)
  return not target:match('^%a[%w+.-]*:') and not target:match('^//')
    and not target:match('^#')
end

return {
  {
    Link = function (link)
      if not link.classes:includes('if-built') then return nil end

      local keep = not is_local(link.target) or built(link.target)
      if keep then
        -- The class was an instruction to this filter, not something the
        -- output should carry.
        link.classes = link.classes:filter(function (c) return c ~= 'if-built' end)
        return link
      end

      local inlines = link.content:clone()
      inlines:insert(pandoc.Space())
      inlines:insert(pandoc.Emph{ pandoc.Str '(not built)' })
      return inlines
    end,
  },
}
