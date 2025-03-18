-- Create sequences for each table
CREATE SEQUENCE role_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE user_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE audit_seq START WITH 1 INCREMENT BY 1;

-- Create the ROLE table
CREATE TABLE ROLE (
    role_id NUMBER PRIMARY KEY,
    role_name VARCHAR2(100) 
);

-- Create the USER_TABLE 
CREATE TABLE USER_TABLE (
    user_id NUMBER PRIMARY KEY,
    role_id NUMBER,
    username VARCHAR2(100) NOT NULL,
    Email VARCHAR2(100) UNIQUE NOT NULL,
    Password VARCHAR2(100) NOT NULL,
    FOREIGN KEY (role_id) REFERENCES ROLE(role_id)
);

-- Create the AUDIT_LOG table 
CREATE TABLE AUDIT_LOG (
    audit_id NUMBER PRIMARY KEY,
    user_name VARCHAR(100),
    tablename VARCHAR2(100),
    action VARCHAR2(100),
    oldValue VARCHAR2(100),
    newValue VARCHAR2(100),
    Updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  
);

-- Insert sample data into ROLE table 
INSERT INTO ROLE (role_id, role_name) VALUES (role_seq.NEXTVAL, 'Admin');
INSERT INTO ROLE (role_id, role_name) VALUES (role_seq.NEXTVAL, 'Sales Representative');

-- Insert sample data into USER_TABLE 
INSERT INTO USER_TABLE (user_id, role_id, username, Email, Password) 
    VALUES (user_seq.NEXTVAL, 1, 'Sarita', 'Sarita@example.com', 'pass123');
INSERT INTO USER_TABLE (user_id, role_id, username, Email, Password) 
    VALUES (user_seq.NEXTVAL, 2, 'Jashan', 'Jashan@example.com', 'secure456');
INSERT INTO USER_TABLE (user_id, role_id, username, Email, Password) 
    VALUES (user_seq.NEXTVAL, 2, 'Taslima', 'Taslima@example.com', 'pwd789');
INSERT INTO USER_TABLE (user_id, role_id, username, Email, Password) 
    VALUES (user_seq.NEXTVAL, 1, 'Deep', 'Deep@example.com', 'deeppass1');
INSERT INTO USER_TABLE (user_id, role_id, username, Email, Password) 
    VALUES (user_seq.NEXTVAL, 1, 'Khush', 'Khush@example.com', 'khush456');
INSERT INTO USER_TABLE (user_id, role_id, username, Email, Password) 
    VALUES (user_seq.NEXTVAL, 2, 'Dev', 'Dev@example.com', 'dev789');
    
-- Insert sample data into AUDIT_LOG table
INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
    VALUES (audit_seq.NEXTVAL, 'Sarita', 'USER_TABLE', 'UPDATE', 
            'Sarita@example.com', 'Sarita.updated@example.com', 
            TIMESTAMP '2025-03-18 10:00:00');

INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
    VALUES (audit_seq.NEXTVAL, 'Jashan', 'ROLE', 'UPDATE', 
            'Sales Representative', 'Sales Rep', 
            TIMESTAMP '2025-03-18 12:00:00');

-- Commit
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

-- Create the APPOINTMENT table
CREATE TABLE APPOINTMENT (
    app_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    cust_id NUMBER,
    vehicle_id NUMBER,
    app_date DATE,
    app_time TIMESTAMP, 
    status VARCHAR2(50),
    service_id NUMBER,
    emp_id NUMBER,
    FOREIGN KEY (cust_id) REFERENCES CUSTOMER(cust_id),
    FOREIGN KEY (vehicle_id) REFERENCES VEHICLE(vehicle_id),
    FOREIGN KEY (emp_id) REFERENCES EMPLOYEE(emp_id),
    FOREIGN KEY (service_id) REFERENCES SERVICE(service_id) 
);

-- Insert sample data into APPOINTMENT table
INSERT INTO APPOINTMENT (cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(1, 1, TO_DATE('2023-10-01', 'YYYY-MM-DD'), TO_TIMESTAMP('09:00:00', 'HH24:MI:SS'), 'Scheduled', 1, 1);

INSERT INTO APPOINTMENT (cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(2, 2, TO_DATE('2023-10-05', 'YYYY-MM-DD'), TO_TIMESTAMP('14:30:00', 'HH24:MI:SS'), 'Completed', 2, 2);

INSERT INTO APPOINTMENT (cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(3, 3, TO_DATE('2023-10-10', 'YYYY-MM-DD'), TO_TIMESTAMP('10:45:00', 'HH24:MI:SS'), 'Pending', 3, 3);

SELECT * FROM APPOINTMENT;

SELECT
    app_id,
    cust_id,
    vehicle_id,
    app_date,
    TO_CHAR(app_time, 'HH24:MI:SS') AS app_time_simple,
    status,
    service_id,
    emp_id
FROM
    APPOINTMENT;


-- Create EMPLOYEE table
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

-- Create the employee_appointment table 
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

--create service table
CREATE TABLE Service (
    service_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    service_type VARCHAR2(100) ,
    service_date DATE ,
    status VARCHAR2(100),
    cost NUMBER(10,2) 
);

--create invoice table
CREATE TABLE Invoice (
    invoice_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    service_id NUMBER ,
    app_id NUMBER ,
    invoice_date DATE ,
    total_amount NUMBER(10,2),
    created_at DATE ,
    FOREIGN KEY (service_id) REFERENCES Service(service_id),
    FOREIGN KEY (app_id) REFERENCES Appointment(app_id)
);

--create payment table
CREATE TABLE Payment (
    payment_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    invoice_id NUMBER ,
    payment_date DATE ,
    amount_paid NUMBER(10,2),
    payment_method VARCHAR2(100),
    status VARCHAR2(100),
    FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
);

--insert into service table
INSERT INTO Service (service_type, service_date, status, cost)
VALUES ('Oil Change', TO_DATE('2024-02-01', 'YYYY-MM-DD'), 'Completed', 50.00);

INSERT INTO Service (service_type, service_date, status, cost)
VALUES ('Brake Replacement', TO_DATE('2024-02-02', 'YYYY-MM-DD'), 'Pending', 200.00);

INSERT INTO Service (service_type, service_date, status, cost)
VALUES ('Tire Rotation', TO_DATE('2024-02-03', 'YYYY-MM-DD'), 'Completed', 40.00);

--insert into invoice table
INSERT INTO Invoice (service_id, app_id, invoice_date, total_amount, created_at)
VALUES (1, 1, TO_DATE('2024-02-05', 'YYYY-MM-DD'), 50.00, TO_DATE('2024-02-05', 'YYYY-MM-DD'));

INSERT INTO Invoice (service_id, app_id, invoice_date, total_amount, created_at)
VALUES (2, 2, TO_DATE('2024-02-06', 'YYYY-MM-DD'), 200.00, TO_DATE('2024-02-06', 'YYYY-MM-DD'));

INSERT INTO Invoice (service_id, app_id, invoice_date, total_amount, created_at)
VALUES (3, 3, TO_DATE('2024-02-07', 'YYYY-MM-DD'), 40.00, TO_DATE('2024-02-07', 'YYYY-MM-DD'));

--insert into payment table
INSERT INTO Payment (invoice_id, payment_date, amount_paid, payment_method, status)
VALUES (4, TO_DATE('2024-02-08', 'YYYY-MM-DD'), 50.00, 'Credit Card', 'Successful');

INSERT INTO Payment (invoice_id, payment_date, amount_paid, payment_method, status)
VALUES (5, TO_DATE('2024-02-09', 'YYYY-MM-DD'), 200.00, 'Cash', 'Pending');

INSERT INTO Payment (invoice_id, payment_date, amount_paid, payment_method, status)
VALUES (6, TO_DATE('2024-02-10', 'YYYY-MM-DD'), 40.00, 'Debit Card', 'Successful');


--create inventory table
CREATE TABLE inventory (
    item_id        NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,  
    item_name      VARCHAR2(100),                              
    quantity       NUMBER,                                   
    price_per_unit NUMBER(10, 2)                              
);

-- create service_inventory table
CREATE TABLE service_inventory (
    service_id     NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,  
    item_id        NUMBER ,                                      
    quantity_used  NUMBER,                                      
    CONSTRAINT fk_item_id FOREIGN KEY (item_id)                         
    REFERENCES inventory(item_id)
);


--Insert into inventory table
INSERT INTO inventory (item_name, quantity, price_per_unit)
VALUES ('Engine Oil', 100, 15.50);

INSERT INTO inventory (item_name, quantity, price_per_unit)
VALUES ('Brake Pads', 50, 40.00);

--Insert data into service_inventory table

INSERT INTO service_inventory (item_id, quantity_used)
VALUES (1, 2); 

INSERT INTO service_inventory (item_id, quantity_used)
VALUES (2, 1); 


select * from inventory
select * from service_inventory

