# the json library is used to read JSON format data
import json

# an empty list that we will fill with all of the alerts
alerts = []

# an empty list which we will use to track which alert ids we have already seen
seen = []

# empty list with fast-style messages
fast = []

# empty list with participants
participants = []

# open the eve.json file; 'r' means we are opening it for reading (not writing)
with open("eve.json", 'r') as f:
    # read each line of the file
    for line in f:
        # each line is a JSON event; load it
        event = json.loads(line)
        # check if the event type is an alert
        if event.get("event_type") == "alert":

            # get the alert id components
            src_ip = event.get("src_ip")
            dest_ip = event.get("dest_ip")
            alert = event.get("alert")            
            gid = alert.get("gid")
            sid = alert.get("signature_id")
            rev = alert.get("rev")
            # make the id that uniquely identifies this alert
            alert_id = (src_ip, dest_ip, gid, sid, rev)

            # check that this alert is not a duplicate
            if alert_id not in seen:
                # if so, add it to the list of alerts
                alerts.append(event)
                # remember that we have now seen this alert id
                seen.append(alert_id)

for a in alerts:
    # get the parts of the alert we want to print
    src_ip = a.get("src_ip")
    dest_ip = a.get("dest_ip")
    timestamp = a.get("timestamp")
    alert = a.get("alert")
    signature = alert.get("signature")
    gid = alert.get("gid")
    sid = alert.get("signature_id")
    rev = alert.get("rev")

    severity = alert.get("severity")
    if severity == 1:
        if src_ip not in participants:
            participants.append(src_ip)
        if dest_ip not in participants:
            participants.append(dest_ip)
        fast.append(f"{src_ip} -> {dest_ip} : {timestamp} [{gid}:{sid}:{rev}] {signature}")

participants = sorted(participants)

print("@startuml")
for address in participants:
    print("participant " + address)
for message in fast:
    print(message)
print("@enduml")
