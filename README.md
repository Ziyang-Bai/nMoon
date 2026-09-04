# nMoon

nMoon 是面向 TI-Nspire 的中文 Lua 编辑器。它在计算器文档中提供文本编辑、变量文件管理、查找与替换、语法高亮、撤销与重做，以及带指令预算保护的 Lua 代码预览和运行输出。

## 使用

按照下方“构建”说明从源码生成 `dist/nMoon.tns`，再将其传输到 TI-Nspire 并打开。当前脚本声明 TI-Nspire Lua API 2.7。

应用内“帮助”菜单列出了按键和组合键；常用组合键包括：

- `Ctrl+N` / `Ctrl+O` / `Ctrl+S`：新建、打开、保存
- `Ctrl+F`：查找
- `Ctrl+Z` / `Ctrl+Y`：撤销、重做
- `Ctrl+R`：运行当前代码
- `Esc`：取消当前操作或退出预览

## 项目结构

- `src/nMoon.lua`：应用源代码
- `tests/ti_api_mock.lua`：桌面 Lua 测试所用的 TI API 替身
- `tests/nMoon_core_test.lua`：编辑器核心行为测试
- `tests/nMoon_app_test.lua`：文件、界面与代码预览行为测试
- `build/nMoon.xml/`：用于生成 TI-Nspire 文档的 XML 输入
- `build.py`：从源码生成并校验 TI-Nspire 文档的跨平台构建入口

## 测试

需要可用的 Lua 运行时及 `debug` 库。两组测试应分别在全新的 Lua 进程中运行：

```sh
lua -e "dofile('tests/ti_api_mock.lua'); dofile('src/nMoon.lua'); dofile('tests/nMoon_core_test.lua')"
lua -e "dofile('tests/ti_api_mock.lua'); dofile('src/nMoon.lua'); dofile('tests/nMoon_app_test.lua')"
```

成功时分别输出 `nMoon core tests: OK` 和 `nMoon app tests: OK`。

## 构建

构建以 `src/nMoon.lua` 为唯一源码，并依赖支持 TI-Nspire method 13 的
[TnsTools](https://github.com/MaksimirKurtov/TnsTools)。先获取完整的 TnsTools
目录并按其说明安装依赖；`tnstools.py` 同目录下的模块也必须保留。

Windows PowerShell 示例：

```powershell
git clone https://github.com/MaksimirKurtov/TnsTools.git ..\TnsTools
py -m pip install -r ..\TnsTools\requirements.txt
py .\build.py --tnstools ..\TnsTools\tnstools.py
```

通用 shell 示例：

```sh
git clone https://github.com/MaksimirKurtov/TnsTools.git ../TnsTools
python3 -m pip install -r ../TnsTools/requirements.txt
python3 build.py --tnstools ../TnsTools/tnstools.py
```

也可通过环境变量提供工具路径：

```powershell
$env:TNS_TOOLS = 'C:\path\to\TnsTools\tnstools.py'
py .\build.py
```

```sh
TNS_TOOLS=/path/to/TnsTools/tnstools.py python3 build.py
```

默认输出为 `dist/nMoon.tns`；可用 `--output PATH` 指定其他位置。构建脚本会将
`build/nMoon.xml/` 复制到系统临时目录，把正确 XML 转义后的 `src/nMoon.lua`
写入临时 `Problem1.xml`，调用 TnsTools 构建并执行 `--verify`，成功后才原子替换
目标文件。`.tns` 编译产物不纳入版本控制，需要时请在本地重新构建。

## 许可证

本项目仅按 GNU General Public License version 3 发布，SPDX 许可证标识为 **GPL-3.0-only**。完整条款见 [LICENSE](LICENSE)。
