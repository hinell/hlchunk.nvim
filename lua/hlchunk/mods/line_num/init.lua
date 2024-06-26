local BaseMod = require("hlchunk.mods.base_mod")
local LineNumConf = require("hlchunk.mods.line_num.line_num_conf")

local class = require("hlchunk.utils.class")
local utils = require("hlchunk.utils.utils")

local api = vim.api
local CHUNK_RANGE_RET = utils.CHUNK_RANGE_RET

---@class LineNumMetaInfo : MetaInfo

local constructor = function(self, conf, meta)
    local default_meta = {
        name = "line_num",
        augroup_name = "hlchunk_line_num",
        hl_base_name = "HLLineNum",
        ns_id = api.nvim_create_namespace("line_num"),
    }

    BaseMod.init(self, conf, meta)
    self.meta = vim.tbl_deep_extend("force", default_meta, meta or {})
    self.conf = LineNumConf(conf)
    -- vim.notify(vim.inspect(self))
end

---@class LineNumMod : BaseMod
---@field conf LineNumConf
---@field meta LineNumMetaInfo
---@field render fun(self:LineNumMod)
---@overload fun(conf?: UserLineNumConf, meta?: MetaInfo): LineNumMod
local LineNumMod = class(BaseMod, constructor)

function LineNumMod:render()
    if not self:shouldRender() then
        return
    end

    self:clear()

    local retcode, cur_chunk_range = utils.get_chunk_range(self, nil, {
        use_treesitter = self.conf.use_treesitter,
    })
    if retcode ~= CHUNK_RANGE_RET.OK then
        return
    end

    local beg_row = cur_chunk_range.start
    local end_row = cur_chunk_range.finish
    local row_opts = {
        number_hl_group = self.meta.hl_name_list[1],
    }
    for i = beg_row, end_row do
        api.nvim_buf_set_extmark(0, self.meta.ns_id, i, 0, row_opts)
    end
end

function LineNumMod:createAutocmd()
    BaseMod.createAutocmd(self)

    api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = self.meta.augroup_name,
        callback = function()
            self:render()
        end,
    })
end

return LineNumMod
