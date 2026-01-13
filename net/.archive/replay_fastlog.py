import time
from datetime import datetime

def replay_fastlog(file_path):
    with open(file_path, "r") as f:
        lines = f.readlines()

    if not lines:
        print("fast.log is empty.")
        return

    # Print the first line immediately
    print(lines[0].strip())

    # Parse first timestamp as reference
    first_time = datetime.strptime(lines[0].split()[0] + " " + lines[0].split()[1],
                                   "%m/%d/%Y-%H:%M:%S.%f")

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

        # Calculate sleep interval
        delta = (current_time - prev_time).total_seconds()
        if delta > 0:
            time.sleep(delta)

        print(line.strip())
        prev_time = current_time

if __name__ == "__main__":
    replay_fastlog("fast.log")
