USE training_center_rdbms_1;

DROP TABLE IF EXISTS `session`;
DROP TABLE IF EXISTS `take`;								
DROP TABLE IF EXISTS `module`;
DROP TABLE IF EXISTS `course`; 
DROP TABLE IF EXISTS `delegate`;


-- Start Creating Tables with variables, data types, lengths, and constraints
CREATE TABLE delegate (
    `no` INT NOT NULL,
    `name` VARCHAR(30) NOT NULL,
    `phone` VARCHAR(30) NULL,
	CONSTRAINT pri_delegate PRIMARY KEY (no)
);

CREATE TABLE course (
    `code` CHAR(3) NOT NULL,
    `name` VARCHAR(30) NOT NULL,
    `credits` TINYINT NOT NULL,
    CONSTRAINT pri_course PRIMARY KEY (`code`)
);

CREATE TABLE module (
    `code` CHAR(2) NOT NULL,
    `name` VARCHAR(30) NOT NULL,
    `cost` DECIMAL(8,2) NOT NULL,	
    `credits` TINYINT NOT NULL,
    `course_code` CHAR(3) NOT NULL,
    CONSTRAINT pri_module PRIMARY KEY (`code`),
    CONSTRAINT for_course FOREIGN KEY (course_code) REFERENCES course (`code`) ON UPDATE CASCADE 
);

CREATE TABLE take (
    `no` INT(2) NOT NULL,
    `code` CHAR(2) NOT NULL,
    `grade`	 TINYINT NULL,
    CONSTRAINT pri_take PRIMARY KEY (no, code),
    CONSTRAINT for_take_delegate FOREIGN KEY (`no`) REFERENCES delegate (`no`) ON UPDATE CASCADE,
    CONSTRAINT for_take_module FOREIGN KEY (`code`) REFERENCES module (`code`) ON UPDATE CASCADE
);

CREATE TABLE session (
    `code` CHAR(2) NOT NULL,
    `date` DATE NOT NULL,
    `room` VARCHAR(30) NULL,
	CONSTRAINT pri_session PRIMARY KEY (code, date),
    CONSTRAINT for_session FOREIGN KEY (`code`) REFERENCES module (`code`) ON UPDATE CASCADE 
);
CREATE INDEX idx_delegate
ON delegate (`no`, `name`, `phone`);

CREATE INDEX idx_course
ON course (`code`, `name`, `credits`);

CREATE INDEX idx_module
ON module (`code`, `name`, `cost`, `credits`, `course_code`);

CREATE INDEX idx_take
ON take (`no`, `code`, `grade`);

CREATE INDEX idx_session
ON session (`code`, `date`, `room`);
-- Insert Data into tables	

INSERT INTO `course` (`code`, `name`, `credits`)
VALUES
    ('WSD', 'Web Systems Development', 75),
    ('DDM', 'Database Design & Management', 100),
    ('NSF', 'Network Security & Forensics', 75);

INSERT INTO module (code, name, cost, credits, course_code)
VALUES
    ('A2', 'ASP.NET', 250, 25, 'WSD'),
    ('A3', 'PHP', 250, 25, 'WSD'),
    ('A4', 'JavaFX', 350, 25, 'WSD'),
    ('B2', 'Oracle', 750, 50, 'DDM'),
    ('B3', 'SQLS', 750, 50, 'DDM'),
    ('C2', 'Law', 250, 25, 'NSF'),
    ('C3', 'Forensics', 350, 25, 'NSF'),
    ('C4', 'Networks', 250, 25, 'NSF');


INSERT INTO `session` (code, date, room)
VALUES
    ('A2', '2023-06-05', '305'),
    ('A3', '2023-06-06', '307'),
    ('A4', '2023-06-07', '305'),
    ('B2', '2023-08-22', '208'),
    ('B3', '2023-08-23', '208'),
    ('A2', '2024-05-01', '303'),
    ('A3', '2024-05-02', '305'),
    ('A4', '2024-05-03', '303'),
    ('B2', '2024-07-10', NULL),  -- Assuming NULL for the room number or ''
    ('B3', '2024-07-11', NULL); -- Assuming NULL for the room number or ''
    

INSERT INTO `delegate` (no, name, phone)
VALUES
    (2001, 'Mike', NULL),
    (2002, 'Andy', NULL),
    (2003, 'Sarah', NULL),
    (2004, 'Karen', NULL),
    (2005, 'Lucy', NULL),
    (2006, 'Steve', NULL),
    (2007, 'Jenny', NULL),
    (2008, 'Tom', NULL);
    
INSERT INTO `take` (no, code, grade)
VALUES
    (2003, 'A2', 68),
    (2003, 'A3', 72),
    (2003, 'A4', 53),
    (2005, 'A2', 48),
    (2005, 'A3', 52),
    (2002, 'A2', 20),
    (2002, 'A3', 30),
    (2002, 'A4', 50),
    (2008, 'B2', 90),
    (2007, 'B2', 73),
    (2007, 'B3', 63);



DROP VIEW IF EXISTS future_sessions;

CREATE VIEW future_sessions AS
SELECT *
FROM session
WHERE date >= CURRENT_DATE WITH CHECK OPTION;

INSERT INTO future_sessions (code, date, room) VALUES ('C2', '2023-01-01', '302');	-- Past session test, should result in error.
-- INSERT INTO future_sessions (code, date, room) VALUES ('C2', '2024-01-01', '302');  -- Future session test, should appear in future_sessions view
SELECT * FROM coursework_1.future_sessions;
								

DROP PROCEDURE IF EXISTS AssignSchedule;

CREATE PROCEDURE AssignSchedule(IN courseCode CHAR(3), IN startDate DATE)
BEGIN
    DECLARE currentDate DATE;
    DECLARE currentModuleCode CHAR(2);
    DECLARE currentModuleName VARCHAR(30);
    DECLARE done BOOLEAN DEFAULT FALSE;
    
    DECLARE curModules CURSOR FOR
        SELECT code, name
        FROM module
        WHERE course_code = courseCode;

    /* Declare continue handler for the cursor */
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Check if the start date is at least a month in the future
    IF startDate < CURRENT_DATE + INTERVAL 1 MONTH THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Start date must be at least a month in the future';
        SET done = TRUE; -- error message 
        ELSE
        
        SELECT 'Scheduling started successfully' AS Result; -- Show message if schduled successfully
        
    END IF;

    -- Loop through modules and schedule them
    OPEN curModules;
    readLoop: LOOP
        FETCH curModules INTO currentModuleCode, currentModuleName;

        -- Exit the loop if no more rows
        IF done THEN
            LEAVE readLoop;
        END IF;

        /* Print course code and start dates to verify */
        SELECT CONCAT('Scheduled module ', currentModuleCode, ' (', currentModuleName, ') on ', startDate) AS Result;

        -- Move to the next day for the next module
        SET startDate = startDate + INTERVAL 1 DAY;
    END LOOP;
    CLOSE curModules;
END
//
DELIMITER ;


-- Create the grade_audit table
DROP TABLE IF EXISTS grade_audit;

CREATE TABLE grade_audit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    delegate_no INT(2) NOT NULL,
    old_grade TINYINT NOT NULL,
    new_grade TINYINT NOT NULL,
    username VARCHAR(30) NOT NULL,
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (delegate_no) REFERENCES delegate (`no`) ON UPDATE CASCADE
);

-- Create the trigger
DELIMITER $$

CREATE TRIGGER before_update_delegate_grade
BEFORE UPDATE ON delegate
FOR EACH ROW
BEGIN
    -- Check if the grade is being updated
    IF new_grade <> old_grade THEN
        -- Insert an entry into the grade_audit table
        INSERT INTO grade_audit (delegate_no, old_grade, new_grade, username)
        VALUES (old_no, old_grade, new_grade, CURRENT_USER());
    END IF;
END;
$$

DELIMITER ;

1) Fetch every module’s code, name & credits. 
SELECT code, name, credits
FROM module;

2) Fetch every delegate’s no & name in descending order by name.
SELECT `no`, name
FROM delegate
ORDER BY name DESC;

3) Fetch the course’s code, name & credits where the name contains the string “Network”.
SELECT code, name, credits
FROM course
WHERE name LIKE '%Network%';

4) Calculate the highest grade in any module 
SELECT MAX(grade) AS highest_grade
FROM take;

5) Modify the query from Q4 to now fetch only the delegate no. 
SELECT no AS delegate_no
FROM take
WHERE grade = (SELECT MAX(grade) FROM take);
6) Modify the query from Q5 to also fetch the delegate name. ????
SELECT t.no AS delegate_no, 
       (SELECT name FROM delegate d WHERE d.no = t.no) AS delegate_name
FROM take t
WHERE t.grade = (SELECT MAX(grade) FROM take);

7) Fetch the sessions's code & date for sessions running in the next year and for which no room has been allocated
SELECT code, date
FROM session
WHERE YEAR(date) = YEAR(CURRENT_DATE()) + 1
  AND room IS NULL;
  
 8) Fetch the delegate’s no & name along with the module’s code & name for delegates who have taken a module but have a failing grade. 

SELECT d.`no` AS delegate_no, d.name AS delegate_name, t.code AS module_code, m.name AS module_name
FROM delegate d
JOIN take t ON d. `no` = t.`no`
JOIN Module m ON t.code = m.code
WHERE t.grade < 40;

9) Solve the problem from Q6 using JOINS where possible.

SELECT t.no AS delegate_no, d.name AS delegate_name
FROM take t
JOIN delegate d ON t.no = d.no
WHERE t.grade = (SELECT MAX(grade) FROM take);




10) Calculate and display every delegate’s no & name along with their attained credits versus the course’s code, name & credits.  

SELECT
	d.`no` AS delegate_no,
    d.name AS delegate_name,
    SUM(m.credits) AS attained_credits,
    c.code AS course_code,
    c.name AS course_name,
    c.credits AS total_course_credits
FROM
	delegate d
JOIN 
	take t ON d.`no` = t.`no`
JOIN
	module m ON t.code = m.code
JOIN
	course c ON m.course_code = c.code
GROUP BY
	d.`no`, d.name, c.code, c.name, c.credits;
    
11) Modify the query from Q10 to only show a delegate when they have attained the course’s credits. 
    
SELECT
d.`no` AS delegate_no,
d.name AS delegate_name,
SUM(m.credits) AS attained_credits,
c.code AS course_code,
c.name AS course_name,
c.credits AS total_course_credits
FROM
    delegate d
JOIN
    take t ON d.`no` = t.`no`
JOIN
    module m ON t.code = m.code
JOIN
    course c ON m.course_code = c.code
GROUP BY
    d.`no`, d.name, c.code, c.name, c.credits
HAVING
    attained_credits >= c.credits;