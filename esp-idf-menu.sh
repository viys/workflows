#!/bin/bash

# 显示菜单
show_menu() {
    echo "请选择要执行的命令："
    echo "1. 创建项目 (create-project)"
    echo "2. 设置目标芯片 (set-target)"
    echo "3. 编译项目 (build)"
    echo "4. 配置项目 (menuconfig)"
    echo "5. 打开ESP IDF容器终端 (bash)"
    echo "6. 启动串口服务器 (esp_rfc2217_server)"
    echo "7. 烧录程序 (flash)"
    echo "8. 串口监视器 (monitor)"
    echo "0. 退出"
}

# 检查并安装 esptool
ensure_esptool() {
    TOOL_PATH="scripts/esptool-linux64"
    if [ ! -d "$TOOL_PATH" ]; then
        echo "未找到 $TOOL_PATH，正在运行 install_esptool.py 以安装所需工具..."
        INSTALL_SCRIPT="scripts/install_esptool.py"
        if [ -f "$INSTALL_SCRIPT" ]; then
            python3 "$INSTALL_SCRIPT"
            if [ ! -d "$TOOL_PATH" ]; then
                echo "安装失败，目录仍然不存在：$TOOL_PATH"
                return 1
            fi
        else
            echo "安装脚本未找到：$INSTALL_SCRIPT"
            return 1
        fi
    fi
    return 0
}

# 运行命令
run_command() {
    case $1 in
        1)
            read -p "请输入目标项目名称: " proj
            docker-compose run --rm esp-idf idf.py create-project "$proj"
            exit
            ;;
        2)
            read -p "请输入目标芯片名称（如：esp32）: " target
            docker-compose run --rm esp-idf idf.py set-target "$target"
            exit
            ;;
        3)
            docker-compose run --rm esp-idf idf.py build
            exit
            ;;
        4)
            docker-compose run --rm esp-idf idf.py menuconfig
            exit
            ;;
        5)
            docker-compose run --rm esp-idf bash
            exit
            ;;
        6)
            read -p "请输入目标串口设备名称（如：/dev/ttyUSB0）: " port
            if ensure_esptool; then
                pushd "scripts/esptool-linux64"
                ./esp_rfc2217_server -v -p 4000 "$port"
                popd
                exit
            fi
            ;;
        7)
            docker-compose run --rm esp-idf idf.py --port "rfc2217://host.docker.internal:4000?ign_set_control" flash
            exit
            ;;
        8)
            docker-compose run --rm esp-idf idf.py --port "rfc2217://host.docker.internal:4000?ign_set_control" monitor
            exit
            ;;
        0)
            echo "退出。"
            exit
            ;;
        *)
            echo "无效选择，请重试。"
            ;;
    esac
}

while true; do
    show_menu
    read -p "请输入数字选择（如 1-8 或 0 退出）: " selection
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        run_command "$selection"
    else
        echo "无效输入，请输入有效数字（0-8）。"
    fi
done
