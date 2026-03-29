-- Q1
select 
    first_name ||' ' || last_name,
    coalesce(nationality, 'Unknown') as nationality
from students;

-- Q2
select 
    first_name ||' ' || last_name,
    gpa as real_gpa,
    nullif(gpa, 0.0) as cleaned_gpa
from students;

-- Q3
select 
    first_name ||' ' || last_name,
    coalesce(nullif(gpa, 0.0)::TEXT, 'Not Evaluated') as gpa_status
from students;

select 
    d.dept_name,
    COUNT(s.student_id) AS student_count,
    coalesce(
        sum(nullif(s.gpa, 0)) / nullif(count(nullif(s.gpa, 0)), 0),
        0
    ) as avg_gpa
from students s
join departments d on s.dept_id = d.dept_id
group by d.dept_name;

-- Q4
create temp table temp_course_stats AS
select 
    c.course_code,
    c.course_name,
    count(e.student_id) AS enrolled_count,
    avg(e.grade) as avg_grade
from courses c
left join enrollments e ON c.course_id = e.course_id
group BY c.course_code, c.course_name;

SELECT *
FROM temp_course_stats
WHERE avg_grade > 75;

-- Q5
create index idx_students_dept_id
ON students(dept_id);

-- Q6
create unique index idx_students_email
ON students(email);

insert into students (first_name,last_name, email)
values ('Ali','alaa', 'test@example.com');

insert into students (first_name,last_name, email)
values ('Ahmed','mohamed', 'test@example.com');

-- Q7
create index idx_prof_salary_active
on professors(salary)
where is_active = TRUE;

-- Q8
create view v_student_details AS
select 
    s.student_id,
    (s.first_name || ' '|| s.last_name) AS full_name,
    s.email,
    s.gpa,
    d.dept_name,
    f.faculty_name,
	s.dept_id
from students s
join departments d ON s.dept_id = d.dept_id
join faculties f ON d.faculty_id = f.faculty_id;

select *
from v_student_details
where dept_id = 3;

-- Q9
create table enrollment_audit (
    audit_id SERIAL PRIMARY KEY,
    student_id INT,
    old_grade NUMERIC,
    new_grade NUMERIC,
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    changed_by TEXT DEFAULT CURRENT_USER
);
--
create OR replace function log_grade_change()
returns trigger AS $$
BEGIN
    if NEW.grade IS DISTINCT from OLD.grade then
        insert into enrollment_audit (student_id, old_grade, new_grade)
        values (OLD.student_id, OLD.grade, NEW.grade);
    END if;
    return NEW;
END;
$$ LANGUAGE plpgsql;

--
create trigger trg_grade_update
before update ON enrollments
for each row
execute function log_grade_change();

-- Q10
update enrollments
set grade = 90
where enrollment_id = 1;

-- Q11
create OR replace function fix_salary()
returns trigger AS $$
BEGIN
    if NEW.salary IS NULL OR NEW.salary < 5000 then
        NEW.salary := 5000;
    END if;
    return NEW;
END;
$$ LANGUAGE plpgsql;
----
create trigger trg_fix_salary
before insert ON professors
for each row
execute function fix_salary();

-- Q12
CREATE TABLE IF NOT EXISTS salary_log ( 
  log_id    SERIAL PRIMARY KEY, 
  prof_id   INTEGER, 
  old_salary NUMERIC, 
  new_salary NUMERIC, 
  changed_by TEXT DEFAULT CURRENT_USER, 
  changed_at TIMESTAMPTZ DEFAULT NOW() 
); 

BEGIN;

update professors
set salary = salary * 1.10
where dept_id = 1;

insert into salary_log (prof_id, old_salary, new_salary)
select 
    prof_id,
    salary / 1.10,
    salary
from professors
where dept_id = 1;

COMMIT;

-- Q13
begin;

delete from enrollments
where student_id = 1;

select * from enrollments where student_id = 1;

rollback;

select * from enrollments where student_id = 1;

-- Q14
begin;

update faculties
set budget = budget + 500000
where faculty_id = 1;

savepoint after_first_update;

update faculties
set budget = budget + 500000
where faculty_id = 2;

rollback to savepoint after_first_update;

commit;

-- Q15
create role uni_readonly;
create role uni_readwrite;

grant select on all tables in schema public to uni_readonly;
grant select, insert, update on all tables in schema public to uni_readwrite;

set role uni_readonly;
select * from students;

insert into students (first_name,last_name,email) values ('test','test22','test22@gmail.com');

reset role;

-- Q16
revoke delete on students from uni_readwrite;

revoke all on students from uni_readwrite;

revoke all on students from uni_readonly;

-- Q17
-- full backup
-- pg_dump university_db > full_backup.sql

-- schema only
-- pg_dump -s university_db > schema_only.sql

-- data only
-- pg_dump -a university_db > data_only.sql

