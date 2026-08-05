import time
import argparse

def replay_fastlog(file_path, minutes=1.0):
    with open(file_path, "r") as f:
        lines = [line.strip() for line in f if line.strip()]

    if not lines:
        print("fast.log is empty.")
        return

    total_lines = len(lines)
    total_seconds = minutes * 60
    interval = total_seconds / total_lines

    print(f"Replaying {total_lines} lines over {minutes} minutes "
          f"({interval:.2f} seconds between each line).")

    for line in lines:
        print(line)
        time.sleep(interval)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Replay Suricata fast.log evenly spaced over a set duration.")
    parser.add_argument("file", help="Path to fast.log file")
    parser.add_argument("--minutes", type=float, default=1.0,
                        help="Duration to replay all logs (in minutes). Default: 1 minute")

    args = parser.parse_args()
    replay_fastlog(args.file, args.minutes)
