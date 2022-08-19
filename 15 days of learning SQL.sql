# HackerRank Hard Problem: https://www.hackerrank.com/challenges/15-days-of-learning-sql/problem

WITH RECURSIVE cte AS 
(
  SELECT DISTINCT submission_date, hacker_id 
  FROM submissions 
  WHERE submission_date = (SELECT MIN(submission_date) FROM submissions)
  UNION
  SELECT s.submission_date, s.hacker_id 
  FROM submissions s JOIN cte ON cte.hacker_id = s.hacker_id 
  WHERE s.submission_date = (SELECT MIN(submission_date) FROM submissions WHERE submission_date > cte.submission_date)
),

unique_hackers_count AS 
(
  SELECT
    submission_date,
    COUNT(hacker_id) unique_hacker_count 
  FROM
    cte 
  GROUP BY
    submission_date
),

count_submission AS 
(
  SELECT
    submission_date,
    hacker_id,
    COUNT(1) AS num_of_submission 
  FROM
    submissions 
  GROUP BY
    submission_date,
    hacker_id
)
,
max_submission AS 
(
  SELECT
    submission_date,
    MAX(num_of_submission) AS max_submission 
  FROM
    count_submission 
  GROUP BY
    submission_date
)
,
max_hacker AS 
(
  SELECT
    cs.submission_date,
    MIN(cs.hacker_id) hacker_id 
  FROM
    max_submission ms 
    JOIN
      count_submission cs 
  WHERE
    ms.submission_date = cs.submission_date 
    AND ms.max_submission = cs.num_of_submission 
  GROUP BY
    cs.submission_date
)

SELECT
  uhc.submission_date,
  uhc.unique_hacker_count,
  mh.hacker_id,
  h.name 
FROM
  unique_hackers_count uhc 
  JOIN
    max_hacker mh 
    ON uhc.submission_date = mh.submission_date 
  JOIN
    hackers h 
    ON mh.hacker_id = h.hacker_id 
ORDER BY
  1;
  
  
