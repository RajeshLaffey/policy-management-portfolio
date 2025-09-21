/* =========================================================
/* =========================================================
   Project: Policy Management SQL Analysis
   Author: Rajesh Laffey
   DBMS: SQLite 
   Description:
     - Contains 9 business questions and their SQL answers
     - Focused on policies, reviews, employees, and departments
   ========================================================= */
/* =========================================================
  Q1: What is the breakdown of policies by status (Active, Draft, Retired) */

SELECT
Status
,count(status) as StatusCount

FROM clean_policies

GROUP BY Status

ORDER BY count(status) DESC 

/* 
   Analysis:
	- The majority of policies (169) are in an "Approved" state, which indicates 	that most of the portfolio has been formally reviewed and authorized. 
	- However, there are still 48 policies currently "Under Review" and 31 in "Draft" status, showing ongoing development and review activity. 	
    - Additionally, 52 policies have been "Retired," which is expected in a mature policy environment but should be monitored to ensure no gaps are 	left unaddressed.
	- This breakdown gives leadership a clear picture of where policies sit in their lifecycle and highlights areas (Draft/Under Review) that may need 	extra attention to keep compliance obligations current.
   ========================================================= */
/* =========================================================
   Q2: How many reviews were completed in December 2024

SELECT 
count(cr.PolicyID) as 'December 2024 Count'


FROM clean_reviews as cr
INNER JOIN clean_policies as cp
ON cr.PolicyID = cp.PolicyID

WHERE 
date(cr.ReviewDate) BETWEEN '2024-12-01' AND '2024-12-31'

/* 
   Analysis:
    - In December 2024, a total of 36 policy reviews were completed. This number provides a point-in-time view of review activity and can be compared against expected review volumes for that month. 
    - If December typically aligns with scheduled review cycles, this output can confirm whether teams 	are meeting compliance expectations. 
    - Leadership can use this to assess whether review cadence is consistent throughout the year or if activity is clustered at certain times, which may indicate resourcing or planning issues.
   ========================================================= */
/* =========================================================
   Q3: Which Top 5 active employees are responsible for the most reviews? */

SELECT 
ce.FullName as Name
,ce.Role
,cd.DepartmentName
,count(ce.FullName) as ReviewCount

FROM clean_reviews as cr
INNER JOIN clean_employees as ce
on cr.ReviewerEmployeeID = ce.EmployeeID

INNER JOIN clean_departments as cd
on ce.DepartmentID = cd.DepartmentID

WHERE
ce.ActiveFlag = 'Y'

GROUP BY  ce.FullName
ORDER BY count(ce.FullName) DESC

LIMIT 5

/* 
   Analysis:
	Over the 5-year span, the top 5 active employees have each completed 	between 179 and 204 reviews, with all individuals coming from the 	Compliance department. 

	While this highlights consistent contributions from Compliance analysts, 	the timeframe means these results do not necessarily reflect current 	workload or concentration of responsibilities. Instead, it shows who has 	been most active historically across the policy review process. 

	Leadership can use this to recognize long-term contributors and, if 	needed, compare against shorter time periods to evaluate current workload 	distribution.

   ========================================================= */
/* =========================================================
   Q4: Which 3 departments own the lowest number of Approved policies?*/

WITH dept_counts AS (
    SELECT 
        cd.DepartmentName,
        COUNT(cp.OwnerDepartmentID) AS PolicyCount
    FROM clean_policies AS cp
    INNER JOIN clean_departments AS cd
        ON cp.OwnerDepartmentID = cd.DepartmentID
    WHERE cp.Status = 'Approved'
    GROUP BY cd.DepartmentName
),
ranked AS (
    SELECT 
        DepartmentName,
        PolicyCount,
        RANK() OVER (ORDER BY PolicyCount ASC) AS rnk
    FROM dept_counts
)
SELECT DepartmentName, PolicyCount
FROM ranked
WHERE rnk <= 3
ORDER BY rnk, DepartmentName;

/* 
   Analysis:
	Across the approved and reviewed policies, the departments with the lowest 	counts are Internal Audit (4), Legal Affairs (6), and Procurement (7). 

	This indicates that these units either own fewer policies overall or that 	their policies reach the approval stage less frequently than other 	departments. While a low count is not inherently negative—it may simply 	reflect the scope of each department’s responsibilities—it does provide 	visibility into areas where policy ownership is lighter. 

	Leadership may want to confirm whether these lower numbers align with 	business expectations (e.g., Internal Audit naturally owning fewer 	policies) or if they point to gaps in oversight that could expose the 	organization to compliance risk.
   =========================================================*/
/* =========================================================
   Q5: How many policies are overdue for review (NextReview < today)? */

SELECT 
cp.PolicyID
,cp.PolicyTitle
,cd.DepartmentName
,cp.NextReview

FROM clean_policies as cp
INNER JOIN clean_departments as cd
on cp.OwnerDepartmentID = cd.DepartmentID

WHERE date(cp.NextReview) < date('now')

ORDER BY date(cp.NextReview) ASC

/* 
   Analysis:
	There are a total of 19 policies overdue for review across 11 departments. 
	
	Risk Management has the highest number with 4 overdue policies, followed 	by Compliance with 3. Communications, Investment Operations, Member 	Services, and Facilities each have 2 overdue policies. The remaining 	departments (HR Operations, Treasury, IT Infrastructure, IT Security, and 	Procurement) each have 1 overdue policy. 

	This view highlights both the total backlog of overdue reviews and where 	they are concentrated. Leadership can use this to prioritize departments 	with higher overdue volumes while still monitoring single-policy delays in 	smaller units.
   =========================================================*/
/* =========================================================
   Q6: What percentage of reviews were approved vs. rejected? */

WITH pol_review AS(
SELECT
ReviewStatus
,count(ReviewStatus) as statuscount

FROM clean_reviews

GROUP BY ReviewStatus
),
pol_count AS (
SELECT
SUM(statuscount) as sumcount
FROM pol_review
)

SELECT 
pr.ReviewStatus as 'Review Status'
,round(100.0 * pr.statuscount / pc.sumcount,2) AS 'Total (%)'

FROM pol_review AS pr
CROSS JOIN pol_count AS pc

/* 
   Analysis:
	The results show that 87.99% of reviews were approved, while 12.01% were 	rejected. This high approval rate suggests that most policies under review 	are meeting compliance and quality expectations. At the same time, the 	presence of rejected reviews highlights that the review process is 	functioning as a meaningful control, ensuring that not all policies 	automatically pass through without scrutiny. 

	Leadership can use this insight to validate that the review process 	maintains rigor while also monitoring whether the rejection rate is within 	an acceptable range or may signal recurring quality issues that require 	upstream improvements.
   =========================================================*/
/* =========================================================
   Q7: Which departments have the highest average days overdue among policies past NextReview?*/

SELECT 
cd.DepartmentName,
count(*) PolicyCount,
round(avg(julianday('now') - julianday(cp.NextReview)),2) AvgDayPastDue


FROM clean_policies as cp
INNER JOIN clean_departments as cd
on cp.OwnerDepartmentID = cd.DepartmentID

WHERE
date(cp.NextReview) < date('now')

GROUP BY cd.DepartmentID

/* 
   Analysis:
	Among policies that are already overdue, some departments show 	much higher average days past due than others. Procurement stands 	out with an average of 729 days overdue, followed by 	Communications (605 days) and HR Operations (566 days). These 	results highlight not just missed deadlines, but prolonged delays 	in completing policy reviews. 

	By contrast, departments such as IT Security (64 days) and 	Facilities (172 days) are closer to their review deadlines, 	suggesting shorter lag times in addressing overdue items. 

	This metric helps leadership prioritize the most critical gaps by 	focusing on departments where overdue policies remain unaddressed 	for extended periods, posing higher compliance and operational 	risks.
   =========================================================*/
/* =========================================================
   Q8: What is each department’s review throughput (reviews per active employee) in 2022?

WITH active_employee AS(
SELECT
ce.DepartmentID
,count(ce.DepartmentID) AS ActiveEmployeeCount

FROM clean_employees ce

WHERE 
NOT DepartmentID IS NULL
AND ce.ActiveFlag = 'Y'

GROUP BY ce.DepartmentID
),

policy_dept AS(
SELECT
cp2.OwnerDepartmentID,
cd2.DepartmentName,
Count(cp2.OwnerDepartmentID) ReviewCount

FROM clean_reviews cr2
INNER JOIN clean_policies cp2
ON cr2.PolicyID = cp2.PolicyID

INNER JOIN clean_departments cd2
ON cp2.OwnerDepartmentID = cd2.DepartmentID

WHERE 

date(cr2.ReviewDate) BETWEEN '2022-01-01' AND '2022-12-31'

GROUP BY cp2.OwnerDepartmentID
)

SELECT 
pd.DepartmentName AS 'Dept Name'
,Round(1.0 * pd.ReviewCount/ae.ActiveEmployeeCount,2) as 'Throughput 2022'

FROM active_employee ae
LEFT JOIN policy_dept pd
ON ae.DepartmentID = pd.OwnerDepartmentID

/* 
   Analysis:	
	Review throughput, measured as reviews per active employee in 	2022, varies significantly across departments. Legal Affairs 	(23.0), Communications (15.0), and Member Services (14.5) stand 	out with the highest throughput, suggesting a heavier review 	workload relative to their staffing levels. 

	Departments such as IT Infrastructure (3.33), Internal Audit 	(2.33), and Employer Services (3.75) show the lowest throughput, 	indicating lighter review responsibilities per employee. 

	High throughput can reflect efficiency, but it may also signal 	that certain departments are carrying more review demand than 	their staffing comfortably supports. Leadership should consider 	whether consistently high-throughput areas require additional 	resources to reduce risk of overextension and ensure sustainable 	review practices.
   =========================================================*/
/* =========================================================
   Q9: Which departments carry the highest compliance risk (proportion of overdue policies vs. total policies)?*/

WITH OverdueCount AS(
SELECT
cp.OwnerDepartmentID
,cd.DepartmentName
,1.0 * count(cp.OwnerDepartmentID) OverdueCount

FROM clean_policies cp
INNER JOIN clean_departments cd
ON cp.OwnerDepartmentID = cd.DepartmentID

WHERE date(cp.NextReview) < date('now')

GROUP BY OwnerDepartmentID
),

PolicyCount AS(
SELECT 
OwnerDepartmentID,
1.0 * count(*) AS TotalPolicy

FROM clean_policies

GROUP BY OwnerDepartmentID
)

SELECT
oc.DepartmentName
,oc.OverdueCount
,pc.TotalPolicy
,ROUND(100 * oc.OverdueCount/pc.TotalPolicy , 2) AS 'Overdue Policy (%)'

FROM OverdueCount oc
INNER JOIN PolicyCount pc
ON pc.OwnerDepartmentID = oc.OwnerDepartmentID

ORDER BY ROUND(100 * oc.OverdueCount/pc.TotalPolicy , 2) DESC

/* 
	Analysis:
	When measuring compliance risk by the proportion of overdue 	policies relative to total active policies, Risk Management shows 	the highest exposure with 21.05% of its policies overdue. 	Investment Operations follows at 15.38%, while Facilities and 	Communications each have 9.52% overdue. 

	Departments such as Compliance (4.05%), Treasury (5.0%), and IT 	(6–6.25%) have lower percentages, suggesting stronger adherence 	to review schedules or more robust oversight processes. 

	This proportional view highlights risk relative to each 	department’s policy portfolio. A smaller department with just a 	few overdue policies may appear riskier than a larger department 	with more total policies but a smaller share overdue. Leadership 	can use this measure to focus remediation on departments where 	overdue policies make up a significant percentage of their 	obligations, not just where raw counts are high.
   =========================================================*/
/* =========================================================
   Closing Note:
   This collection of queries demonstrates how SQL can be used 
   to answer business-critical policy and compliance questions. 
   Each query provides a different lens on policy status, review 
   activity, workload distribution, and compliance risk.
   ========================================================= */

