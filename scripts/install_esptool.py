import os
import sys
import platform
import urllib.request
import zipfile
import shutil

def find_nonempty_esptool_folder(base_path):
    for entry in os.listdir(base_path):
        full_path = os.path.join(base_path, entry)
        if entry.startswith("esptool") and os.path.isdir(full_path):
            # 检查目录是否非空
            if any(os.scandir(full_path)):
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

def download_and_extract(url, extract_to):
    zip_path = os.path.join(extract_to, "esptool_tmp.zip")
    print(f"Downloading esptool from {url}...")
    urllib.request.urlretrieve(url, zip_path)
    print("Download complete. Extracting...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_to)
    os.remove(zip_path)
    print("Extraction complete.")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"Checking in: {script_dir}")
    folder = find_nonempty_esptool_folder(script_dir)

    if folder:
        print(f"Found non-empty esptool folder: {folder}")
    else:
        print("No valid esptool folder found. Starting download...")
        url = get_esptool_download_url()
        if not url:
            print("Unsupported OS or no URL configured.")
            sys.exit(1)
        download_and_extract(url, script_dir)

if __name__ == "__main__":
    main()
