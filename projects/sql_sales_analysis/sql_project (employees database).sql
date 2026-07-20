SELECT * FROM titles;
USE employees;
SELECT * FROM employees;

-- 1. Find the current department of each employee (where to_date = '9999-01-01') --

SELECT 
	e.emp_no,
    CONCAT(e.first_name,' ',e.last_name) AS emp_name,
    d.dept_name
FROM employees e
JOIN dept_emp de
	ON e.emp_no = de.emp_no
JOIN departments d
	ON de.dept_no = d.dept_no
WHERE de.to_date = '9999-01-01';

-- 2. Top 5 Highest-Paid Employees by Department and Gender (with Average Comparison)(hint: use Window Functions, CTEs, JOINs, and Aggregation)-- 
    
WITH current_salaries AS (
	SELECT 
		emp_no,
        salary
	FROM salaries
    WHERE to_date = "9999-01-01"
),
dept_gender_avg AS (
	SELECT 
		d.dept_name,
        e.gender,
        AVG(cs.salary) AS avg_salary_dept_gender
	FROM employees e
    JOIN dept_emp de
		ON e.emp_no = de.emp_no
	JOIN departments d 
		ON de.dept_no = d.dept_no
	JOIN current_salaries cs 
		ON e.emp_no = cs.emp_no
	GROUP BY d.dept_name, e.gender
),
ranked_employees AS (
	SELECT
		e.emp_no,
        e.first_name,
        e.last_name,
        e.gender,
        d.dept_name,
        cs.salary AS current_salary,
        dga.avg_salary_dept_gender AS avg_salary_in_group,
        ROUND(cs.salary - dga.avg_salary_dept_gender, 2) AS diff_from_avg,
        RANK() OVER (
			PARTITION BY d.dept_name, e.gender
            ORDER BY cs.salary DESC
		) AS dept_gender_rank
	FROM employees e
    JOIN dept_emp de 
		ON e.emp_no = de.emp_no
	JOIN departments d 
		ON de.dept_no = d.dept_no
	JOIN current_salaries cs 
		ON e.emp_no = cs.emp_no
	JOIN dept_gender_avg dga
		ON d.dept_name = dga.dept_name
        AND e.gender = dga.gender
)
SELECT 
	dept_gender_rank AS "Rank",
    dept_name AS "Department",
    gender AS "Gender",
    emp_no AS "Emp No",
    first_name AS "First Name",
    last_name AS "Last Name",
    current_salary AS "Current Salary",
    ROUND(avg_salary_in_group, 2) AS "Group Avg Salary",
    CASE 
		WHEN diff_from_avg > 0 THEN CONCAT('+', diff_from_avg)
        ELSE CAST(diff_from_avg AS CHAR)
        END AS "diff from Avg"
	FROM ranked_employees
    WHERE dept_gender_rank <= 5
    ORDER BY dept_name, gender, dept_gender_rank;
    
-- 3. Find departments with average salary above 70,000

SELECT
	d.dept_name AS "Department",
    COUNT(e.emp_no) AS "Total Employee",
    ROUND(AVG(s.salary),2) AS "Average Salary",
    MIN(s.salary) AS "Min Salary",
    MAX(s.salary) AS "Max Salary"
FROM departments d
JOIN dept_emp de
	ON d.dept_no = de.dept_no
JOIN employees e
	ON de.emp_no = e.emp_no
JOIN salaries s 
	ON e.emp_no = s.emp_no
WHERE de.to_date = "9999-01-01" AND s.to_date = "9999-01-01"
GROUP BY d.dept_name
HAVING AVG(s.salary)>70000
ORDER BY AVG(s.salary) DESC;
 
 -- 4. Find the most common job title for each department(hint: use JOIN, GROUP BY, Window Function (RANK))
 
 WITH title_counts AS (
	SELECT 
		d.dept_name,
        t.title,
        COUNT(*) AS title_count
	FROM departments d
    JOIN dept_emp de 
		ON d.dept_no = de.dept_no
	JOIN titles t
		ON de.emp_no = t.emp_no
	WHERE de.to_date = "9999-01-01" AND t.to_date = "9999-01-01"
    GROUP BY d.dept_name, t.title
),
 
 ranked_titles AS(
	SELECT
		dept_name,
        title,
        title_count,
        RANK() OVER(PARTITION BY dept_name ORDER BY title_count DESC) AS title_rank
	FROM title_counts
)
SELECT
	dept_name AS "Department",
    title AS "Most Common Title",
    title_count AS "Employee Count",
    ROUND(100.0 * title_count / SUM(title_count) OVER (PARTITION BY dept_name), 2) 
                     AS `% of Dept`
FROM ranked_titles
WHERE title_rank =1
ORDER BY "Employee Count";

-- 5. Find employees who have changed departments more than 1 time

SELECT
    e.emp_no AS 'Employee No',
    CONCAT(e.first_name,' ',e.last_name) AS 'Employee Name',
    e.gender AS 'Gender',
    e.hire_date AS 'Hire Date',
    dept_changes.total_departments AS 'Total Department Worked',
    dept_changes.total_departments - 1 AS 'No. of Department Changed',
    current_d.dept_name AS 'Current Department'
FROM employees e
JOIN (
    SELECT
        emp_no,
        COUNT(dept_no) AS total_departments
    FROM dept_emp
    GROUP BY emp_no
    HAVING COUNT(dept_no) > 1
) AS dept_changes 
	ON e.emp_no = dept_changes.emp_no
JOIN dept_emp cde      
	ON e.emp_no = cde.emp_no
    AND cde.to_date = '9999-01-01'
JOIN departments current_d 
	ON cde.dept_no = current_d.dept_no

ORDER BY dept_changes.total_departments DESC, e.emp_no;

-- 6. Calculate salary growth percentage for each employee

WITH salary_with_order AS (
	SELECT
        emp_no,
        salary,
        from_date,
        to_date,
        ROW_NUMBER() OVER (
            PARTITION BY emp_no
            ORDER BY from_date ASC
        ) AS salary_rank,
        COUNT(*) OVER (
            PARTITION BY emp_no
        ) AS total_records
    FROM salaries
),
first_and_last AS (
	SELECT
        emp_no,
        MAX(CASE WHEN salary_rank = 1 THEN salary  END) AS first_salary,
        MAX(CASE WHEN salary_rank = 1 THEN from_date END) AS career_start,
        MAX(CASE WHEN salary_rank = total_records THEN salary  END) AS latest_salary,
        MAX(CASE WHEN to_date = '9999-01-01' THEN from_date END) AS latest_date,
        MAX(salary_rank) AS total_raises
    FROM salary_with_order
    GROUP BY emp_no
),
salary_growth AS (
	SELECT
        emp_no,
        first_salary,
        latest_salary,
        career_start,
        latest_date,
        latest_salary - first_salary AS absolute_growth,
        ROUND((latest_salary - first_salary) * 100.0/ first_salary, 2) AS growth_pct,
        TIMESTAMPDIFF(YEAR, career_start, IFNULL(latest_date, CURDATE())) AS years_at_company
    FROM first_and_last
    WHERE first_salary IS NOT NULL
      AND latest_salary IS NOT NULL
)
SELECT
    sg.emp_no AS 'Employee No.',
    CONCAT(e.first_name,' ',e.last_name) AS 'Employee Name',
    d.dept_name AS 'Department',
    sg.career_start AS 'First Date',
    sg.first_salary AS 'First Salary',
    sg.latest_salary AS 'Current Salary',
    sg.absolute_growth  AS 'Salary Growth',
    CONCAT(sg.growth_pct, '%') AS 'Growth %',
    sg.years_at_company AS 'Years At Company'
FROM salary_growth sg
JOIN employees e  ON sg.emp_no  = e.emp_no
JOIN dept_emp de ON e.emp_no = de.emp_no
JOIN departments d ON de.dept_no = d.dept_no
ORDER BY sg.growth_pct DESC;

-- 7. Find departments with the most gender diversity(the count of male and female employees per department)

WITH gender_counts AS (
	SELECT
        d.dept_name,
        COUNT(e.emp_no) AS total_employees,
        COUNT(CASE WHEN e.gender = 'M' THEN e.emp_no END) AS male_count,
        COUNT(CASE WHEN e.gender = 'F' THEN e.emp_no END) AS female_count
    FROM departments d
    JOIN dept_emp de ON d.dept_no = de.dept_no
    JOIN employees e ON de.emp_no = e.emp_no
    WHERE de.to_date = '9999-01-01'
    GROUP BY d.dept_name
),
diversity_metrics AS (
	SELECT
        dept_name,
        total_employees,
        male_count,
        female_count,
        ROUND(male_count   * 100.0 / total_employees, 2) AS male_pct,
        ROUND(female_count * 100.0 / total_employees, 2) AS female_pct,
        ROUND(ABS((male_count * 100.0 / total_employees) - (female_count * 100.0 / total_employees)), 2) AS diversity_gap_pct
    FROM gender_counts
)
SELECT
    dept_name AS 'Department',
    total_employees AS 'Total Employee',
    male_count AS 'Male Count',
    female_count AS 'Female Count',
    CONCAT(male_pct,'%') AS 'Male %',
    CONCAT(female_pct,'%') AS 'Female %',
    CONCAT(diversity_gap_pct, '%')  AS 'Gender Gap%'
FROM diversity_metrics
ORDER BY diversity_gap_pct DESC;

-- 8. Find each department manager’s average managed salary(hint: JOIN, GROUP BY)

WITH managers AS (
	SELECT
        dm.emp_no AS manager_emp_no,
        dm.dept_no,
        dm.from_date AS manager_since
    FROM dept_manager dm
    WHERE dm.to_date = '9999-01-01'
),
dept_employee_salaries AS (
	SELECT
        de.dept_no,
        de.emp_no,
        s.salary
    FROM dept_emp de
    JOIN salaries s ON de.emp_no = s.emp_no
    WHERE de.to_date = '9999-01-01'
      AND s.to_date = '9999-01-01'
)
SELECT
    m.manager_emp_no  AS 'Manager Emp No.',
    CONCAT(e.first_name,' ',e.last_name) AS 'Employee Name',
    d.dept_name AS 'Department',
    m.manager_since AS 'Manager Since',
    TIMESTAMPDIFF(YEAR, m.manager_since, CURDATE()) AS 'Years As Manager',
    MIN(des.salary) AS 'Min Team Salary',
    MAX(des.salary) AS 'Max Team Salary',
    ROUND(AVG(des.salary), 2) AS 'Avg Team Salary',
    (SELECT salary FROM salaries
        WHERE emp_no = m.manager_emp_no
		AND to_date = '9999-01-01')  AS 'Manager Salary'
FROM managers m
JOIN employees e ON m.manager_emp_no = e.emp_no
JOIN departments d ON m.dept_no = d.dept_no
JOIN dept_employee_salaries des ON m.dept_no = des.dept_no
GROUP BY
    m.manager_emp_no,
    e.first_name,
    e.last_name,
    d.dept_name,
    m.manager_since
ORDER BY 'Avg Team Salary' DESC;

-- 9. Create a view of current employees with salary information, then create a stored procedure to generate department-level summaries.(hint: CREATE VIEW, Stored Procedure with parameters)

CREATE OR REPLACE VIEW vw_current_employees_infos AS 
SELECT
	e.emp_no AS emp_no,
    CONCAT(e.first_name,' ',e.last_name) AS employee_name,
    e.gender AS gender,
    e.birth_date AS birth_date,
    e.hire_date AS hire_date,
    TIMESTAMPDIFF(YEAR,e.hire_date, CURDATE()) AS years_at_company,
    t.title AS current_title,
    d.dept_no AS dept_no,
    d.dept_name AS dept_name,
    s.salary AS current_salary,
    s.from_date AS salary_since
FROM employees e
JOIN dept_emp de 
	ON e.emp_no = de.emp_no
	AND de.to_date = '9999-01-01'
JOIN departments d 
	ON de.dept_no =d.dept_no
JOIN salaries s
	ON e.emp_no = s.emp_no
    AND s.to_date = '9999-01-01'
JOIN titles t 
	ON e.emp_no = t.emp_no
    AND t.to_date = '9999-01-01';
    
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_department_summary$$
CREATE PROCEDURE sp_department_summary (
	IN p_dept_name VARCHAR(40)
)
BEGIN
	SELECT 
		dept_name AS 'Department',
        COUNT(emp_no) AS 'Total Employees',
        MIN(current_salary) AS 'Min Salary',
        MAX(current_salary) AS 'Max Salary',
        ROUND(AVG(current_salary),2) AS 'Avg Salary'
	FROM vw_current_employees_infos
    WHERE (p_dept_name IS NULL OR dept_name = p_dept_name)
    GROUP BY dept_name
    ORDER BY AVG(current_salary) DESC;
END$$
DELIMITER ;

CALL sp_department_summary('Sales');


SELECT 
	d.dept_name AS "Department",
    ROUND(AVG(s.salary),2) AS "Avg Salary",
    CASE 
		WHEN AVG (s.salary)>= 70000 THEN "Above $70k"
        ELSE "Below $70k"
	END AS "Threshold Satus"
FROM departments d
JOIN dept_emp de
	ON d.dept_no = de.dept_no
JOIN salaries s
	ON de.emp_no = s.emp_no
WHERE de.to_date  = "9999-01-01" AND s.to_date ="9999-01-01"
GROUP BY d.dept_name
ORDER BY AVG(s.salary) DESC;

-- Departments of sale, marketing and finance exceed the average threshold $70k, Sales dept is the highest in the company - reaching $88k.

-- A distinct number of employees have changed departments at least once that mobility indicating career development culture.

-- 'Quality management department' and 'Finance department' are the most balanced gender gap existing.

-- Evey department manager earns more than the average salary of their team.

-- The most common job title is 'Senior Engineer' for Development, Quality Management and Production departments.

