# Library Management System

## Project Description

A SQL-based Library Management System developed using PostgreSQL.

The project manages:

* Books
* Members
* Book Loans
* Fine Tracking

## Database Tables

### Books

* book_id
* title
* author
* isbn
* available_copies

### Members

* member_id
* name
* email
* phone
* join_date

### Loans

* loan_id
* book_id
* member_id
* checkout_date
* due_date
* return_date

### Fines

* fine_id
* loan_id
* member_id
* amount
* paid_status

## Features

* Track borrowed books
* Find overdue books
* Calculate unpaid fines
* Identify popular books
* Stored Function for fine calculation
* Trigger to restrict borrowing with high unpaid fines

## Technologies Used

* PostgreSQL
* pgAdmin 4

## Author

Kanak Sharma
