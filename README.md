# SQL-projects
A repository is for my daily SQL practice.

## Practice 1: Investigating a Drop in User Engagement [Mode practice](https://mode.com/sql-tutorial/a-drop-in-user-engagement-answers/)
**Problem** [A chart](https://app.mode.com/modeanalytics/reports/cbb8c291ee96/runs/7925c979521e/embed) from Yammer shows the number of engaged users each week. Yammer defines engagement as having made some type of server call by interacting with the product (shown in the data as events of type "engagement"). Any point in this chart can be interpreted as "the number of users who logged at least one engagement event during the week starting on that date." 

**Task** You are responsible for determining what caused the dip at the end of the chart shown above and, if appropriate, recommending solutions for the problem.

#### Step 1: Investigating a new signup trend
```
SELECT
  DATE_TRUNC('day', created_at) as created_day,
  COUNT(user_id) as all_users,
  COUNT(CASE WHEN state = 'active' THEN user_id ELSE NULL END) as active_users
FROM tutorial.yammer_users
WHERE created_at >= '2014-06-01'
   AND created_at < '2014-09-01'
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY DATE_TRUNC('day', created_at)
```

