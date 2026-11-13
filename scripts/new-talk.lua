--- new-talk.lua — start a new deck from templates/presentation.md.
--
-- Run through pandoc's own Lua interpreter, so it needs nothing beyond what
-- `brew bundle` already installs:
--
--   pandoc lua scripts/new-talk.lua DIR/NAME ["Title"] ["Description"]
--
-- `just new` is the friendly front for it. DIR is any top-level folder (a
-- topic, a team, a person); NAME is the deck's slug. The title defaults to
-- the slug with its dashes turned to spaces, the author to `git config
-- user.name`, and the date to today. An existing file is never overwritten,
-- and a template placeholder left unfilled is an error, not a blank.

local TEMPLATE = 'templates/presentation.md'

local function fail (message)
  io.stderr:write('[new-talk] ' .. message .. '\n')
  os.exit(1)
end

local function read_file (path)
  local fh = io.open(path, 'r')
  if not fh then return nil end
  local text = fh:read('a')
  fh:close()
  return text
end

local path = arg and arg[1]
if not path or path == '' then
  fail('usage: just new DIR/NAME ["Title"] ["One line on what it covers"]')
end

path = path:gsub('%.md$', '')
local dir, slug = path:match('^([^/]+)/([^/]+)$')
if not dir or not slug then
  fail('the deck goes in a top-level folder: DIR/NAME, e.g. notifications/my-talk')
end
if slug:match('[^%w%-]') then
  fail('NAME should be a slug: lowercase words joined by dashes, e.g. my-talk')
end

local target = path .. '.md'
if read_file(target) then
  fail(target .. ' already exists — pick another name or edit that one')
end

-- "my-talk" reads as "My talk" until a real title is given.
local function title_from (s)
  local words = s:gsub('%-', ' ')
  return (words:gsub('^%l', string.upper))
end

local function git_user ()
  local ok, name = pcall(pandoc.pipe, 'git', { 'config', 'user.name' }, '')
  if ok then name = name:gsub('%s+$', '') end
  return ok and name ~= '' and name or 'Your Name'
end

local title = arg[2]
local values = {
  name = path,
  title = (title and title ~= '') and title or title_from(slug),
  description = (arg[3] and arg[3] ~= '') and arg[3]
    or 'One line on what the talk covers.',
  author = git_user(),
  date = os.date('%Y-%m-%d'),
}

local text = read_file(TEMPLATE)
if not text then fail('cannot read ' .. TEMPLATE) end

text = text:gsub('{{(%w+)}}', function (key)
  return values[key] -- nil leaves the placeholder in place, caught below
end)

local leftover = text:match('{{%w+}}')
if leftover then
  fail(TEMPLATE .. ' uses ' .. leftover .. ', which this script does not fill')
end

pandoc.system.make_directory(dir, true)
local fh = assert(io.open(target, 'w'))
fh:write(text)
fh:close()

print('started ' .. target)
print('build it:  just build-presentation ' .. target)
