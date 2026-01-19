## How They Work (Operational Concept)

- Splunk indexes raw events and stores them with associated metadata fields.
- At search time, Splunk extracts additional fields based on sourcetype rules, automatic key/value patterns, or user-created extractions.
- Fields enable you to slice and analyze data without modifying raw events, simply by referencing fields in your SPL (Search Processing Language) commands.

---

## How and When to Use Fields in Searches

**Filtering**  
Use field/value criteria to narrow results (e.g., `status=404` or `user="admin"`).

**Statistical Analysis**  
Feed fields into transforming commands (e.g., `stats`, `timechart`, `chart`, `eventstats`) to derive metrics (e.g., `stats count by status`).

**Correlation**  
Join or correlate events across data sources using shared fields (e.g., session IDs, user IDs).

**Data Enrichment**  
Leverage fields to lookup external context (e.g., enriching IP fields with asset metadata).

**Visualization**  
Drive dashboards and reports where fields act as dimensions and measures.

---

## Typical Usage Patterns

- Use fields in base searches to reduce event volume early: `index=web status>=500`
- Use fields with transforming commands to derive metrics: `| stats count by status`
- Use wildcard or boolean operators for conditional logic: `status!=200 AND method=POST`
- Use the `fields` command to include/exclude fields for clarity and performance: `| fields host user status`



## Logical Operators in Splunk
Logical operators in Splunk define how multiple search conditions are evaluated. Each event is checked against these operators to determine whether it should be returned.  

- **AND**: All conditions must be true.  
- **OR**: At least one condition must be true.  
- **NOT**: Excludes events that match a specific condition.  

By combining these operators, you can create precise and flexible filtering logic.


Dashboards in Splunk provide a powerful way to visualize, monitor, and share data. They transform raw search results into actionable insights using **interactive panels** such as:

- **Charts** – line, bar, pie, and more to show trends and comparisons  
- **Tables** – organized data for detailed analysis  
- **Maps** – geographic visualization of event data  

Dashboards can be **interactive**, allowing users to filter, drill down, and explore data in real time. By combining multiple panels and searches, they help spot patterns, trends, and anomalies quickly and effectively.

