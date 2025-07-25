-- Library Management System

-- Create table "branch"
DROP TABLE IF EXISTS branch;
CREATE TABLE branch
(
            branch_id VARCHAR(10) PRIMARY KEY,
            manager_id VARCHAR(10),
            branch_address VARCHAR(30),
            contact_no VARCHAR(15)
);


-- Create table "Employee"
DROP TABLE IF EXISTS employees;
CREATE TABLE employees
(
            emp_id VARCHAR(10) PRIMARY KEY,
            emp_name VARCHAR(30),
            position VARCHAR(30),
            salary DECIMAL(10,2),
            branch_id VARCHAR(10),
            FOREIGN KEY (branch_id) REFERENCES  branch(branch_id)
);


-- Create table "Members"
DROP TABLE IF EXISTS members;
CREATE TABLE members
(
            member_id VARCHAR(10) PRIMARY KEY,
            member_name VARCHAR(30),
            member_address VARCHAR(30),
            reg_date DATE
);



-- Create table "Books"
DROP TABLE IF EXISTS books;
CREATE TABLE books
(
            isbn VARCHAR(50) PRIMARY KEY,
            book_title VARCHAR(80),
            category VARCHAR(30),
            rental_price DECIMAL(10,2),
            status VARCHAR(10),
            author VARCHAR(30),
            publisher VARCHAR(30)
);



-- Create table "IssueStatus"
DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status
(
            issued_id VARCHAR(10) PRIMARY KEY,
            issued_member_id VARCHAR(30),
            issued_book_name VARCHAR(80),
            issued_date DATE,
            issued_book_isbn VARCHAR(50),
            issued_emp_id VARCHAR(10),
            FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
            FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
            FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn) 
);



-- Create table "ReturnStatus"
DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status
(
            return_id VARCHAR(10) PRIMARY KEY,
            issued_id VARCHAR(30),
            return_book_name VARCHAR(80),
            return_date DATE,
            return_book_isbn VARCHAR(50),
            FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO library.books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2','To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co. ');

-- Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE 
FROM issued_status
WHERE   issued_id =   'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * 
FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT
    issued_emp_id,
    COUNT(*) total_books_issued
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1;

-- Task 6: Create Summary Tables: Use CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_issued_count
SELECT b.isbn, b.book_title, COUNT(i.issued_id) total_books_issued
FROM issued_status i
JOIN books b
ON i.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

SELECT *
FROM book_issued_count;

-- Task 7. Retrieve All Books in a Specific Category:
SELECT *
FROM books
WHERE category = 'Classic';

-- Task 8: Find Total Rental Income by Category
SELECT 
	b.category, 
    SUM(b.rental_price) total_rental_income
FROM issued_status i
JOIN books b
ON i.issued_book_isbn = b.isbn
GROUP BY b.category;

-- Task 9: List Members Who Registered in the Last 180 Days
SELECT *
FROM members
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY;

-- Task 10: List Employees with Their Branch Manager's Name and their branch details:
SELECT
	e1.emp_id,
    e1.emp_name,
    b.*,
    e2.emp_name manager_name
FROM employees e1
JOIN branch b
ON e1.branch_id = b.branch_id
JOIN employees e2
ON e2.emp_id = b.manager_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold
CREATE TABLE expensive_books 
SELECT * FROM books
WHERE rental_price > 7.00;

-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT i.issued_book_name
FROM issued_status as i
LEFT JOIN
return_status as r
ON r.issued_id = i.issued_id
WHERE r.return_id IS NULL;

-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name,
-- book title, issue date, and days overdue.
SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    -- rs.return_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1;

-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

DELIMITER $$

CREATE PROCEDURE add_return_records(
    IN p_return_id VARCHAR(10),
    IN p_issued_id VARCHAR(10),
    IN p_book_quality VARCHAR(10)
)
BEGIN
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    -- Inserting into return_status table
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURDATE(), p_book_quality);

    -- Fetching isbn and book name
    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    -- Updating book status
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    -- Simulate notice 
    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS message;

END$$

DELIMITER ;


-- Testing FUNCTION add_return_records

-- Check book info
SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

-- Check issued info
SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

-- Check return status
SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- Call the procedure
CALL add_return_records('RS138', 'IS135', 'Good');
CALL add_return_records('RS148', 'IS140', 'Good');

-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, 
-- and the total revenue generated from book rentals.

CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_reports;

-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
CREATE TABLE active_members AS
SELECT * FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= CURDATE() - INTERVAL 2 MONTH
);

SELECT * FROM active_members;

-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2;

-- Task 18: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
-- Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
-- The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
-- The procedure should first check if the book is available (status = 'yes'). 
-- If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
-- If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

DELIMITER $$

CREATE PROCEDURE issue_book(
    IN p_issued_id VARCHAR(10),
    IN p_issued_member_id VARCHAR(30),
    IN p_issued_book_isbn VARCHAR(30),
    IN p_issued_emp_id VARCHAR(10)
)
BEGIN
    DECLARE v_status VARCHAR(10);

    -- Get the book's current status
    SELECT status
    INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    -- Check if the book is available
    IF v_status = 'yes' THEN
        -- Insert issue record
        INSERT INTO issued_status (
            issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id
        ) VALUES (
            p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id
        );

        -- Update the book status to 'no' (unavailable)
        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        -- Simulate RAISE NOTICE
        SELECT CONCAT('Book records added successfully for book ISBN: ', p_issued_book_isbn) AS message;

    ELSE
        -- Simulate RAISE NOTICE for unavailable book
        SELECT CONCAT('Sorry, the book is unavailable. ISBN: ', p_issued_book_isbn) AS message;
    END IF;
END$$

DELIMITER ;

-- Check books and their availability
SELECT * FROM books;

-- Sample ISBNs:
-- "978-0-553-29698-2" -- should be available ("yes")
-- "978-0-375-41398-8" -- should be unavailable ("no")

-- Check issued records
SELECT * FROM issued_status;

-- Call the procedure with test data
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104'); -- should succeed
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104'); -- should show unavailable

-- Verify updated status
SELECT * FROM books WHERE isbn = '978-0-375-41398-8';
