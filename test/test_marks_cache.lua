local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local new_buf = function()
  child.bo.ft = "json"
  child.type_keys("iline1<cr>line2<cr>line3<cr>line4<esc>gg")
end

local get_cache = function(bufnr)
  bufnr = bufnr or child.api.nvim_get_current_buf()
  return child.lua_get("M._marks_cache[" .. bufnr .. "]")
end

local get_extmarks = function(bufnr)
  bufnr = bufnr or child.api.nvim_get_current_buf()
  local ns = child.api.nvim_get_namespaces()["gutter_marks"]
  if not ns then
    return {}
  end
  return child.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
end

local validate_sync = function(cache, extmarks)
  eq(#cache, #extmarks)
  for i, cached_mark in ipairs(cache) do
    local extmark = extmarks[i]
    eq(extmark[2] + 1, cached_mark.line)
  end
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "test/init.lua" })
      child.bo.readonly = false
      child.lua([[M = require('guttermarks')]])
    end,
    post_once = child.stop,
  },
})

T["Cache prevents redundant refresh"] = function()
  new_buf()
  child.type_keys("ma")

  local cache_initial = get_cache()
  local extmarks_initial = get_extmarks()
  eq(#cache_initial, 1)
  eq(cache_initial[1].mark, "a")
  validate_sync(cache_initial, extmarks_initial)

  local result = child.lua_get([[M.refresh()]])
  eq(result, true)

  local cache_after = get_cache()
  local extmarks_after = get_extmarks()
  eq(#cache_after, 1)
  eq(cache_after[1].mark, "a")
  validate_sync(cache_after, extmarks_after)
end

T["Cache invalidated on mark addition"] = function()
  new_buf()
  child.type_keys("ma")
  child.lua([[M.refresh()]])

  local cache1 = get_cache()
  local extmarks1 = get_extmarks()
  eq(#cache1, 1)
  validate_sync(cache1, extmarks1)

  child.type_keys("jmb")
  child.lua([[M.refresh()]])

  local cache2 = get_cache()
  local extmarks2 = get_extmarks()
  eq(#cache2, 2)
  eq(cache2[1].mark, "a")
  eq(cache2[2].mark, "b")
  validate_sync(cache2, extmarks2)
end

T["Cache invalidated on mark deletion"] = function()
  new_buf()
  child.type_keys({ "ma", "j", "mb" })
  child.lua([[M.refresh()]])

  local cache1 = get_cache()
  local extmarks1 = get_extmarks()
  eq(#cache1, 2)
  validate_sync(cache1, extmarks1)

  child.type_keys(":delmarks a<cr>")
  child.lua([[M.refresh()]])

  local cache2 = get_cache()
  local extmarks2 = get_extmarks()
  eq(#cache2, 1)
  eq(cache2[1].mark, "b")
  validate_sync(cache2, extmarks2)
end

T["Cache invalidated on mark movement"] = function()
  new_buf()
  child.type_keys("ma")
  child.lua([[M.refresh()]])

  local cache1 = get_cache()
  local extmarks1 = get_extmarks()
  eq(cache1[1].line, 1)
  validate_sync(cache1, extmarks1)

  child.type_keys("jjma")
  child.lua([[M.refresh()]])

  local cache2 = get_cache()
  local extmarks2 = get_extmarks()
  eq(cache2[1].line, 3)
  validate_sync(cache2, extmarks2)
end

T["Cache is buffer-specific"] = function()
  new_buf()
  local buf1 = child.api.nvim_get_current_buf()
  child.type_keys("ma")
  child.lua([[M.refresh()]])

  local cache_buf1 = get_cache(buf1)
  local extmarks_buf1 = get_extmarks(buf1)
  eq(#cache_buf1, 1)
  eq(cache_buf1[1].mark, "a")
  validate_sync(cache_buf1, extmarks_buf1)

  child.cmd("new")
  child.bo.ft = "json"
  local buf2 = child.api.nvim_get_current_buf()
  child.type_keys("imb_buffer<esc>")
  child.type_keys("mb")
  child.lua([[M.refresh()]])

  local cache_buf2 = get_cache(buf2)
  local extmarks_buf2 = get_extmarks(buf2)
  eq(#cache_buf2, 1)
  eq(cache_buf2[1].mark, "b")
  validate_sync(cache_buf2, extmarks_buf2)

  child.api.nvim_set_current_buf(buf1)
  local cache_buf1_again = get_cache(buf1)
  local extmarks_buf1_again = get_extmarks(buf1)
  eq(#cache_buf1_again, 1)
  eq(cache_buf1_again[1].mark, "a")
  validate_sync(cache_buf1_again, extmarks_buf1_again)
end

T["Cache cleared on buffer delete"] = function()
  new_buf()
  local bufnr = child.api.nvim_get_current_buf()
  child.type_keys("ma")
  child.lua([[M.refresh()]])

  local cache1 = get_cache(bufnr)
  eq(#cache1, 1)

  child.cmd("new")
  child.api.nvim_buf_delete(bufnr, { force = true })

  local cache_after_delete = child.lua_get("M._marks_cache[" .. bufnr .. "]")
  eq(cache_after_delete, vim.NIL)
end

T["mark_types"] = MiniTest.new_set({
  parametrize = {
    { "local", "a", "local_mark" },
    { "global", "A", "global_mark" },
  },
})

T["mark_types"]["Cache handles mark type"] = function(_, mark, mark_type)
  new_buf()
  child.type_keys("m" .. mark)

  local cache = get_cache()
  local extmarks = get_extmarks()
  eq(#cache, 1)
  eq(cache[1].mark, mark)
  eq(cache[1].type, mark_type)
  validate_sync(cache, extmarks)
end

T["Manual cache invalidation"] = function()
  new_buf()
  local bufnr = child.api.nvim_get_current_buf()
  child.type_keys("ma")
  child.lua([[M.refresh()]])

  local cache1 = get_cache()
  local extmarks1 = get_extmarks()
  eq(#cache1, 1)
  validate_sync(cache1, extmarks1)

  child.lua("M._marks_cache[" .. bufnr .. "] = nil")
  local cache_cleared = get_cache()
  eq(cache_cleared, vim.NIL)

  child.lua([[M.refresh()]])
  local cache2 = get_cache()
  local extmarks2 = get_extmarks()
  eq(#cache2, 1)
  eq(cache2[1].mark, "a")
  validate_sync(cache2, extmarks2)
end

T["Cache with multiple marks"] = function()
  new_buf()
  child.type_keys({ "ma", "j", "mb", "j", "mc" })
  child.lua([[M.refresh()]])

  local cache1 = get_cache()
  local extmarks1 = get_extmarks()
  eq(#cache1, 3)
  validate_sync(cache1, extmarks1)

  child.type_keys("ggma")
  child.lua([[M.refresh()]])

  local cache2 = get_cache()
  local extmarks2 = get_extmarks()
  eq(#cache2, 3)
  eq(cache2[1].line, 1)
  eq(cache2[2].line, 2)
  eq(cache2[3].line, 3)
  validate_sync(cache2, extmarks2)
end

T["Cache empty when no marks"] = function()
  new_buf()
  child.lua([[M.refresh()]])

  local cache = get_cache()
  local extmarks = get_extmarks()
  eq(#cache, 0)
  eq(#extmarks, 0)
end

T["Cache not used when plugin disabled"] = function()
  new_buf()
  child.type_keys("ma")
  child.lua([[M.refresh()]])

  local cache1 = get_cache()
  local extmarks1 = get_extmarks()
  eq(#cache1, 1)
  validate_sync(cache1, extmarks1)

  child.lua([[M.enable(false)]])
  local result = child.lua_get([[M.refresh()]])
  eq(result, false)

  local cache2 = get_cache()
  local extmarks2 = get_extmarks()
  eq(cache2, vim.NIL)
  eq(#extmarks2, 0)
end

return T
