-- Creating ROLE table 
CREATE TABLE ROLE (
    role_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR2(100) CHECK (role_name IN ('Admin', 'Sales Representative'))
);

-- Creating USER table 
CREATE TABLE USER_TABLE (
    user_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id INT,
    username VARCHAR2(100) NOT NULL,
    Email VARCHAR2(100) UNIQUE NOT NULL,
    FOREIGN KEY (role_id) REFERENCES ROLE(role_id)
);

-- Creating AUDIT_LOG table 
CREATE TABLE AUDIT_LOG (
    audit_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_name VARCHAR(100),
    tablename VARCHAR2(100),
    action VARCHAR2(100),
    oldValue VARCHAR2(100),
    newValue VARCHAR2(100),
    Updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  
);

-- Inserting sample data into ROLE table
INSERT INTO ROLE (role_name) VALUES ('Admin');
INSERT INTO ROLE (role_name) VALUES ('Sales Representative');

-- Inserting sample data into USER_TABLE
INSERT INTO USER_TABLE (role_id, username, Email) VALUES (1, 'Sarita', 'Sarita@example.com');
INSERT INTO USER_TABLE (role_id, username, Email) VALUES (2, 'Jashan', 'Jashan@example.com');
INSERT INTO USER_TABLE (role_id, username, Email) VALUES (2, 'Taslima', 'Taslima@example.com');

COMMIT;

-- Create CUSTOMER table with identity column
CREATE TABLE CUSTOMER (
    cust_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cust_name VARCHAR2(100),
    phone VARCHAR2(20),
    email VARCHAR2(100),
    address VARCHAR2(255)
);

-- Insert data into CUSTOMER table
INSERT INTO CUSTOMER (cust_name, phone, email, address) VALUES
('Dev Patel', '9876543210', 'dev@example.com', '123 MG Road, Mumbai');

INSERT INTO CUSTOMER (cust_name, phone, email, address) VALUES
('Vatsal Shah', '8765432109', 'vatsal@example.com', '456 Juhu Beach, Mumbai');

INSERT INTO CUSTOMER (cust_name, phone, email, address) VALUES
('Deep Singh', '7654321098', 'deep@example.com', '789 Marine Drive, Mumbai');

-- Create VEHICLE table with identity column
CREATE TABLE VEHICLE (
    Vehicle_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cust_id NUMBER,
    Licence_plate VARCHAR2(50),
    Make VARCHAR2(50),
    Model VARCHAR2(50),
    Year NUMBER,
    FOREIGN KEY (cust_id) REFERENCES CUSTOMER(cust_id)
);

-- Insert data into VEHICLE table
INSERT INTO VEHICLE (cust_id, Licence_plate, Make, Model, Year) VALUES
(1, 'MH01A1234', 'Toyota', 'Corolla', 2020);

INSERT INTO VEHICLE (cust_id, Licence_plate, Make, Model, Year) VALUES
(2, 'MH02B5678', 'Honda', 'Civic', 2019);

INSERT INTO VEHICLE (cust_id, Licence_plate, Make, Model, Year) VALUES
(3, 'MH03C9101', 'Maruti', 'Swift', 2021);


CREATE TABLE APPOINTMENT (
    app_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cust_id NUMBER,
    Vehicle_id NUMBER,
    app_date DATE,
    app_time INTERVAL DAY TO SECOND,
    Status VARCHAR2(50),
    service_id NUMBER,
    emp_id NUMBER,
    FOREIGN KEY (cust_id) REFERENCES CUSTOMER(cust_id),
    FOREIGN KEY (Vehicle_id) REFERENCES VEHICLE(Vehicle_id),
    FOREIGN KEY (emp_id) REFERENCES EMPLOYEE(emp_id)
);

-- Insert sample data into the APPOINTMENT table
INSERT INTO APPOINTMENT (cust_id, Vehicle_id, app_date, app_time, Status, service_id, emp_id) VALUES
(1, 1, TO_DATE('2023-10-01', 'YYYY-MM-DD'), INTERVAL '09:00:00' HOUR TO SECOND, 'Scheduled', 1, 1);

INSERT INTO APPOINTMENT (cust_id, Vehicle_id, app_date, app_time, Status, service_id, emp_id) VALUES
(2, 2, TO_DATE('2023-10-05', 'YYYY-MM-DD'), INTERVAL '14:30:00' HOUR TO SECOND, 'Completed', 2, 2);

INSERT INTO APPOINTMENT (cust_id, Vehicle_id, app_date, app_time, Status, service_id, emp_id) VALUES
(3, 3, TO_DATE('2023-10-10', 'YYYY-MM-DD'), INTERVAL '10:45:00' HOUR TO SECOND, 'Pending', 3, 3);

SELECT * FROM APPOINTMENT;


SELECT
    app_id,
    cust_id,
    Vehicle_id,
    app_date,
    TO_CHAR(EXTRACT(HOUR FROM app_time), 'FM00') || ':' ||
    TO_CHAR(EXTRACT(MINUTE FROM app_time), 'FM00') || ':' ||
    TO_CHAR(EXTRACT(SECOND FROM app_time), 'FM00') AS app_time_simple,
    Status,
    service_id,
    emp_id
FROM
    APPOINTMENT;


-- Create EMPLOYEE table with identity column
CREATE TABLE EMPLOYEE (
    emp_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    emp_name VARCHAR2(100),
    position VARCHAR2(50),
    emp_phn VARCHAR2(20),
    email VARCHAR2(100),
    salary NUMBER(10, 2),
    hire_date DATE,
    hours_worked NUMBER(5, 2)
);

-- Insert data into EMPLOYEE table
INSERT INTO EMPLOYEE (emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
('John Doe', 'Mechanic', '1234567890', 'john@example.com', 50000.00, TO_DATE('2020-01-15', 'YYYY-MM-DD'), 40.5);

INSERT INTO EMPLOYEE (emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
('Jane Smith', 'Service Advisor', '0987654321', 'jane@example.com', 45000.00, TO_DATE('2019-06-20', 'YYYY-MM-DD'), 38.25);

INSERT INTO EMPLOYEE (emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
('Alice Johnson', 'Manager', '1928374650', 'alice@example.com', 60000.00, TO_DATE('2018-03-25', 'YYYY-MM-DD'), 45.75);

-- Create the employee_appointment table without assigned_time
CREATE TABLE employee_appointment (
    employee_id NUMBER,
    appointment_id NUMBER,
    role VARCHAR2(50),
    PRIMARY KEY (employee_id, appointment_id),
    FOREIGN KEY (employee_id) REFERENCES EMPLOYEE(emp_id),
    FOREIGN KEY (appointment_id) REFERENCES APPOINTMENT(app_id)
);

-- Insert sample data into employee_appointment table
INSERT INTO employee_appointment (employee_id, appointment_id, role) VALUES
(1, 1, 'Mechanic');

INSERT INTO employee_appointment (employee_id, appointment_id, role) VALUES
(2, 2, 'Service Advisor');

INSERT INTO employee_appointment (employee_id, appointment_id, role) VALUES
(3, 3, 'Manager');

SELECT * FROM employee_appointment;