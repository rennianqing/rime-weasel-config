-- lua/digit_punct.lua
-- 数字后核心分隔符（, . :）智能处理：
--   1. 在数字（主键盘 0-9、小键盘 KP_0-KP_9 或以数字结尾的词条）后首次输入 , . : 时，直接上屏半角符号；
--   2. 紧接着按下 BackSpace 退格删除该半角符号后，再次输入同一按键时，直接上屏对应的全角符号（， 。 ：）；
--   3. 若删除后改按另一个核心分隔符（如误按 . 后删掉改按 :），仍保留数字后半角输出；
--   4. 仅在中文默认非全角、非英文标点、非拼写组词状态下生效，不影响英文模式、计算器、网址输入及翻页/选词。

local DIGIT_PUNCT_MAP = {
    [","] = "，",
    ["."] = "。",
    [":"] = "：",
}

local function is_modifier_key(keycode)
    -- 保护独立修饰键本身（Shift/Ctrl/Alt/Super 等），避免输入 ":" 前按住 Shift 时误重置状态
    return (keycode >= 0xffe1 and keycode <= 0xffee)
        or (keycode >= 0xfe01 and keycode <= 0xfe0f)
end

local function is_digit_keycode(keycode)
    return (keycode >= 0x30 and keycode <= 0x39)      -- 主键盘 '0'..'9'
        or (keycode >= 0xffb0 and keycode <= 0xffb9)  -- 小键盘 KP_0..KP_9
end

local function ends_with_digit(text)
    return type(text) == "string" and #text > 0 and text:sub(-1):match("%d") ~= nil
end

local function get_latest_commit_text(context)
    local history = context.commit_history
    if history and history.latest_text then
        return history:latest_text()
    end
    return ""
end

local function reset_state(env)
    env.after_digit = false
    env.pending_half = nil
    env.force_full = nil
end

local function commit_direct(env, text)
    env.self_committing = true
    local ok, err = pcall(function()
        env.engine:commit_text(text)
    end)
    env.self_committing = false
    if not ok and log and log.error then
        log.error("[digit_punct] commit_text failed: " .. tostring(err))
    end
end

local processor = {}

function processor.init(env)
    reset_state(env)
    env.self_committing = false

    local context = env.engine.context
    if context.commit_notifier then
        env.commit_notifier = context.commit_notifier:connect(function(ctx)
            if env.self_committing then
                return
            end
            local text = ctx:get_commit_text()
            if not text or #text == 0 then
                text = get_latest_commit_text(ctx)
            end
            env.pending_half = nil
            env.force_full = nil
            env.after_digit = ends_with_digit(text)
        end)
    end

    if context.option_update_notifier then
        env.option_notifier = context.option_update_notifier:connect(function(ctx, name)
            if name == "ascii_mode" or name == "ascii_punct" or name == "full_shape" then
                reset_state(env)
            end
        end)
    end
end

function processor.fini(env)
    if env.commit_notifier then
        env.commit_notifier:disconnect()
        env.commit_notifier = nil
    end
    if env.option_notifier then
        env.option_notifier:disconnect()
        env.option_notifier = nil
    end
end

function processor.func(key, env)
    local context = env.engine.context
    local keycode = key.keycode

    -- 忽略按键释放事件及单纯修饰键
    if key:release() or is_modifier_key(keycode) then
        return 2
    end

    -- 英文模式、英文标点、全角模式或带 Ctrl/Alt/Super 组合键时，重置状态并放行
    if context:get_option("ascii_mode")
        or context:get_option("ascii_punct")
        or context:get_option("full_shape")
        or key:ctrl()
        or key:alt()
        or key:super()
    then
        reset_state(env)
        return 2
    end

    -- 处于拼写组词或候选菜单状态（拼音、网址、计算器、v 模式、选词等）时不拦截
    -- 仅清理重输标点状态，保留 after_digit 以兼容“输入数字后按 Esc 取消组词”场景
    if context:is_composing() or context:has_menu() then
        env.pending_half = nil
        env.force_full = nil
        return 2
    end

    -- 非拼写状态下按下数字键：记录前序为数字
    if is_digit_keycode(keycode) then
        env.after_digit = true
        env.pending_half = nil
        env.force_full = nil
        return 2
    end

    -- 处理退格键（BackSpace = 0xff08）
    if keycode == 0xff08 then
        if env.pending_half and get_latest_commit_text(context) == env.pending_half then
            env.force_full = env.pending_half
            env.pending_half = nil
            env.after_digit = true
        else
            reset_state(env)
        end
        return 2 -- 放行 BackSpace 给宿主应用删除符号
    end

    -- 处理核心数字分隔符（, . :）
    if keycode >= 0x20 and keycode <= 0x7e then
        local ch = string.char(keycode)
        local full_ch = DIGIT_PUNCT_MAP[ch]
        if full_ch then
            -- 1. 退格删除半角符号后再次输入同一按键 -> 输出全角符号
            if env.force_full == ch then
                commit_direct(env, full_ch)
                reset_state(env)
                return 1
            end

            -- 2. 紧跟数字之后（或删除另一个分隔符后改按此符号） -> 直接上屏半角符号
            if env.after_digit or env.force_full ~= nil then
                commit_direct(env, ch)
                env.pending_half = ch
                env.force_full = nil
                env.after_digit = false
                return 1
            end

            -- 3. 普通中文环境 -> 交给后续默认 punctuator 处理
            reset_state(env)
            return 2
        end
    end

    -- 其他非目标按键（空格、回车、方向键、其他符号等） -> 重置状态并放行
    reset_state(env)
    return 2
end

return processor
