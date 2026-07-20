# SQL Sales Analysis / Employee Database Project

## Overview
This project contains SQL scripts for analyzing an employee database using MySQL. The queries explore employee organization, compensation, department movement, salary growth, diversity, and management insights.

## Files
- employees database.sql - SQL script with employee database queries and analysis logic
- sql_project (employees database).sql - Main SQL project file with analytical queries, a view, and a stored procedure
- Schema link - View the database schema through Google Drive: https://drive.google.com/file/d/1TGElszQj6KfTqqlM90ajx66A0uBwitGy/view?usp=drive_link

## What This Project Covers
The SQL scripts include analyses for:
- Current department of each employee
- Top 5 highest-paid employees by department and gender
- Departments with average salary above $70,000
- Most common job title per department
- Employees who changed departments multiple times
- Salary growth percentage over time
- Gender diversity by department
- Average salary comparison for department managers
- A view and stored procedure for department-level summaries

## Requirements
- MySQL database server
- The employee sample database loaded in your MySQL environment
- A SQL client such as MySQL Workbench, HeidiSQL, or the MySQL CLI

## How to Use
1. Open the SQL file in your preferred MySQL client.
2. Connect to your MySQL database instance.
3. Ensure the employees database is available.
4. Run the queries in order.

## Notes
- The script uses MySQL-specific syntax such as DELIMITER and stored procedures.
- Some queries rely on the employees sample dataset structure, including tables such as employees, departments, dept_emp, salaries, and titles.

## Example Insights
The project highlights patterns such as:
- High-paying departments and salary trends
- Department mobility and employee growth
- Gender balance across departments
- Management compensation relative to team averages
