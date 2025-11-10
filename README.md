# Conky Lyrics Pro 🎤✨
a Lyrics Prompter with conky and playerctl

**专业级桌面歌词显示器**  
实时同步高亮 · 歌词缓存 · 多版本切换 · 字体调节 · 拖动定位 · 位置记忆

https://github.com/yourname/Conky-Lyrics-Pro/assets/demo.gif

---

## ✨ 特性一览

| 功能 | 描述 |
|------|------|
| ⏰ **实时同步高亮** | 精准到毫秒，当前句高亮显示 |
| 💾 **本地缓存** | SQLite 缓存，避免重复请求 |
| 🔄 **多版本切换** | `-` / `=` 键切换不同翻译/音译版本 |
| 🔠 **字体动态调节** | `a` / `s` 键放大缩小字体 |
| 🖱️ **窗口可拖动** | Conky 透明无边框，支持自由拖动（需要安装window action键，fedora42的默认是“super“键） |
| 🌍 **支持 lrclib.net** | 免费开源歌词源，覆盖广泛 |
| ⌨️ **键盘交互** | `q` 退出，`-/+` 切换歌词 |

---

## 📸 效果展示

![demo](assets/demo1.gif)

---

## 🚀 快速开始
### 安装(不用安装，直接运行)

```bash
git clone https://github.com/yourname/Conky-Lyrics-Pro.git
cd Conky-Lyrics-Pro
chmod +x conky-lyrics-pro.sh
./conky-lyrics-pro.sh
```

### 依赖安装（fedora,其他发行版类似）
我的开发测试环境是Fedora 42，其他版本没有测试过，大家如果遇到问题请提ISSUE
```bash
sudo dnf install conky playerctl curl jq sqlite3 coreutils gawk

