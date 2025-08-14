import socket
import time
import sys

def run_server():
    """
    啟動伺服器端，等待客戶端連線並測量速度。
    """
    HOST = '0.0.0.0'  # 監聽所有可用的 IP 位址
    PORT = 65432      # 使用固定的埠號

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
                
                while True:
                    data = conn.recv(1024)
                    if not data:
                        break
                    total_data_size += len(data)
                
                end_time = time.time()
                duration = end_time - start_time
                
                print("資料接收完成。")
                
                if duration > 0:
                    speed_mbps = (total_data_size / 1024 / 1024) / duration
                    print("--- 測試結果 ---")
                    print(f"總共接收：{total_data_size / 1024 / 1024:.2f} MB")
                    print(f"耗時：{duration:.2f} 秒")
                    print(f"平均速度：{speed_mbps:.2f} MB/s")
                else:
                    print("時間過短，無法計算速度。")
    except Exception as e:
        print(f"伺服器啟動失敗或發生錯誤：{e}")

def run_client():
    """
    啟動客戶端，連線到伺服器並發送資料。
    """
    SERVER_IP = input("請輸入伺服器 IP 位址：")
    PORT = 65432  # 必須與伺服器端的埠號相同

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            print(f"正在嘗試連線到伺服器 {SERVER_IP}:{PORT}...")
            s.connect((SERVER_IP, PORT))
            print("連線成功。")

            # 準備要發送的資料 (約 100 MB)
            data_to_send = b'X' * (1024 * 1024 * 100)
            
            print("開始發送資料...")
            s.sendall(data_to_send)
            
            print("資料發送完成。")
    except ConnectionRefusedError:
        print("連線失敗，請檢查伺服器 IP 位址和埠號是否正確，以及伺服器是否正在運行。")
    except socket.timeout:
        print("連線超時，請檢查網路連線。")
    except Exception as e:
        print(f"客戶端發生錯誤：{e}")

if __name__ == "__main__":
    while True:
        print("\n--- 網路速度測試工具 ---")
        print("請選擇你要啟動的模式：")
        print("1. 伺服器端 (等待連線)")
        print("2. 客戶端 (連線並發送資料)")
        print("3. 結束程式")
        
        choice = input("請輸入你的選擇 (1-3): ")
        
        if choice == '1':
            run_server()
            break
        elif choice == '2':
            run_client()
            break
        elif choice == '3':
            print("程式已結束。")
            sys.exit()
        else:
            print("無效的選擇，請重新輸入。")