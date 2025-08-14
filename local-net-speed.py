import socket
import time
import sys

# 配置選項
DEFAULT_PORT = 65432
DEFAULT_DATA_SIZE_MB = 100
CHUNK_SIZE = 1024 * 1024  # 1 MB
GIGABIT_SPEED_MBPS = 125  # 1 Gbps = 125 MB/s (理論值)
GIGABIT_PRACTICAL_THRESHOLD = 100  # 實際可達到的 Gigabit 門檻值 (MB/s)

def evaluate_gigabit_performance(speed_mbps):
    """評估是否達到 Gigabit 乙太網路效能"""
    print("\n--- Gigabit 乙太網路效能評估 ---")
    print(f"理論 Gigabit 速度: {GIGABIT_SPEED_MBPS} MB/s")
    print(f"實際測試速度: {speed_mbps:.2f} MB/s")
    
    # 計算效能百分比
    performance_percentage = (speed_mbps / GIGABIT_SPEED_MBPS) * 100
    print(f"達到理論速度的: {performance_percentage:.1f}%")
    
    # 效能評級
    if speed_mbps >= GIGABIT_PRACTICAL_THRESHOLD:
        rating = "優秀 ✅"
        message = "恭喜！您的網路已達到 Gigabit 等級效能"
    elif speed_mbps >= 80:
        rating = "良好 ⚡"
        message = "接近 Gigabit 效能，但仍有提升空間"
    elif speed_mbps >= 50:
        rating = "一般 ⚠️"
        message = "網路速度一般，建議檢查網路設備或連線品質"
    elif speed_mbps >= 10:
        rating = "偏慢 🐌"
        message = "網路速度偏慢，可能未使用 Gigabit 設備"
    else:
        rating = "很慢 🚫"
        message = "網路速度很慢，建議檢查網路連線問題"
    
    print(f"效能評級: {rating}")
    print(f"建議: {message}")
    
    # 提供改善建議
    if speed_mbps < GIGABIT_PRACTICAL_THRESHOLD:
        print("\n--- 效能改善建議 ---")
        suggestions = [
            "• 確認使用 Cat5e 或更高等級的網路線",
            "• 檢查網路交換器是否支援 Gigabit",
            "• 確認網路卡設定為 1000 Mbps 全雙工",
            "• 關閉不必要的網路程式和服務",
            "• 檢查是否有網路瓶頸或干擾"
        ]
        for suggestion in suggestions:
            print(suggestion)

def get_data_size():
    """讓用戶選擇要傳輸的資料大小"""
    while True:
        try:
            size = input(f"請輸入要傳輸的資料大小 (MB，預設 {DEFAULT_DATA_SIZE_MB}): ").strip()
            if not size:
                return DEFAULT_DATA_SIZE_MB * 1024 * 1024
            size_mb = int(size)
            if size_mb <= 0:
                print("請輸入正數")
                continue
            return size_mb * 1024 * 1024
        except ValueError:
            print("請輸入有效的數字")

def run_server():
    """
    啟動伺服器端，等待客戶端連線並測量速度。
    """
    HOST = '0.0.0.0'  # 監聽所有可用的 IP 位址
    PORT = DEFAULT_PORT      # 使用固定的埠號

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind((HOST, PORT))
            s.listen()
            
            # 取得本機 IP 位址供客戶端參考
            try:
                hostname = socket.gethostname()
                local_ip = socket.gethostbyname(hostname)
            except socket.gaierror:
                local_ip = "127.0.0.1"

            print(f"伺服器正在監聽 {local_ip}:{PORT}，等待客戶端連線...")
            conn, addr = s.accept()
            with conn:
                print(f"已成功連線到 {addr}")
                
                # 開始接收資料並計時
                start_time = time.time()
                total_data_size = 0
                
                print("開始接收資料...")
                while True:
                    data = conn.recv(1024 * 1024)  # 增加接收緩衝區大小
                    if not data:
                        break
                    total_data_size += len(data)
                    
                    # 顯示接收進度
                    print(f"\r已接收: {total_data_size / 1024 / 1024:.1f} MB", end='', flush=True)
                
                end_time = time.time()
                duration = end_time - start_time
                
                print("\n資料接收完成。")
                
                if duration > 0:
                    speed_mbps = (total_data_size / 1024 / 1024) / duration
                    print("--- 測試結果 ---")
                    print(f"總共接收：{total_data_size / 1024 / 1024:.2f} MB")
                    print(f"耗時：{duration:.2f} 秒")
                    print(f"平均速度：{speed_mbps:.2f} MB/s")
                    
                    # 新增 Gigabit 效能評估
                    evaluate_gigabit_performance(speed_mbps)
                else:
                    print("時間過短，無法計算速度。")
    except Exception as e:
        print(f"伺服器啟動失敗或發生錯誤：{e}")

def run_client():
    """
    啟動客戶端，連線到伺服器並發送資料。
    """
    SERVER_IP = input("請輸入伺服器 IP 位址：")
    PORT = DEFAULT_PORT  # 必須與伺服器端的埠號相同

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            print(f"正在嘗試連線到伺服器 {SERVER_IP}:{PORT}...")
            s.connect((SERVER_IP, PORT))
            print("連線成功。")

            # 分塊發送資料並顯示進度
            total_size = 100 * 1024 * 1024  # 100 MB
            chunk_size = 1024 * 1024  # 1 MB per chunk
            sent_size = 0
            
            print("開始發送資料...")
            start_time = time.time()
            
            while sent_size < total_size:
                remaining = min(chunk_size, total_size - sent_size)
                data_chunk = b'X' * remaining
                s.sendall(data_chunk)
                sent_size += remaining
                
                # 顯示進度
                progress = (sent_size / total_size) * 100
                print(f"\r進度: {progress:.1f}% ({sent_size // (1024*1024)} MB / {total_size // (1024*1024)} MB)", end='', flush=True)
            
            end_time = time.time()
            duration = end_time - start_time
            speed_mbps = (total_size / 1024 / 1024) / duration if duration > 0 else 0
            
            print(f"\n資料發送完成。")
            print(f"發送速度：{speed_mbps:.2f} MB/s")
            
            # 新增 Gigabit 效能評估
            evaluate_gigabit_performance(speed_mbps)
            
    except ConnectionRefusedError:
        print("連線失敗，請檢查伺服器 IP 位址和埠號是否正確，以及伺服器是否正在運行。")
    except Exception as e:
        print(f"客戶端發生錯誤：{e}")

def check_network_connectivity(host, port):
    """檢查網路連接性"""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(3)
            result = s.connect_ex((host, port))
            return result == 0
    except:
        return False

if __name__ == "__main__":
    while True:
        print("\n--- 網路速度測試工具 (含 Gigabit 效能評估) ---")
        print("請選擇你要啟動的模式：")
        print("1. 伺服器端 (等待連線)")
        print("2. 客戶端 (連線並發送資料)")
        print("3. 結束程式")
        
        choice = input("請輸入你的選擇 (1-3): ")
        
        if choice == '1':
            run_server()
            # 伺服器執行完後不退出，可以繼續選擇
        elif choice == '2':
            run_client()
            # 客戶端執行完後不退出，可以繼續選擇
        elif choice == '3':
            print("程式已結束。")
            sys.exit()
        else:
            print("無效的選擇，請重新輸入。")