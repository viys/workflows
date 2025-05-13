# esp-idf-menu.ps1

function Show-Menu {
    Write-Host "请选择要执行的命令："
    Write-Host "1. 创建项目 (create-project)"
    Write-Host "2. 设置目标芯片 (set-target)"
    Write-Host "3. 编译项目 (build)"
    Write-Host "4. 配置项目 (menuconfig)"
    Write-Host "5. 打开ESP IDF容器终端 (bash)"
    Write-Host "6. 启动串口服务器 (esp_rfc2217_server)"
    Write-Host "7. 烧录程序 (flash)"
    Write-Host "8. 串口监视器 (monitor)"
    Write-Host "0. 退出"
}

# 检查并安装 esptool
function Ensure-Esptool {
    $toolPath = "scripts\esptool-win64"
    if (-Not (Test-Path $toolPath)) {
        Write-Host "未找到 $toolPath，正在运行 install_esptool.py 以安装所需工具..."
        $installScript = "scripts\install_esptool.py"
        if (Test-Path $installScript) {
            python $installScript
            if (-Not (Test-Path $toolPath)) {
                Write-Error "安装失败，目录仍然不存在：$toolPath"
                return $false
            }
        } else {
            Write-Error "安装脚本未找到：$installScript"
            return $false
        }
    }
    return $true
}

function Run-Command {
    param (
        [int]$Choice
    )

    switch ($Choice) {
        1 {
            $proj = Read-Host "请输入目标项目名称"
            docker-compose run --rm esp-idf idf.py create-project $proj
            exit
        }
        2 {
            $target = Read-Host "请输入目标芯片名称（如：esp32）"
            docker-compose run --rm esp-idf idf.py set-target $target
            exit
        }
        3 {
            docker-compose run --rm esp-idf idf.py build
            exit
        }
        4 {
            docker-compose run --rm esp-idf idf.py menuconfig
            exit
        }
        5 {
            docker-compose run --rm esp-idf bash
            exit
        }
        6 {
            # 询问串口端口
            $port = Read-Host "请输入目标串口设备名称（如：COM3）"
            if (Ensure-Esptool) {
                Push-Location "scripts\esptool-win64"
                .\esp_rfc2217_server -v -p 4000 $port
                Pop-Location
                exit
            }
        }
        7 {
            docker-compose run --rm esp-idf idf.py --port "rfc2217://host.docker.internal:4000?ign_set_control" flash
            exit
        }
        8 {
            docker-compose run --rm esp-idf idf.py --port "rfc2217://host.docker.internal:4000?ign_set_control" monitor
            exit
        }
        0 {
            Write-Host "退出。"
            exit
        }
        Default {
            Write-Host "无效选择，请重试。"
        }
    }
}

while ($true) {
    Show-Menu
    $selection = Read-Host "请输入数字选择（如 1-8 或 0 退出）"
    
    # 确保选择是有效数字
    if ($selection -match '^\d+$') {
        $selection = [int]$selection
        Run-Command -Choice $selection
    } else {
        Write-Host "无效输入，请输入有效数字（0-8）。"
    }
}
