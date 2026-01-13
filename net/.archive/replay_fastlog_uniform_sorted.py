import time
import argparse
from datetime import datetime

def parse_timestamp(line):
    parts = line.split()
    if len(parts) < 2:
        return None
    try:
        return datetime.strptime(parts[0] + " " + parts[1], "%m/%d/%Y-%H:%M:%S.%f")
    except ValueError:
        return None

def replay_fastlog(file_path, minutes=1.0):
    with open(file_path, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    if not lines:
        print("fast.log is empty.")
        return

    # Sort by timestamp (if available)
    lines_with_time = [(parse_timestamp(line), line) for line in lines]
    lines_with_time = [(t, l) for t, l in lines_with_time if t is not None]
    lines_with_time.sort(key=lambda x: x[0])

    sorted_lines = [l for _, l in lines_with_time]

    total_lines = len(sorted_lines)
    total_seconds = minutes * 60
    interval = total_seconds / total_lines

    print(f"Replaying {total_lines} lines over {minutes} minutes "
          f"({interval:.2f} seconds between each line).")

    for line in sorted_lines:
        print(line)
        time.sleep(interval)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Replay Suricata fast.log evenly spaced over a set duration.")
    parser.add_argument("file", help="Path to fast.log file")
    parser.add_argument("--minutes", type=float, default=1.0,
                        help="Duration to replay all logs (in minutes). Default: 1 minute")

    args = parser.parse_args()
    replay_fastlog(args.file, args.minutes)
