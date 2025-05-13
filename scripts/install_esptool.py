import os
import sys
import platform
import urllib.request
import zipfile

def find_nonempty_esptool_folder(base_path):
    for entry in os.listdir(base_path):
        full_path = os.path.join(base_path, entry)
        if entry.startswith("esptool") and os.path.isdir(full_path):
            if any(os.scandir(full_path)):  # 非空文件夹
                return full_path
    return None

def get_esptool_download_url():
    system = platform.system()
    # 示例链接，这些链接你需要根据你项目中实际可用的 esptool 下载地址更新
    urls = {
        # 此安装脚本只推荐 Windows 使用，Linux 和 MacOS 推荐使用 pip install esptool
        "Windows": "https://github.com/espressif/esptool/releases/download/v4.8.1/esptool-v4.8.1-win64.zip",
        "Linux":   "https://github.com/espressif/esptool/releases/download/v4.8.1/esptool-v4.8.1-linux-amd64.zip",
        "Darwin":  "https://github.com/espressif/esptool/releases/download/v4.8.1/esptool-v4.8.1-macos.zip"
    }
    return urls.get(system)

def download_progress_hook(block_num, block_size, total_size):
    downloaded = block_num * block_size
    percent = int(downloaded * 100 / total_size) if total_size > 0 else 0
    bar_len = 50
    filled_len = int(bar_len * percent // 100)
    bar = '=' * filled_len + '-' * (bar_len - filled_len)
    sys.stdout.write(f'\r下载进度：[{bar}] {percent}%')
    sys.stdout.flush()

def download_and_extract(url, extract_to):
    zip_path = os.path.join(extract_to, "esptool_tmp.zip")
    print(f"开始从 {url} 下载 esptool...")
    urllib.request.urlretrieve(url, zip_path, reporthook=download_progress_hook)
    print("\n下载完成，开始解压...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_to)
    os.remove(zip_path)
    print("解压完成。")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"当前目录：{script_dir}")
    folder = find_nonempty_esptool_folder(script_dir)

    if folder:
        print(f"已找到 esptool 文件夹：{folder}")
    else:
        print("未找到有效的 esptool 文件夹，准备下载安装...")
        url = get_esptool_download_url()
        if not url:
            print("不支持的操作系统或未配置下载地址。")
            sys.exit(1)
        download_and_extract(url, script_dir)

if __name__ == "__main__":
    main()
