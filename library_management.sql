CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    author VARCHAR(100),
    isbn VARCHAR(30) UNIQUE,
    available_copies INT NOT NULL
);

CREATE TABLE members (
    member_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    join_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE loans (
    loan_id SERIAL PRIMARY KEY,
    book_id INT REFERENCES books(book_id),
    member_id INT REFERENCES members(member_id),
    checkout_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE
);

CREATE TABLE fines (
    fine_id SERIAL PRIMARY KEY,
    loan_id INT REFERENCES loans(loan_id),
    member_id INT REFERENCES members(member_id),
    amount NUMERIC(10,2),
    paid_status VARCHAR(20) DEFAULT 'Unpaid'
);


INSERT INTO books(title, author, isbn, available_copies)
VALUES
('Database Systems', 'Korth', 'ISBN001', 5),
('SQL Fundamentals', 'John Smith', 'ISBN002', 4),
('Python Basics', 'Guido', 'ISBN003', 6),
('Data Structures', 'Mark Allen', 'ISBN004', 3),
('Operating Systems', 'Galvin', 'ISBN005', 2),
('Computer Networks', 'Tanenbaum', 'ISBN006', 5),
('Java Programming', 'Herbert Schildt', 'ISBN007', 4),
('AI Basics', 'Russell', 'ISBN008', 3),
('Machine Learning', 'Tom Mitchell', 'ISBN009', 4),
('Cloud Computing', 'Rajkumar Buyya', 'ISBN010', 5);

INSERT INTO members(name,email,phone,join_date)
VALUES
('Aman','aman@gmail.com','1111111111','2024-01-01'),
('Rahul','rahul@gmail.com','2222222222','2024-01-05'),
('Priya','priya@gmail.com','3333333333','2024-01-10'),
('Neha','neha@gmail.com','4444444444','2024-01-15'),
('Arjun','arjun@gmail.com','5555555555','2024-01-20'),
('Karan','karan@gmail.com','6666666666','2024-01-25'),
('Riya','riya@gmail.com','7777777777','2024-02-01'),
('Pooja','pooja@gmail.com','8888888888','2024-02-05'),
('Vikas','vikas@gmail.com','9999999999','2024-02-10'),
('Anjali','anjali@gmail.com','1010101010','2024-02-15');

INSERT INTO loans(book_id, member_id, checkout_date, due_date, return_date)
VALUES
(1,1,'2024-05-01','2024-05-10','2024-05-12'),
(2,2,'2024-05-02','2024-05-12','2024-05-13'),
(3,3,'2024-05-03','2024-05-15',NULL),
(4,4,'2024-05-05','2024-05-20',NULL),
(5,5,'2024-05-07','2024-05-17','2024-05-18'),
(1,2,'2024-05-10','2024-05-20','2024-05-20'),
(2,3,'2024-05-11','2024-05-21','2024-05-22'),
(1,4,'2024-05-12','2024-05-22','2024-05-24');

CREATE OR REPLACE FUNCTION calculate_fine(p_loan_id INT)
RETURNS VOID
LANGUAGE plpgsql
AS
$$
DECLARE
    late_days INT;
    fine_amount NUMERIC(10,2);
BEGIN

    SELECT (return_date - due_date)
    INTO late_days
    FROM loans
    WHERE loan_id = p_loan_id;

    IF late_days > 0 THEN

        fine_amount := late_days * 0.50;

        INSERT INTO fines
        (
            loan_id,
            member_id,
            amount,
            paid_status
        )
        SELECT
            loan_id,
            member_id,
            fine_amount,
            'Unpaid'
        FROM loans
        WHERE loan_id = p_loan_id;

    END IF;

END;
$$;

-- EXECUTE FUNCTION
SELECT calculate_fine(1);
SELECT calculate_fine(2);
SELECT calculate_fine(5);
SELECT calculate_fine(7);
SELECT calculate_fine(8);

CREATE OR REPLACE FUNCTION check_unpaid_fines()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
DECLARE
    total_fine NUMERIC(10,2);
BEGIN

    SELECT COALESCE(SUM(amount),0)
    INTO total_fine
    FROM fines
    WHERE member_id = NEW.member_id
    AND paid_status='Unpaid';

    IF total_fine > 10 THEN
        RAISE EXCEPTION
        'Member has unpaid fines above $10';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_unpaid_fines
BEFORE INSERT ON loans
FOR EACH ROW
EXECUTE FUNCTION check_unpaid_fines();

-- 1. CURRENTLY BORROWED BOOKS

SELECT
    b.title,
    m.name,
    l.due_date
FROM loans l
JOIN books b
ON l.book_id = b.book_id
JOIN members m
ON l.member_id = m.member_id
WHERE l.return_date IS NULL;

-- 2. OVERDUE BOOKS

SELECT
    b.title,
    m.name,
    l.due_date
FROM loans l
JOIN books b
ON l.book_id = b.book_id
JOIN members m
ON l.member_id = m.member_id
WHERE l.return_date IS NULL
AND l.due_date < CURRENT_DATE;

-- 3. TOTAL UNPAID FINES PER MEMBER

SELECT
    m.member_id,
    m.name,
    COALESCE(SUM(f.amount),0) AS total_unpaid_fines
FROM members m
LEFT JOIN fines f
ON m.member_id = f.member_id
AND f.paid_status='Unpaid'
GROUP BY m.member_id,m.name
ORDER BY total_unpaid_fines DESC;

-- 4. TOP 5 MOST BORROWED BOOKS

SELECT
    b.book_id,
    b.title,
    COUNT(*) AS borrow_count
FROM loans l
JOIN books b
ON l.book_id=b.book_id
GROUP BY b.book_id,b.title
ORDER BY borrow_count DESC
LIMIT 5;

-- 5. MEMBERS WHO NEVER BORROWED A BOOK

SELECT
    m.*
FROM members m
LEFT JOIN loans l
ON m.member_id=l.member_id
WHERE l.loan_id IS NULL;

-- VIEW FINES TABLE

SELECT * FROM fines;

-- VIEW ALL TABLES

SELECT * FROM books;
SELECT * FROM members;
SELECT * FROM loans;
SELECT * FROM fines;