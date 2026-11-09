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

5. **实用符号联想（纯净无 Emoji 干扰）**：
   * 原生挂载专用特殊符号库（数学、希腊字母、单位、箭头、图形等）；
   * 支持自然拼音联想常用符号：如输入 cheng 候选出现 ×，输入 chu 出现 ÷，输入 jia 出现 +，输入 jian 出现 -，输入 dengyu 出现 =，输入 gou / dui 出现 √，输入 du 出现 °，输入 pai 出现 π，输入 jiantou 出现 → 等；
   * 严格过滤所有彩色图片表情（Emoji），保持输入面板纯粹专业。

---

## 📁 目录结构

```text
user/
├── opencc/                # 特殊符号转换词库（symbols.json, symbols.txt）
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

## 🚀 安装与部署

### 方式一：一键独立完整安装包（⭐️⭐️⭐️⭐️⭐️ 最推荐，零依赖秒开）
直接下载内置完整引擎、华为鸿蒙黑体与预编译词库的独立安装程序：
* **下载地址**：[Weasel-Setup-v1.1.0-Enhanced.exe (56.9 MB)](https://github.com/rennianqing/rime-weasel-config/releases/download/v1.1.0/Weasel-Setup-v1.1.0-Enhanced.exe)
* **安装特性**：
  1. **零第三方依赖**：自动释放并向 Windows 系统注册华为鸿蒙黑体（`HarmonyOS Sans SC`），无需手动下载安装字体；
  2. **自由选择目录**：默认安装路径为 `D:\Program Files\Rime`，安装时支持在向导界面自由自定义安装盘符与路径；
  3. **跳过首次编译秒开**：随包已封装预编译完成的高性能二进制词库（`build/`），安装完成后自动注册输入法并启动服务，**彻底告别首次部署漫长的 15 秒卡顿**，装完立刻直接打字；
  4. **全套配置预设完毕**：默认即为横排 9 候选词、深色微边框、中英混输、`Ctrl+Alt+P`（置顶）与 `Ctrl+Alt+U`（取消置顶）。

---

### 方式二：已有小狼毫用户配置同步
如果电脑上已经安装过小狼毫，仅需同步配置：
1. 找到小狼毫的 **用户文件夹**（默认位于 `%APPDATA%\Rime`，或安装目录下的自定义 `user` 目录）；
2. 将此仓库代码克隆或解压至该用户目录：
   ```bash
   git clone https://github.com/rennianqing/rime-weasel-config.git .
   ```
3. 右键任务栏小狼毫托盘图标，点击 **「重新部署」**（Deploy）即可生效。
