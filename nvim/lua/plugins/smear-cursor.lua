-- smear-cursor.nvim: https://github.com/sphamba/smear-cursor.nvim
-- 光标平滑移动 + 拖尾效果。随时可用 :SmearCursorToggle 开关。
return {
  "sphamba/smear-cursor.nvim",
  opts = {
    -- Windows Terminal 默认字体 Cascadia Mono/Code 支持 legacy computing symbols(块状字符),
    -- 开 true 后拖尾/粒子混色更平滑、阴影更小。
    -- 若你换了不支持该字形的字体(如 Consolas/雅黑), 光标处会出现方块, 改回 false。
    legacy_computing_symbols_support = true,

    -- 光标(拖尾)颜色: 默认取 nvim 的 Cursor 高亮色;
    -- 但 Windows Terminal 会用自身 cursorColor 覆盖实际光标颜色,
    -- 导致拖尾色和真实光标不一致时, 取消注释并填终端里看到的真实光标色(或用 "none" 跟随文字色):
    -- cursor_color = "#d3cdc3",

    -- ---- 手感调参(默认值较柔和, 想更"跟手"取消注释) ----
    -- stiffness = 0.8,               -- 头部的跟随速度 [0,1]
    -- trailing_stiffness = 0.6,      -- 尾部的跟随速度 [0,1]
    -- damping = 0.95,                -- 减速/回弹, 调低(如0.65)更弹
    -- time_interval = 7,             -- 动画帧间隔(ms), 觉得掉帧才需要调
    -- ---- 粒子(火花)效果, 默认关 ----
    -- particles_enabled = true,      -- 开 true 时建议同时开 never_draw_over_target
    -- never_draw_over_target = true, -- 让拖尾不盖住目标字符
  },
}
