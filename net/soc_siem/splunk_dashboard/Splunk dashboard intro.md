
# Step 1 - Create dashboard

- Click "Create New Dashboard" in top right of Splunk window.
- Add a meaningful dashboard title.
- Change permissions as required - Usually "Shared in App"
- Choose your preferred dashboard.

![](65school/net/soc_siem/splunk_dashboard/attachments/step1.png)

# Step 2 - Creating a Search(optional)

- Create a search query which contains data which you'd like to add to your dashboard.
- In the top right click "save as"
- Select "Existing Dashboard"
	-  Alternatively you can Create the dashboard by selecting "New Dashboard" here.
- Select the dashboard you've created previously.


![](65school/net/soc_siem/splunk_dashboard/attachments/Step2.png)

# Step 3 - Adding filters

- Navigate to "Dashboards" at the top of Splunk page.
- Enter the dashboard which you created. 
- Select "add input".
- At this point you need to pick a filter which is relevant to the data you're trying to search for.
	- eg. If you're trying to look for a specific process name "text" might be a good choice.
	- If you're looking for a specific IP address you might use "multiselect"

![](65school/net/soc_siem/splunk_dashboard/attachments/step3.png)

![](65school/net/soc_siem/splunk_dashboard/attachments/step4.png)

# Step 4 - Merging filter with search query

To filter on data values which are present in your search query you need tie the value which you're searching on to the value already present in the search query. 
- Eg. If i wanted to search for a specific process I'll need to 

![](65school/net/soc_siem/splunk_dashboard/attachments/step5.png)

# Step 5 - Complete

![](65school/net/soc_siem/splunk_dashboard/attachments/Step6%201.png)


![](65school/net/soc_siem/splunk_dashboard/attachments/step7.png)

