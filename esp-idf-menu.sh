#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/project"

function ensure_esptool() {
    if ! command -v esp_rfc2217_server.py >/dev/null 2>&1; then
        echo "esp_rfc2217_server.py 未安装，尝试使用 pip install esptool"
        pip install --user esptool || {
            echo "安装失败，请手动安装 esptool。" >&2
            exit 1
        }
    fi
}

function select_project() {
    echo "正在查找 project 目录下的 ESP-IDF 项目..."

    local projects=()
    for dir in "$PROJECT_DIR"/*/; do
        if [[ -f "$dir/CMakeLists.txt" ]]; then
            projects+=("$(basename "$dir")")
        fi
    done

    if [[ ${#projects[@]} -eq 0 ]]; then
        echo "未找到任何项目。"
        return 1
    fi

    echo ""
    echo "请选择一个项目："
    for i in "${!projects[@]}"; do
        echo "$((i+1)). ${projects[$i]}"
    done

    read -rp "请输入编号：" index
    if [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 1 && index <= ${#projects[@]} )); then
        SELECTED_PROJECT="${projects[$((index-1))]}"
        echo "已选择项目：$SELECTED_PROJECT"
        return 0
    else
        echo "输入无效。"
        return 1
    fi
}

function show_menu() {
    echo ""
    echo "===== ESP-IDF Docker 菜单 ====="
    echo "1. 创建项目"
    echo "2. 设置目标芯片"
    echo "3. 编译项目"
    echo "4. 配置项目 (menuconfig)"
    echo "5. 打开容器终端"
    echo "6. 启动串口服务器"
    echo "7. 烧录程序"
    echo "8. 串口监视器"
    echo "0. 退出"
}

function main_loop() {
    while true; do
        show_menu
        read -rp "请输入数字选择: " choice

        case $choice in
            1)
                read -rp "请输入项目名称：" proj
                docker-compose run --rm esp-idf idf.py create-project "$proj"
                ;;
            2|3|4|7|8)
                if select_project; then
                    project_path="/project/$SELECTED_PROJECT"
                    case $choice in
                        2)
                            read -rp "请输入目标芯片（如 esp32s3）：" chip
                            docker-compose run --rm -w "$project_path" esp-idf idf.py set-target "$chip"
                            ;;
                        3)
                            docker-compose run --rm -w "$project_path" esp-idf idf.py build
                            ;;
                        4)
                            docker-compose run --rm -w "$project_path" esp-idf idf.py menuconfig
                            ;;
                        7)
                            docker-compose run --rm -w "$project_path" esp-idf idf.py --port "rfc2217://host.docker.internal:4000?ign_set_control" flash
                            ;;
                        8)
                            docker-compose run --rm -w "$project_path" esp-idf idf.py --port "rfc2217://host.docker.internal:4000?ign_set_control" monitor
                            ;;
                    esac
                fi
                ;;
            5)
                docker-compose run --rm esp-idf bash
                ;;
            6)
                ensure_esptool
                read -rp "请输入主机串口设备（如 /dev/ttyUSB0）：" dev
                esp_rfc2217_server.py -v -p 4000 "$dev"
                ;;
            0)
                echo "退出。"
                exit 0
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done
}

main_loop
