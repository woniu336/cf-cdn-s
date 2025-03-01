#!/usr/bin/env python3
import sys
from collections import defaultdict
import time
from datetime import datetime

def parse_line(line):
    try:
        # 解析日志时间
        time_str = line.split('[')[1].split(']')[0]
        return datetime.strptime(time_str, '%d/%b/%Y:%H:%M:%S %z')
    except:
        return None

def analyze_log(file_path, interval=60):
    requests = defaultdict(int)
    
    with open(file_path, 'r') as f:
        for line in f:
            dt = parse_line(line)
            if dt:
                # 按秒计数
                key = dt.strftime('%Y-%m-%d %H:%M:%S')
                requests[key] += 1
    
    # 计算 RPS
    total_seconds = len(requests)
    total_requests = sum(requests.values())
    avg_rps = total_requests / total_seconds if total_seconds > 0 else 0
    
    max_rps = max(requests.values())
    
    print(f"分析结果:")
    print(f"总请求数: {total_requests}")
    print(f"平均 RPS: {avg_rps:.2f}")
    print(f"最大 RPS: {max_rps}")
    
    # 显示最近的 RPS
    sorted_times = sorted(requests.keys())
    if sorted_times:
        print("\n最近的 RPS 数据:")
        for t in sorted_times[-10:]:
            print(f"{t}: {requests[t]}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <log_file>")
        sys.exit(1)
    
    analyze_log(sys.argv[1])