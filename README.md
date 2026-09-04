# nMoon

nMoon 是面向 TI-Nspire 的中文 Lua 编辑器。它在计算器文档中提供文本编辑、变量文件管理、查找与替换、语法高亮、撤销与重做，以及带指令预算保护的 Lua 代码预览和运行输出。

## 使用

将发布产物 `nMoon.tns` 传输到 TI-Nspire 并打开。当前脚本声明 TI-Nspire Lua API 2.7。

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
- `nMoon.tns`：可直接传输的发布产物

## 测试

需要可用的 Lua 运行时及 `debug` 库。两组测试应分别在全新的 Lua 进程中运行：

```sh
lua -e "dofile('tests/ti_api_mock.lua'); dofile('src/nMoon.lua'); dofile('tests/nMoon_core_test.lua')"
lua -e "dofile('tests/ti_api_mock.lua'); dofile('src/nMoon.lua'); dofile('tests/nMoon_app_test.lua')"
```

成功时分别输出 `nMoon core tests: OK` 和 `nMoon app tests: OK`。

## 构建

构建依赖支持 TI-Nspire method 13 的 `tnstools.py`；该工具不包含在本仓库中。使用仓库内已同步好的 XML 输入生成并回读校验产物：

```sh
python path/to/tnstools.py -xml build/nMoon.xml -out nMoon.tns --verify
```

`--verify` 会解包新生成的文档并逐字节核对 XML。发布前还应确认 `build/nMoon.xml/Problem1.xml` 中的脚本与 `src/nMoon.lua` 一致。

## 许可证

本项目仅按 GNU General Public License version 3 发布，SPDX 许可证标识为 **GPL-3.0-only**。完整条款见 [LICENSE](LICENSE)。
