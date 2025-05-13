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

# ✅ 检测并选择 ESP-IDF 项目
function Select-Project {
    $projectRoot = Join-Path $PSScriptRoot "project"
    if (-Not (Test-Path $projectRoot)) {
        Write-Warning "未找到 project 文件夹：$projectRoot"
        return $null
    }

    $dirs = Get-ChildItem -Path $projectRoot -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName "CMakeLists.txt")
    }

    if ($dirs.Count -eq 0) {
        Write-Warning "未在 project 文件夹中找到任何 ESP-IDF 项目（含 CMakeLists.txt 的文件夹）"
        return $null
    }

    Write-Host "`n可用项目列表："
    for ($i = 0; $i -lt $dirs.Count; $i++) {
        Write-Host "$($i + 1). $($dirs[$i].Name)"
    }

    $index = Read-Host "请选择项目 (输入编号)"
    if ($index -match '^\d+$' -and $index -ge 1 -and $index -le $dirs.Count) {
        return "/project/$($dirs[$index - 1].Name)"
    } else {
        Write-Warning "输入无效。"
        return $null
    }
}

function Ensure-Esptool {
    $toolPath = "scripts\esptool-win64"
    if (-Not (Test-Path $toolPath)) {
        Write-Host "未找到 $toolPath，正在运行 install_esptool.py 安装..."
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
            $projPath = Select-Project
            if ($projPath) {
                $target = Read-Host "请输入目标芯片名称（如：esp32）"
                docker-compose run --rm -w $projPath esp-idf idf.py set-target $target
            }
            exit
        }
        3 {
            $projPath = Select-Project
            if ($projPath) {
                docker-compose run --rm -w $projPath esp-idf idf.py build
            }
            exit
        }
        4 {
            $projPath = Select-Project
            if ($projPath) {
                docker-compose run --rm -w $projPath esp-idf idf.py menuconfig
            }
            exit
        }
        5 {
            docker-compose run --rm esp-idf bash
            exit
        }
        6 {
            $port = Read-Host "请输入目标串口设备名称（如：COM3）"
            if (Ensure-Esptool) {
                Push-Location "scripts\esptool-win64"
                .\esp_rfc2217_server -v -p 4000 $port
                Pop-Location
                exit
            }
        }
        7 {
            $projPath = Select-Project
            if ($projPath) {
                docker-compose run --rm -w $projPath esp-idf idf.py --port "rfc2217://host.docker.internal:4000?ign_set_control" flash
            }
            exit
        }
        8 {
            $projPath = Select-Project
            if ($projPath) {
                docker-compose run --rm -w $projPath esp-idf idf.py --port "rfc2217://host.docker.internal:4000?ign_set_control" monitor
            }
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
    if ($selection -match '^\d+$') {
        $selection = [int]$selection
        Run-Command -Choice $selection
    } else {
        Write-Host "无效输入，请输入有效数字（0-8）。"
    }
}
