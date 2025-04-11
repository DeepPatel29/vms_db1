-- Drop and recreate all sequences with CYCLE
DROP SEQUENCE role_seq;
DROP SEQUENCE user_seq;

-- Role sequence (1 to 50)
CREATE SEQUENCE role_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 50
    CYCLE;

-- User sequence (51 to 100)
CREATE SEQUENCE user_seq
    START WITH 51
    INCREMENT BY 1
    MINVALUE 51
    MAXVALUE 100
    CYCLE;

CREATE SEQUENCE audit_seq START WITH 1 INCREMENT BY 1;


DROP SEQUENCE invoice_seq;
CREATE SEQUENCE invoice_seq START WITH 3001 INCREMENT BY 1 MINVALUE 3001 MAXVALUE 4000 CYCLE;

DROP SEQUENCE payment_seq;
CREATE SEQUENCE payment_seq START WITH 4001 INCREMENT BY 1 MINVALUE 4001 MAXVALUE 5000 CYCLE;

DROP SEQUENCE customer_seq;
CREATE SEQUENCE customer_seq START WITH 5001 INCREMENT BY 1 MINVALUE 5001 MAXVALUE 7000 CYCLE;

DROP SEQUENCE vehicle_seq;
CREATE SEQUENCE vehicle_seq START WITH 7001 INCREMENT BY 1 MINVALUE 7001 MAXVALUE 9000 CYCLE;

DROP SEQUENCE appointment_seq;
CREATE SEQUENCE appointment_seq START WITH 9001 INCREMENT BY 1 MINVALUE 9001 MAXVALUE 12000 CYCLE;

DROP SEQUENCE employee_seq;
CREATE SEQUENCE employee_seq START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 1000 CYCLE;


DROP SEQUENCE service_seq;
CREATE SEQUENCE service_seq START WITH 1001 INCREMENT BY 1 MINVALUE 1001 MAXVALUE 2000 CYCLE;

DROP SEQUENCE inventory_seq;
CREATE SEQUENCE inventory_seq START WITH 2001 INCREMENT BY 1 MINVALUE 2001 MAXVALUE 3000 CYCLE;

DROP SEQUENCE employee_appointment_seq;
CREATE SEQUENCE employee_appointment_seq START WITH 12001 INCREMENT BY 1 MINVALUE 12001 MAXVALUE 15000 CYCLE;

-- Create the ROLE table
CREATE TABLE ROLE (
    role_id NUMBER PRIMARY KEY,
    role_name VARCHAR2(100) 
);

-- Add NOT NULL and UNIQUE constraint to role_name
ALTER TABLE ROLE
MODIFY (role_name VARCHAR2(100) NOT NULL);

ALTER TABLE ROLE
ADD CONSTRAINT uk_role_name UNIQUE (role_name);

-- Create the USER_TABLE 
CREATE TABLE USER_TABLE (
    user_id NUMBER PRIMARY KEY,
    role_id NUMBER,
    username VARCHAR2(100) NOT NULL,
    Email VARCHAR2(100) UNIQUE NOT NULL,
    Password VARCHAR2(256) NOT NULL,
    FOREIGN KEY (role_id) REFERENCES ROLE(role_id)
);

-- Modify USER_TABLE table(adding default role_id to be 2(Sales Representative))
ALTER TABLE USER_TABLE
MODIFY (role_id NUMBER DEFAULT 2);

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



-- Create CUSTOMER table 
CREATE TABLE CUSTOMER (
    cust_id NUMBER PRIMARY KEY,
    cust_name VARCHAR2(50),
    phone VARCHAR2(13),
    email VARCHAR2(50),
    address VARCHAR2(255)
);

-- Create VEHICLE table 
CREATE TABLE VEHICLE (
    Vehicle_id NUMBER PRIMARY KEY,
    cust_id NUMBER,
    Licence_plate VARCHAR2(50),
    Make VARCHAR2(50),
    Model VARCHAR2(50),
    Year NUMBER,
    FOREIGN KEY (cust_id) REFERENCES CUSTOMER(cust_id)
);


-- Create EMPLOYEE table with sequence
CREATE TABLE EMPLOYEE (
    emp_id NUMBER PRIMARY KEY,
    emp_name VARCHAR2(100),
    position VARCHAR2(50),
    emp_phn VARCHAR2(20),
    email VARCHAR2(100),
    salary NUMBER(10, 2),
    hire_date DATE,
    hours_worked NUMBER(5, 2)
);

-- Create the APPOINTMENT table 
CREATE TABLE APPOINTMENT (
    app_id NUMBER PRIMARY KEY,
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

-- Create the employee_appointment 
CREATE TABLE employee_appointment (
    employee_id NUMBER,
    appointment_id NUMBER,
    role VARCHAR2(50),
    PRIMARY KEY (employee_id, appointment_id),
    FOREIGN KEY (employee_id) REFERENCES EMPLOYEE(emp_id),
    FOREIGN KEY (appointment_id) REFERENCES APPOINTMENT(app_id)
);


--create service table
CREATE TABLE Service (
    service_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    service_type VARCHAR2(100) ,
    service_date DATE ,
    status VARCHAR2(100),
    cost NUMBER(10,2) 
);

--create invoice table
CREATE TABLE INVOICE (
    invoice_id NUMBER PRIMARY KEY,        
    service_id NUMBER,          
    app_id NUMBER,              
    invoice_date DATE DEFAULT SYSDATE,   
    total_amount NUMBER(10,2),   
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP,
    FOREIGN KEY (service_id) REFERENCES SERVICE(service_id),
    FOREIGN KEY (app_id) REFERENCES APPOINTMENT(app_id)
);

--create payment table
CREATE TABLE PAYMENT (
    payment_id NUMBER PRIMARY KEY,        
    invoice_id NUMBER,           
    payment_date DATE DEFAULT SYSDATE,    
    amount_paid NUMBER(10,2),    
    payment_method VARCHAR2(50),
    FOREIGN KEY (invoice_id) REFERENCES INVOICE(invoice_id)
);


-- Create service table with sequence
CREATE TABLE Service (
    service_id NUMBER PRIMARY KEY,
    service_type VARCHAR2(100),
    service_date DATE,
    status VARCHAR2(100),
    cost NUMBER(10,2)
);

-- Create inventory table with sequence
CREATE TABLE inventory (
    item_id NUMBER PRIMARY KEY,
    item_name VARCHAR2(100),
    quantity NUMBER,
    price_per_unit NUMBER(10, 2)
);

CREATE TABLE service_inventory (
    service_id NUMBER,
    item_id NUMBER,
    quantity_used NUMBER,
    
    -- Composite Primary Key
    CONSTRAINT pk_service_inventory PRIMARY KEY (service_id, item_id),
    
    -- Foreign Key Constraints
    CONSTRAINT fk_service_id FOREIGN KEY (service_id)
        REFERENCES service(service_id),
        
    CONSTRAINT fk_item_id FOREIGN KEY (item_id)
        REFERENCES inventory(item_id)
);



--Updating table

INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Aarav Sharma', '9123456789', 'aarav@example.com', '101 Park Street, Delhi');
INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Priya Gupta', '9234567890', 'priya@example.com', '22 Lajpat Nagar, Delhi');
INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Rohan Patel', '9345678901', 'rohan@example.com', '34 Andheri West, Mumbai');
INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Neha Kapoor', '9456789012', 'neha@example.com', '56 Banjara Hills, Hyderabad');
INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Vikram Singh', '9567890123', 'vikram@example.com', '78 MG Road, Bangalore');
INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Ananya Iyer', '9678901234', 'ananya@example.com', '90 Anna Nagar, Chennai');
INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Karan Malhotra', '9789012345', 'karan@example.com', '12 Salt Lake, Kolkata');
INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Sneha Reddy', '9890123456', 'sneha@example.com', '23 Jubilee Hills, Hyderabad');
INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Arjun Nair', '9901234567', 'arjun@example.com', '45 Koramangala, Bangalore');
INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Pooja Desai', '9012345678', 'pooja@example.com', '67 Vashi, Navi Mumbai');



INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5001, 'DL01X4321', 'Hyundai', 'Creta', 2021);
INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5002, 'DL02Y8765', 'Maruti', 'Baleno', 2020);
INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5003, 'MH03Z1234', 'Tata', 'Nexon', 2022);
INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5004, 'TS04A5678', 'Honda', 'City', 2019);
INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5005, 'KA05B9101', 'Toyota', 'Innova', 2023);
INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5006, 'TN06C2345', 'Kia', 'Seltos', 2021);
INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5007, 'WB07D6789', 'Mahindra', 'XUV500', 2020);
INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5008, 'TS08E0123', 'Skoda', 'Octavia', 2022);
INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5009, 'KA09F4567', 'Renault', 'Duster', 2018);
INSERT INTO VEHICLE (vehicle_id, cust_id, licence_plate, make, model, year) VALUES
(vehicle_seq.NEXTVAL, 5010, 'MH10G8901', 'Ford', 'EcoSport', 2021);



INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Rahul Verma', 'Mechanic', '9123456780', 'rahul@example.com', 52000.00, TO_DATE('2021-02-10', 'YYYY-MM-DD'), 42.5);
INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Meera Joshi', 'Service Advisor', '9234567891', 'meera@example.com', 48000.00, TO_DATE('2020-07-15', 'YYYY-MM-DD'), 39.0);
INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Suresh Kumar', 'Manager', '9345678902', 'suresh@example.com', 65000.00, TO_DATE('2019-04-01', 'YYYY-MM-DD'), 45.0);
INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Lakshmi Nair', 'Mechanic', '9456789013', 'lakshmi@example.com', 51000.00, TO_DATE('2022-01-20', 'YYYY-MM-DD'), 41.25);
INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Amitabh Roy', 'Service Advisor', '9567890124', 'amitabh@example.com', 47000.00, TO_DATE('2021-09-05', 'YYYY-MM-DD'), 38.75);
INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Divya Pillai', 'Receptionist', '9678901235', 'divya@example.com', 40000.00, TO_DATE('2020-11-10', 'YYYY-MM-DD'), 37.5);
INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Nikhil Bose', 'Mechanic', '9789012346', 'nikhil@example.com', 53000.00, TO_DATE('2022-03-15', 'YYYY-MM-DD'), 43.0);
INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Shalini Menon', 'Manager', '9890123457', 'shalini@example.com', 68000.00, TO_DATE('2018-12-01', 'YYYY-MM-DD'), 46.5);
INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Tarun Das', 'Service Advisor', '9901234568', 'tarun@example.com', 46000.00, TO_DATE('2021-06-25', 'YYYY-MM-DD'), 39.5);
INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked) VALUES
(employee_seq.NEXTVAL, 'Kavita Rane', 'Mechanic', '9012345679', 'kavita@example.com', 50000.00, TO_DATE('2022-08-10', 'YYYY-MM-DD'), 40.0);






INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5001, 7001, TO_DATE('2025-04-05', 'YYYY-MM-DD'), TO_TIMESTAMP('10:00:00', 'HH24:MI:SS'), 'Scheduled', 1001, 1);
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5002, 7002, TO_DATE('2025-04-06', 'YYYY-MM-DD'), TO_TIMESTAMP('11:30:00', 'HH24:MI:SS'), 'Completed', 1002, 2);
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5003, 7003, TO_DATE('2025-04-07', 'YYYY-MM-DD'), TO_TIMESTAMP('09:15:00', 'HH24:MI:SS'), 'Pending', 1003, 3);
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5004, 7004, TO_DATE('2025-04-08', 'YYYY-MM-DD'), TO_TIMESTAMP('14:00:00', 'HH24:MI:SS'), 'Scheduled', 1004, 4);
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5005, 7005, TO_DATE('2025-04-09', 'YYYY-MM-DD'), TO_TIMESTAMP('15:45:00', 'HH24:MI:SS'), 'Completed', 1005, 5);
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5006, 7006, TO_DATE('2025-04-10', 'YYYY-MM-DD'), TO_TIMESTAMP('10:30:00', 'HH24:MI:SS'), 'Pending', 1006, 6);
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5007, 7007, TO_DATE('2025-04-11', 'YYYY-MM-DD'), TO_TIMESTAMP('13:00:00', 'HH24:MI:SS'), 'Scheduled', 1007, 7);
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5008, 7008, TO_DATE('2025-04-12', 'YYYY-MM-DD'), TO_TIMESTAMP('16:15:00', 'HH24:MI:SS'), 'Completed', 1008, 8);
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5009, 7009, TO_DATE('2025-04-13', 'YYYY-MM-DD'), TO_TIMESTAMP('09:45:00', 'HH24:MI:SS'), 'Pending', 1009, 9);
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 5010, 7010, TO_DATE('2025-04-14', 'YYYY-MM-DD'), TO_TIMESTAMP('12:30:00', 'HH24:MI:SS'), 'Scheduled', 1010, 10);




INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(1, 9001, 'Mechanic');
INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(2, 9002, 'Service Advisor');
INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(3, 9003, 'Manager');
INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(4, 9004, 'Mechanic');
INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(5, 9005, 'Service Advisor');
INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(6, 9006, 'Receptionist');
INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(7, 9007, 'Mechanic');
INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(8, 9008, 'Manager');
INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(9, 9009, 'Service Advisor');
INSERT INTO EMPLOYEE_APPOINTMENT (employee_id, appointment_id, role) VALUES
(10, 9010, 'Mechanic');









INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'Engine Tune-Up', TO_DATE('2025-04-05', 'YYYY-MM-DD'), 'Completed', 120.00);
INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'Wheel Alignment', TO_DATE('2025-04-06', 'YYYY-MM-DD'), 'Pending', 80.00);
INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'AC Repair', TO_DATE('2025-04-07', 'YYYY-MM-DD'), 'Completed', 250.00);
INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'Battery Replacement', TO_DATE('2025-04-08', 'YYYY-MM-DD'), 'Scheduled', 150.00);
INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'Transmission Check', TO_DATE('2025-04-09', 'YYYY-MM-DD'), 'Completed', 300.00);
INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'Car Wash', TO_DATE('2025-04-10', 'YYYY-MM-DD'), 'Pending', 30.00);
INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'Suspension Repair', TO_DATE('2025-04-11', 'YYYY-MM-DD'), 'Completed', 400.00);
INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'Paint Touch-Up', TO_DATE('2025-04-12', 'YYYY-MM-DD'), 'Scheduled', 100.00);
INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'Exhaust Repair', TO_DATE('2025-04-13', 'YYYY-MM-DD'), 'Completed', 180.00);
INSERT INTO Service (service_id, service_type, service_date, status, cost) VALUES
(service_seq.NEXTVAL, 'Full Service', TO_DATE('2025-04-14', 'YYYY-MM-DD'), 'Pending', 500.00);








INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'Spark Plugs', 200, 10.00);
INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'Alignment Kit', 50, 25.00);
INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'AC Compressor', 30, 150.00);
INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'Car Battery', 80, 120.00);
INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'Transmission Fluid', 100, 20.00);
INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'Cleaning Solution', 150, 5.00);
INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'Shock Absorbers', 40, 200.00);
INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'Paint Can', 60, 30.00);
INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'Exhaust Pipe', 25, 100.00);
INSERT INTO inventory (item_id, item_name, quantity, price_per_unit) VALUES
(inventory_seq.NEXTVAL, 'Oil Filter', 120, 15.00);






INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1001, 9001, TO_DATE('2025-04-05', 'YYYY-MM-DD'), 120.00);
INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1002, 9002, TO_DATE('2025-04-06', 'YYYY-MM-DD'), 80.00);
INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1003, 9003, TO_DATE('2025-04-07', 'YYYY-MM-DD'), 250.00);
INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1004, 9004, TO_DATE('2025-04-08', 'YYYY-MM-DD'), 150.00);
INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1005, 9005, TO_DATE('2025-04-09', 'YYYY-MM-DD'), 300.00);
INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1006, 9006, TO_DATE('2025-04-10', 'YYYY-MM-DD'), 30.00);
INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1007, 9007, TO_DATE('2025-04-11', 'YYYY-MM-DD'), 400.00);
INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1008, 9008, TO_DATE('2025-04-12', 'YYYY-MM-DD'), 100.00);
INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1009, 9009, TO_DATE('2025-04-13', 'YYYY-MM-DD'), 180.00);
INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount) VALUES
(invoice_seq.NEXTVAL, 1010, 9010, TO_DATE('2025-04-14', 'YYYY-MM-DD'), 500.00);



INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3001, TO_DATE('2025-04-05', 'YYYY-MM-DD'), 120.00, 'Credit Card', 'Completed');

INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3002, TO_DATE('2025-04-06', 'YYYY-MM-DD'), 80.00, 'Cash', 'Pending');

INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3003, TO_DATE('2025-04-07', 'YYYY-MM-DD'), 250.00, 'Debit Card', 'Completed');

INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3004, TO_DATE('2025-04-08', 'YYYY-MM-DD'), 150.00, 'UPI', 'Completed');

INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3005, TO_DATE('2025-04-09', 'YYYY-MM-DD'), 300.00, 'Credit Card', 'Pending');

INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3006, TO_DATE('2025-04-10', 'YYYY-MM-DD'), 30.00, 'Cash', 'Completed');

INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3007, TO_DATE('2025-04-11', 'YYYY-MM-DD'), 400.00, 'Debit Card', 'Completed');

INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3008, TO_DATE('2025-04-12', 'YYYY-MM-DD'), 100.00, 'UPI', 'Pending');

INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3009, TO_DATE('2025-04-13', 'YYYY-MM-DD'), 180.00, 'Credit Card', 'Completed');

INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status) VALUES
(payment_seq.NEXTVAL, 3010, TO_DATE('2025-04-14', 'YYYY-MM-DD'), 500.00, 'Cash', 'Completed');


INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1001, 2001, 4);  
INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1002, 2002, 1); 
INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1003, 2003, 1);  
INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1004, 2004, 1);  
INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1005, 2005, 5); 
INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1006, 2006, 2); 
INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1007, 2007, 2);  
INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1008, 2008, 1); 
INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1009, 2009, 1); 
INSERT INTO service_inventory (service_id, item_id, quantity_used) VALUES
(1010, 2010, 2);  