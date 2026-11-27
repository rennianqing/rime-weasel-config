-- lua/ascii_debounce.lua
-- 引擎内生中英文切换防回弹消抖处理器（零外部守护依赖）
-- 解决 Windows 系统 Ctrl+Space (OPENCLOSE) 在 32 位 IMM32/CUAS 应用（如 Axure RP 9）中
-- 因 WeaselTSF::_HandleCompartment -> _SetKeyboardOpen(true) 引发的毫秒级二次翻转问题：
--   1. 异步二次翻转：(false -> true -> false)，在 200ms 锁定窗口内拦截回弹并保持目标状态；
--   2. 同步重入翻转：WeaselTSF 栈重入导致连续发送两次相同原状态 (false, false) 或 (true, true)，
--      在 60ms 窗口内识别成对重入脉冲并执行真实翻转；
--   3. 正常单次切换（64 位原生 TSF 应用、托盘图标点击、key_binder）直接放行，互不干扰。

local DEBOUNCE_SEC = 0.20   -- 真实翻转后的防回弹锁定窗口（200ms）
local SYNC_PAIR_SEC = 0.06  -- 同步栈重入双同值脉冲识别窗口（60ms）

local processor = {}

function processor.init(env)
    local context = env.engine.context
    env.in_guard = false
    env.stable_val = context:get_option("ascii_mode") or false
    env.last_flip_clock = -10.0
    env.last_same_clock = -10.0

    if context.option_update_notifier then
        env.notifier_conn = context.option_update_notifier:connect(function(ctx, name)
            if name ~= "ascii_mode" or env.in_guard then
                return
            end

            local now = os.clock()
            local cur = ctx:get_option("ascii_mode") or false

            -- 1. 处于真实翻转后的 200ms 消抖锁定窗口内：强制维持已锁定的目标状态，屏蔽一切回弹
            local since_flip = now - env.last_flip_clock
            if since_flip >= 0 and since_flip < DEBOUNCE_SEC then
                if cur ~= env.stable_val then
                    env.in_guard = true
                    ctx:set_option("ascii_mode", env.stable_val)
                    env.in_guard = false
                end
                return
            end

            -- 2. 锁定窗口外收到与当前状态相反的值：合法的真实切换（单次 TSF / 托盘点击 / 失步自愈）
            if cur ~= env.stable_val then
                env.stable_val = cur
                env.last_flip_clock = now
                env.last_same_clock = -10.0
                return
            end

            -- 3. 锁定窗口外收到与当前状态相同的值：检测是否为 60ms 内的同步重入双脉冲 (same, same)
            local since_same = now - env.last_same_clock
            if since_same >= 0 and since_same < SYNC_PAIR_SEC then
                local target = not env.stable_val
                env.stable_val = target
                env.last_flip_clock = now
                env.last_same_clock = -10.0
                env.in_guard = true
                ctx:set_option("ascii_mode", target)
                env.in_guard = false
            else
                env.last_same_clock = now
            end
        end)
    end
end

function processor.fini(env)
    if env.notifier_conn then
        env.notifier_conn:disconnect()
        env.notifier_conn = nil
    end
end

function processor.func(key, env)
    return 2 -- kNoop：不拦截任何按键，仅通过 option_update_notifier 维护状态一致性
end

return processor
