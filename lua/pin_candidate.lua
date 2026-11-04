-- lua/pin_candidate.lua
-- 处理快捷键：
--   Ctrl + Alt + P: 将当前选中的候选词强制置顶（Pin）
--   Ctrl + Alt + U: 将当前选中的候选词取消置顶（Unpin）
local pin_store = require("pin_store")

local processor = {}

function processor.init(env)
    pin_store.load()
end

function processor.func(key, env)
    local context = env.engine.context

    -- 只有按键按下且当前存在候选菜单时才处理
    if not key:release() and context:has_menu() then
        local repr = key:repr()
        local is_p = (key.keycode == 112 or key.keycode == 80) -- 'p' 或 'P'
        local is_u = (key.keycode == 117 or key.keycode == 85) -- 'u' 或 'U'
        local is_ctrl_alt = key:ctrl() and key:alt() and not key:shift()

        local is_ctrl_alt_p = (is_ctrl_alt and is_p)
            or (repr == "Control+Alt+p" or repr == "Control+Alt+P" or repr == "Alt+Control+p" or repr == "Alt+Control+P")
        local is_ctrl_alt_u = (is_ctrl_alt and is_u)
            or (repr == "Control+Alt+u" or repr == "Control+Alt+U" or repr == "Alt+Control+u" or repr == "Alt+Control+U")

        if is_ctrl_alt_p or is_ctrl_alt_u then
            local cand = context:get_selected_candidate()
            if cand then
                local text = cand.text
                local code = cand.preedit and cand.preedit:gsub("%s+", "")
                if not code or #code == 0 then
                    code = context.input and context.input:gsub("%s+", "")
                end

                if text and #text > 0 and code and #code > 0 then
                    if is_ctrl_alt_p then
                        pin_store.add(code, text)
                    else
                        pin_store.remove(code, text)
                    end
                    -- 刷新当前输入组合，使候选词列表与置顶状态即时更新
                    if context.refresh_non_confirmed_composition then
                        context:refresh_non_confirmed_composition()
                    end
                    return 1 -- 消费该按键，不向下传递
                end
            end
        end
    end

    -- 释放该按键，交给后续处理器
    return 2
end

return processor
