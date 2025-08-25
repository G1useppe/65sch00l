import time
import argparse
from datetime import datetime

def replay_fastlog(file_path, speed=1.0):
    with open(file_path, "r") as f:
        lines = f.readlines()

    if not lines:
        print("fast.log is empty.")
        return

    # Print the first line immediately
    print(lines[0].strip())

    # Parse first timestamp as reference
    try:
        first_time = datetime.strptime(lines[0].split()[0] + " " + lines[0].split()[1],
                                       "%m/%d/%Y-%H:%M:%S.%f")
    except ValueError:
        print("Could not parse timestamp in first line.")
        return

    prev_time = first_time

    # Iterate over the rest of the lines
    for line in lines[1:]:
        parts = line.split()
        if len(parts) < 2:
            continue  # skip malformed lines

        try:
            current_time = datetime.strptime(parts[0] + " " + parts[1],
                                             "%m/%d/%Y-%H:%M:%S.%f")
        except ValueError:
            continue  # skip if timestamp format is unexpected

        # Calculate sleep interval and apply speed multiplier
        delta = (current_time - prev_time).total_seconds()
        adjusted_delta = delta / speed if speed > 0 else 0

        if adjusted_delta > 0:
            time.sleep(adjusted_delta)

        print(line.strip())
        prev_time = current_time


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Replay Suricata fast.log respecting timestamps.")
    parser.add_argument("file", help="Path to fast.log file")
    parser.add_argument("--speed", type=float, default=1.0,
                        help="Replay speed multiplier (e.g., 0.5 = half speed, 10 = 10x faster)")

    args = parser.parse_args()
    replay_fastlog(args.file, args.speed)
