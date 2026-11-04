# Rime 小狼毫（Weasel）输入法定制配置方案

本项目为 Windows 平台小狼毫（Weasel）输入法的高质量精简定制配置方案，基于社区优秀的 **雾凇拼音（rime-ice）** 进行现代化精简与深度定制。

---

## 🌟 核心特性

1. **专注中文全拼输入**：
   * 采用精校现代汉语词库（`8105` 常用字表、`base` 基础词库、`ext` 扩展词库、`tencent` 词向量）；
   * 剔除所有冗余的双拼方案字典、九宫格模块及未启用的 Unihan 生僻大字表，轻量纯粹。

2. **免切换中英混输与单词联想**：
   * 原生挂载 `melt_eng`（墨奇英汉词库）；
   * 中文输入状态下直接键入英文字母（如 `appl`）即可实时获得 `apple` 等单词补全及中文释义；
   * 具备智能大写（`autocap_filter`）与英文候选降频（`reduce_english_filter`）机制，互不干扰。

3. **快捷键自由置顶与取消置顶**：
   * **强制置顶**：**`Ctrl + Alt + P`**（**P** = **P**in）。候选框出现时选中目标词按下，该词瞬间锁定至第 1 位；
   * **取消置顶**：**`Ctrl + Alt + U`**（**U** = **U**npin）。选中已置顶词按下，立即恢复正常词频排序；
   * 置顶规则自动写入并持久化保存在 `pinned_candidates.txt` 中。

4. **现代化 UI 与字体精修**：
   * **配色方案**：`dark_temple`（深灰高对比度暗黑武士风格）；
   * **轮廓质感**：现代 Windows 11 Fluent 风格，`8px` 窗口大圆角、`6px` 候选色块圆角与 `1px` 精致石墨灰立体细边框（`#444444`），彻底告别深色背景融色与直角生硬感；
   * **候选词字体**：`HarmonyOS Sans SC`（华为鸿蒙黑体，字形端正锐利）；
   * **序号字体**：`Segoe UI`（修长现代西文字体）；
   * **候选词个数**：横排 **9 个候选词**，字号微调至 `15pt`，间距层次分明；
   * **Emoji 净化**：彻底禁用并移除了图片表情干扰。

---

## 📁 目录结构

```text
user/
├── cn_dicts/              # 中文词库（8105, base, ext, tencent, others）
├── en_dicts/              # 英汉混输词库（cn_en, en, en_ext）
├── lua/                   # Lua 扩展脚本
│   ├── pin_candidate.lua  # Ctrl+Alt+P 置顶与 Ctrl+Alt+U 取消置顶处理器
│   ├── pin_store.lua      # 置顶词内存管理与文件持久化
│   ├── pin_cand_filter.lua# 置顶候选项排序滤镜
│   ├── date_translator.lua# 日期时间快捷输入（rq, sj）
│   ├── corrector.lua      # 错音错字纠错提示
│   └── ...
├── pinned_candidates.txt  # 用户快捷键置顶词库
├── custom_phrase.txt      # 自定义短语词库
├── default.yaml           # 全局默认配置（仅启用 rime_ice，候选词 9 个）
├── default.custom.yaml    # 全局自定义补丁
├── weasel.yaml            # 小狼毫前端外观设定（字体、字号、横排）
├── weasel.custom.yaml     # 前端补丁（绑定 dark_temple 主题）
├── rime_ice.schema.yaml   # 雾凇拼音全拼方案配置
├── rime_ice.dict.yaml     # 词库主索引
├── melt_eng.schema.yaml   # 英文方案配置
└── radical_pinyin.*       # 拆字反查支持
```

---

## 🚀 安装与同步使用

### 在新机器上同步此配置：
1. 下载并安装 [小狼毫输入法（Weasel）](https://rime.im/)；
2. 找到小狼毫的 **用户文件夹**（默认位于 `%APPDATA%\Rime`，或安装目录下的自定义 `user` 目录）；
3. 将此仓库代码克隆或解压至该用户目录：
   ```bash
   git clone https://github.com/rennianqing/rime-weasel-config.git .
   ```
4. 右键任务栏小狼毫托盘图标，点击 **「重新部署」**（Deploy）即可完成安装。
