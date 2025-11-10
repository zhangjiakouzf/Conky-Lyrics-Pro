# Conky Lyrics Pro 🎤✨
a Lyrics Prompter with conky and playerctl

**桌面歌词题词器**  
实时同步高亮 · 歌词缓存 · 多版本切换 · 字体调节 · 拖动定位 · 位置记忆

https://github.com/zhangjiakouzf/Conky-Lyrics-Pro/blob/main/assets/conky-lyrics-pro_demo.gif
---

## ✨ 特性一览

| 功能 | 描述 |
|------|------|
| 🌍 **通过lrclib.net获取歌词** | 免费开源歌词源，覆盖广泛<BR>（中文歌曲歌词以繁体字居多，一定要找一个合适的字体文件）|
| ⏰ **实时同步高亮** | 当前句高亮显示<BR>（每一句进度显示可能不太准，因为是使用LRC格式，以下一句开始作为本句结束，中间每个字发音时间无法精确确定） |
| 💾 **本地缓存** | SQLite3 缓存，避免重复请求，主要还是为了尽可能显示准确的歌词<BR>（网络获取的歌词时间戳经常对不上，需要在多个版本中找到尽可能合适的） |
| 🔄 **多版本切换** | `-` / `=/+` 键切换不同翻译/音译版本 <BR>每次切换歌词都会保存一次，方便下次从DB读取正确歌词|
| 🔠 **字体动态调节** | `a` / `s` 键放大缩小字体<BR>(每次设置完字体大小都要重启conky，响应速度慢，后期会优化) |
| ⌨️ **键盘交互** | `q` 退出（ctrl+c也可以） |
| 🖱️ **窗口可拖动** | Conky 透明无边框，支持自由拖动<BR>（需要按住window action键，fedora42的默认是“super“键，也就是win键） |

---

## 📸 效果展示

![demo](assets/conky-lyrics-pro_demo.gif)

---

## 🚀 快速开始

### 依赖安装（fedora,其他发行版类似）
我的开发测试环境是Fedora 42，其他版本没有测试过，大家如果遇到问题请提ISSUE
```bash
sudo dnf install conky playerctl curl jq sqlite3 coreutils gawk
```
### 安装(不用安装，直接运行)
```bash
git clone https://github.com/zhangjiakouzf/Conky-Lyrics-Pro.git
cd Conky-Lyrics-Pro
chmod +x conky-lyrics-pro.sh
./conky-lyrics-pro.sh
```
## ❤TODO
- 歌词时间戳调整
- 手动歌词编辑
## 其他
### `LICENSE`（MIT）

```text
MIT License

Copyright (c) 2025 miles

Permission is hereby granted, free of charge, to any person obtaining a copy...

## 版本
### [1.1-20251110] - 2025-11-10
- 多版本歌词切换（-/+）
- 字体大小调节（a/s）
- 位置记忆（开发中）
- SQLite 缓存系统