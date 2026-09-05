# nMoon

nMoon Alpha 是运行在 TI-Nspire 上的中文 Lua 编辑器。它可以编辑和保存代码、管理文本变量、查找与替换、显示语法高亮、撤销与重做，还能直接预览 Lua 程序。

## 功能

- 编辑 TI-Nspire 文本变量，新建、打开、保存、重命名和删除文件
- 查找上一处或下一处匹配，循环查找并替换当前选择或全部匹配
- 高亮 Lua 语法，检查语法错误
- 撤销和重做编辑
- 运行当前代码，在图形预览和输出控制台之间切换
- 用指令预算中断可能陷入死循环的预览代码

## 开始使用

仓库保存源码和构建配置；`build.py` 把成品写入 `dist/`。完成下方构建后，将 `dist/nMoon.tns` 传到 TI-Nspire 并打开。nMoon 使用 TI-Nspire Lua API 2.7。

应用内的“帮助”菜单列出了按键和组合键。常用组合键：

- `Ctrl+N` / `Ctrl+O` / `Ctrl+S`：新建、打开、保存
- `Ctrl+F`：查找
- `Ctrl+Z` / `Ctrl+Y`：撤销、重做
- `Ctrl+R`：运行当前代码
- `Tab`：在图形预览和输出控制台之间切换
- `Esc`：取消操作或退出预览

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
