-- lua/pin_store.lua
-- 维护并持久化用户手动置顶的候选词库
local pin_store = {
    data = {}, -- [code] = { "word1", "word2", ... }
    loaded = false,
    filepath = nil
}

local function get_file_path()
    local rime_api = _G.rime_api
    if not rime_api then
        pcall(function() rime_api = require("rime_api") end)
    end
    local user_dir = (rime_api and rime_api.get_user_data_dir and rime_api.get_user_data_dir())
    if not user_dir or user_dir == "" then
        user_dir = "D:/Program Files/Rime/user"
    end
    return user_dir:gsub("\\", "/") .. "/pinned_candidates.txt"
end

function pin_store.load()
    if pin_store.loaded then return end
    pin_store.filepath = get_file_path()
    pin_store.data = {}

    local f = io.open(pin_store.filepath, "r")
    if f then
        for line in f:lines() do
            line = line:gsub("\r", "")
            if line:sub(1, 1) ~= "#" and line ~= "" then
                local code, text = line:match("^([^\t]+)\t(.+)$")
                if code and text then
                    code = code:gsub("%s+", "")
                    text = text:match("^%s*(.-)%s*$")
                    if #code > 0 and #text > 0 then
                        pin_store.data[code] = pin_store.data[code] or {}
                        table.insert(pin_store.data[code], text)
                    end
                end
            end
        end
        f:close()
    else
        -- 若文件不存在，初始化空文件及说明头
        local wf = io.open(pin_store.filepath, "w")
        if wf then
            wf:write("# 快捷键置顶候选词列表 (Ctrl+Alt+P 自动添加)\n")
            wf:write("# 格式：编码<Tab>字词（支持手动编辑，编辑后重新部署即可生效）\n")
            wf:close()
        end
    end
    pin_store.loaded = true
end

function pin_store.has_any()
    pin_store.load()
    return next(pin_store.data) ~= nil
end

function pin_store.get(code)
    pin_store.load()
    if not code then return nil end
    local clean_code = code:gsub("%s+", "")
    return pin_store.data[clean_code]
end

function pin_store.add(code, text)
    pin_store.load()
    if not code or not text or #code == 0 or #text == 0 then return false end

    local clean_code = code:gsub("%s+", "")
    local list = pin_store.data[clean_code] or {}

    -- 如果已在当前编码的置顶列表中，先移出原位置
    for i = #list, 1, -1 do
        if list[i] == text then
            table.remove(list, i)
        end
    end
    -- 插入到首位
    table.insert(list, 1, text)
    pin_store.data[clean_code] = list

    -- 持久化写入文件
    local f = io.open(pin_store.filepath, "w")
    if f then
        f:write("# 快捷键置顶候选词列表 (Ctrl+Alt+P 自动添加)\n")
        f:write("# 格式：编码<Tab>字词（支持手动编辑，编辑后重新部署即可生效）\n")
        for c, words in pairs(pin_store.data) do
            for _, w in ipairs(words) do
                f:write(c .. "\t" .. w .. "\n")
            end
        end
        f:close()
        return true
    end
    return false
end

return pin_store
