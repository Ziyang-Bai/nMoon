# nMoon

nMoon Alpha 是运行在 TI-Nspire 上的中文 Lua 编辑器。它可以编辑和保存代码、管理文本变量、查找与替换、显示语法高亮、撤销与重做，也可以直接在计算器上运行 Lua 程序。

## 功能

- 编辑 TI-Nspire 文本变量，新建、打开、保存、重命名和删除文件
- 查找上一处或下一处匹配，循环查找并替换当前选择或全部匹配
- 高亮 Lua 语法，检查语法错误
- 撤销和重做编辑
- 运行当前 Lua 代码，查看 `print` 输出和图形预览

## 开始使用

从下方 GitHub Actions 下载 `nMoon.tns`，或按源码构建步骤生成 `dist/nMoon.tns`，再传到 TI-Nspire 并打开。nMoon 使用 TI-Nspire Lua API 2.7。

应用内的“帮助”菜单列出了按键和组合键。常用组合键：

- `Ctrl+N` / `Ctrl+O` / `Ctrl+S`：新建、打开、保存
- `Ctrl+F`：查找
- `Ctrl+Z` / `Ctrl+Y`：撤销、重做
- `Ctrl+R`：运行当前代码
- `Tab`：在图形预览和输出控制台之间切换
- `Esc`：取消操作或退出预览，返回编辑器

在 TI-Nspire 上按 `Ctrl+R` 即可运行当前代码，`print` 输出显示在控制台，`on.paint(gc)` 绘制的内容显示在图形预览中。运行时按 `Tab` 切换两种视图，按 `Esc` 返回编辑器。

运行时可以捕获并显示错误；指令预算仅在提供 `debug.sethook` 的环境中启用，普通 TI Lua 中的循环需自行结束，`Esc` 在回调之间响应。

## 自动构建与下载

每次推送和 Pull Request 都会自动测试并构建，也可以在 [GitHub Actions](https://github.com/Ziyang-Bai/nMoon/actions/workflows/build.yml) 中点击 **Run workflow** 手动构建。

登录 GitHub，打开一次绿色通过的运行，在页面底部的 **Artifacts** 下载 `nMoon` ZIP，解压得到 `nMoon.tns`，传到 TI-Nspire 即可使用。

## 从源码构建

构建会调用 [TnsTools](https://github.com/MaksimirKurtov/TnsTools)。克隆完整的 TnsTools 目录，再安装其中列出的 Python 包。

Windows PowerShell：

```powershell
git clone https://github.com/MaksimirKurtov/TnsTools.git ..\TnsTools
py -m pip install -r ..\TnsTools\requirements.txt
py .\build.py --tnstools ..\TnsTools\tnstools.py
```

通用 shell：

```sh
git clone https://github.com/MaksimirKurtov/TnsTools.git ../TnsTools
python3 -m pip install -r ../TnsTools/requirements.txt
python3 build.py --tnstools ../TnsTools/tnstools.py
```

`--tnstools PATH` 指定 `tnstools.py`。也可以设置 `TNS_TOOLS`：

```powershell
$env:TNS_TOOLS = 'C:\path\to\TnsTools\tnstools.py'
py .\build.py
```

```sh
TNS_TOOLS=/path/to/TnsTools/tnstools.py python3 build.py
```

默认成品是 `dist/nMoon.tns`。`--output PATH` 可以改写输出位置。构建时，`build.py` 将 `src/nMoon.lua` 写入 `build/nMoon.xml` 的副本，调用 TnsTools 生成并校验文档，再写入目标文件。

## 测试

测试需要带 `debug` 库的 Lua 运行时。分别启动全新的 Lua 进程：

```sh
lua -e "dofile('tests/ti_api_mock.lua'); dofile('src/nMoon.lua'); dofile('tests/nMoon_core_test.lua')"
lua -e "dofile('tests/ti_api_mock.lua'); dofile('src/nMoon.lua'); dofile('tests/nMoon_app_test.lua')"
```

两条命令会分别输出 `nMoon core tests: OK` 和 `nMoon app tests: OK`。

## 目录

- `src/nMoon.lua`：编辑器源码
- `build/nMoon.xml/`：TI-Nspire 文档构建配置
- `build.py`：构建入口
- `tests/ti_api_mock.lua`：桌面测试使用的 TI API 实现
- `tests/nMoon_core_test.lua`：编辑器核心测试
- `tests/nMoon_app_test.lua`：文件、界面和代码预览测试

## 许可证

nMoon 使用 [GNU General Public License v3.0](LICENSE)，SPDX 标识为 `GPL-3.0-only`。
