# 字体目录

此目录用于存放游戏中使用的中文字体文件。

## 需要的字体

游戏需要以下字体才能正常显示中文：

| 字体文件 | 说明 | 来源 |
|---------|------|------|
| `simhei.ttf` | 黑体（推荐） | Windows 系统自带 |
| `simkai.ttf` | 楷体（备选） | Windows 系统自带 |
| `msyh.ttc` | 微软雅黑 | Windows 系统自带 |

## 安装方法

### 方法 1：复制系统字体（推荐）

从 `C:\Windows\Fonts\` 目录复制字体文件到此目录：

```powershell
# 复制黑体（推荐）
copy "C:\Windows\Fonts\simhei.ttf" "assets\fonts\"

# 或复制楷体
copy "C:\Windows\Fonts\simkai.ttf" "assets\fonts\"
```

### 方法 2：下载开源字体

也可以下载开源中文字体放到此目录，如：
- [思源黑体 (Noto Sans CJK)](https://github.com/notofonts/noto-cjk)
- [思源宋体 (Noto Serif CJK)](https://github.com/notofonts/noto-cjk)
- [文泉驿字体](http://wenq.org/)

## 字体加载优先级

游戏会按以下顺序尝试加载字体：
1. `assets/fonts/simhei.ttf` (项目内黑体)
2. `assets/fonts/simkai.ttf` (项目内楷体)
3. `C:/Windows/Fonts/simhei.ttf` (系统黑体)
4. `C:/Windows/Fonts/simkai.ttf` (系统楷体)

如果都找不到，中文将显示为方框。
