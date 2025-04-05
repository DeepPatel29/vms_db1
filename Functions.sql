SET SERVEROUTPUT ON;

-- ROLE Table Functions Package
CREATE OR REPLACE PACKAGE role_functions AS
    FUNCTION get_role_name(p_role_id IN NUMBER) RETURN VARCHAR2;
END role_functions;
/

-- Role Table functions package body
CREATE OR REPLACE PACKAGE BODY role_functions AS
    FUNCTION get_role_name(p_role_id IN NUMBER) RETURN VARCHAR2 IS
        v_role_name VARCHAR2(100);
    BEGIN
        -- Retrieve role name for given role_id
        SELECT role_name INTO v_role_name
        FROM ROLE
        WHERE role_id = p_role_id;
        RETURN v_role_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Raise error with a message if role_id doesn't exist
            RAISE_APPLICATION_ERROR(-20010, 'No role found for role_id: ' || p_role_id);
        WHEN OTHERS THEN
            -- Handle any other unexpected errors
            RAISE_APPLICATION_ERROR(-20011, 'Error retrieving role name: ' || SQLERRM);
    END get_role_name;
END role_functions;
/


--Execution of role_funcitons:

-- Getting the role_name of role ID 1 (it exists)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Role Name for ID 1: ' || role_functions.get_role_name(1));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Getting role_name of role ID 99 (it doesn’t exist)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Role Name for ID 99: ' || role_functions.get_role_name(99));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/


-- USER_TABLE Functions Package
CREATE OR REPLACE PACKAGE user_functions AS
    FUNCTION get_user_role(p_user_id IN NUMBER) RETURN VARCHAR2;
END user_functions;
/

-- USER_TABLE Functions Pacakage Body
CREATE OR REPLACE PACKAGE BODY user_functions AS
    FUNCTION get_user_role(p_user_id IN NUMBER) RETURN VARCHAR2 IS
        v_role_name VARCHAR2(100);
    BEGIN
        -- Join USER_TABLE and ROLE to get role name for user
        SELECT r.role_name INTO v_role_name
        FROM USER_TABLE u
        JOIN ROLE r ON u.role_id = r.role_id
        WHERE u.user_id = p_user_id;
        RETURN v_role_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Raise error with custom message if user_id doesn't exist or no role linked
            RAISE_APPLICATION_ERROR(-20012, 'No user or role found for user_id: ' || p_user_id);
        WHEN OTHERS THEN
            -- Handle any other unexpected errors
            RAISE_APPLICATION_ERROR(-20013, 'Error retrieving user role: ' || SQLERRM);
    END get_user_role;
END user_functions;
/


--Execution of User_functions
-- Using get_user_role function to find role_name for user ID 1 (it exists)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Role for User ID 1: ' || user_functions.get_user_role(1));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Getting role_name for user ID 99 (it doesn’t exist)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Role for User ID 99: ' || user_functions.get_user_role(99));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- AUDIT_LOG Functions Package
CREATE OR REPLACE PACKAGE audit_functions AS
    FUNCTION get_latest_audit_time(p_tablename IN VARCHAR2) RETURN TIMESTAMP;
END audit_functions;
/

-- AUDIT_LOG Functions Package Body
CREATE OR REPLACE PACKAGE BODY audit_functions AS
    FUNCTION get_latest_audit_time(p_tablename IN VARCHAR2) RETURN TIMESTAMP IS
        v_timestamp TIMESTAMP;
        v_count NUMBER;
    BEGIN
        -- First check if any rows exist for the table
        SELECT COUNT(*) INTO v_count
        FROM AUDIT_LOG
        WHERE tablename = p_tablename;
        
        -- If no rows exist, raise an error
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20014, 'No audit logs found for table: ' || p_tablename);
        END IF;
        
        -- Get the most recent audit timestamp for specified table
        SELECT MAX(Updated_at) INTO v_timestamp
        FROM AUDIT_LOG
        WHERE tablename = p_tablename;
        
        RETURN v_timestamp;
    EXCEPTION
        WHEN OTHERS THEN
            -- Handle any unexpected errors
            RAISE_APPLICATION_ERROR(-20015, 'Error retrieving latest audit time: ' || SQLERRM);
    END get_latest_audit_time;
END audit_functions;
/

-- Executing AUDIT_LOG Function 

-- Getting latest update time for USER_TABLE (it has a record) using get_latest_audit_time function
BEGIN
    DBMS_OUTPUT.PUT_LINE('Latest Audit Time for USER_TABLE: ' || 
                         TO_CHAR(audit_functions.get_latest_audit_time('USER_TABLE'), 
                                 'YYYY-MM-DD HH24:MI:SS'));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Getting latest update time for ROLE (it has a record)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Latest Audit Time for ROLE: ' || 
                         TO_CHAR(audit_functions.get_latest_audit_time('ROLE'), 
                                 'YYYY-MM-DD HH24:MI:SS'));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Getting latest update time for a table that has no audit_logs
BEGIN
    DBMS_OUTPUT.PUT_LINE('Latest Audit Time for INVALID_TABLE: ' || 
                         TO_CHAR(audit_functions.get_latest_audit_time('Customer'), 
                                 'YYYY-MM-DD HH24:MI:SS'));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/


---------------------
---------------------
-- Customer Functions Package
CREATE OR REPLACE PACKAGE customer_functions AS
    FUNCTION get_customer_count RETURN NUMBER;
    FUNCTION validate_customer_email(p_email IN VARCHAR2) RETURN BOOLEAN;
END customer_functions;
/

CREATE OR REPLACE PACKAGE BODY customer_functions AS
    FUNCTION get_customer_count RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM CUSTOMER;
        RETURN v_count;
    END get_customer_count;

    FUNCTION validate_customer_email(p_email IN VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM CUSTOMER WHERE email = p_email;
        RETURN v_count = 0; -- TRUE if email is unique
    END validate_customer_email;
END customer_functions;
/

-- Vehicle Functions Package
CREATE OR REPLACE PACKAGE vehicle_functions AS
    FUNCTION get_vehicle_count(p_cust_id IN NUMBER) RETURN NUMBER;
    FUNCTION get_vehicle_age(p_year IN NUMBER) RETURN NUMBER;
END vehicle_functions;
/

CREATE OR REPLACE PACKAGE BODY vehicle_functions AS
    FUNCTION get_vehicle_count(p_cust_id IN NUMBER) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM VEHICLE WHERE cust_id = p_cust_id;
        RETURN v_count;
    END get_vehicle_count;

    FUNCTION get_vehicle_age(p_year IN NUMBER) RETURN NUMBER IS
        v_age NUMBER;
    BEGIN
        v_age := EXTRACT(YEAR FROM SYSDATE) - p_year;
        RETURN v_age;
    END get_vehicle_age;
END vehicle_functions;
/

-- Appointment Functions Package
CREATE OR REPLACE PACKAGE appointment_functions AS
    FUNCTION get_appointment_count(p_cust_id IN NUMBER) RETURN NUMBER;
    FUNCTION is_appointment_valid(p_app_date IN DATE) RETURN BOOLEAN;
END appointment_functions;
/

CREATE OR REPLACE PACKAGE BODY appointment_functions AS
    FUNCTION get_appointment_count(p_cust_id IN NUMBER) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM APPOINTMENT WHERE cust_id = p_cust_id;
        RETURN v_count;
    END get_appointment_count;

    FUNCTION is_appointment_valid(p_app_date IN DATE) RETURN BOOLEAN IS
    BEGIN
        RETURN p_app_date >= SYSDATE; -- TRUE if appointment date is valid
    END is_appointment_valid;
END appointment_functions;
/

-- Employee Functions Package
CREATE OR REPLACE PACKAGE employee_functions AS
    FUNCTION get_employee_salary(p_emp_id IN NUMBER) RETURN NUMBER;
    FUNCTION get_total_hours_worked(p_emp_id IN NUMBER) RETURN NUMBER;
END employee_functions;
/

CREATE OR REPLACE PACKAGE BODY employee_functions AS
    FUNCTION get_employee_salary(p_emp_id IN NUMBER) RETURN NUMBER IS
        v_salary NUMBER;
    BEGIN
        SELECT salary INTO v_salary FROM EMPLOYEE WHERE emp_id = p_emp_id;
        RETURN v_salary;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20023, 'No employee found for emp_id: ' || p_emp_id);
    END get_employee_salary;

    FUNCTION get_total_hours_worked(p_emp_id IN NUMBER) RETURN NUMBER IS
        v_hours_worked NUMBER;
    BEGIN
        SELECT hours_worked INTO v_hours_worked FROM EMPLOYEE WHERE emp_id = p_emp_id;
        RETURN v_hours_worked;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20024, 'No employee found for emp_id: ' || p_emp_id);
    END get_total_hours_worked;
END employee_functions;
/

-- Execution Blocks

-- Execute get_customer_count
SET SERVEROUTPUT ON;
DECLARE
    v_customer_count NUMBER;
BEGIN
    v_customer_count := customer_functions.get_customer_count;
    DBMS_OUTPUT.PUT_LINE('Total number of customers: ' || v_customer_count);
END;
/

-- Execute validate_customer_email
SET SERVEROUTPUT ON;
DECLARE
    v_is_unique BOOLEAN;
BEGIN
    v_is_unique := customer_functions.validate_customer_email('john@example.com'); -- Replace with the desired email
    IF v_is_unique THEN
        DBMS_OUTPUT.PUT_LINE('The email is unique.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('The email is not unique.');
    END IF;
END;
/

-- Execute get_vehicle_count
SET SERVEROUTPUT ON;
DECLARE
    v_vehicle_count NUMBER;
BEGIN
    v_vehicle_count := vehicle_functions.get_vehicle_count(1); -- Replace 1 with the desired customer ID
    DBMS_OUTPUT.PUT_LINE('Number of vehicles: ' || v_vehicle_count);
END;
/

-- Execute get_vehicle_age
SET SERVEROUTPUT ON;
DECLARE
    v_vehicle_age NUMBER;
BEGIN
    v_vehicle_age := vehicle_functions.get_vehicle_age(2020); -- Replace 2020 with the desired year
    DBMS_OUTPUT.PUT_LINE('Age of the vehicle: ' || v_vehicle_age || ' years');
END;
/

-- Execute get_appointment_count
SET SERVEROUTPUT ON;
DECLARE
    v_appointment_count NUMBER;
BEGIN
    v_appointment_count := appointment_functions.get_appointment_count(1); -- Replace 1 with the desired customer ID
    DBMS_OUTPUT.PUT_LINE('Number of appointments for customer: ' || v_appointment_count);
END;
/

-- Execute is_appointment_valid
SET SERVEROUTPUT ON;
DECLARE
    v_is_valid BOOLEAN;
BEGIN
    v_is_valid := appointment_functions.is_appointment_valid(TO_DATE('2023-10-15', 'YYYY-MM-DD')); -- Replace with the desired date
    IF v_is_valid THEN
        DBMS_OUTPUT.PUT_LINE('The appointment date is valid.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('The appointment date is not valid.');
    END IF;
END;
/

-- Execute get_employee_salary
SET SERVEROUTPUT ON;
DECLARE
    v_salary NUMBER;
BEGIN
    v_salary := employee_functions.get_employee_salary(1); -- Replace 1 with the desired employee ID
    DBMS_OUTPUT.PUT_LINE('Employee salary: ' || v_salary);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/

-- Execute get_total_hours_worked
SET SERVEROUTPUT ON;
DECLARE
    v_hours_worked NUMBER;
BEGIN
    v_hours_worked := employee_functions.get_total_hours_worked(1); -- Replace 1 with the desired employee ID
    DBMS_OUTPUT.PUT_LINE('Total hours worked by employee: ' || v_hours_worked);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(SQLERRM);
END;
/




---
-------
--FUNCTIONS :
---------------
--package for functions of service table
CREATE OR REPLACE PACKAGE service_function_pkg AS
    FUNCTION get_service_cost(p_service_id IN NUMBER) RETURN NUMBER;
    FUNCTION is_service_completed(p_service_id IN NUMBER) RETURN BOOLEAN;
END service_function_pkg;
/
CREATE OR REPLACE PACKAGE BODY service_function_pkg AS
    FUNCTION get_service_cost(p_service_id IN NUMBER)
    RETURN NUMBER IS
        v_cost NUMBER(10,2);
    BEGIN
        SELECT cost INTO v_cost
        FROM Service
        WHERE service_id = p_service_id;
        
        RETURN v_cost;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Error in get_service_cost: ' || SQLERRM);
    END get_service_cost;

    FUNCTION is_service_completed(p_service_id IN NUMBER)
    RETURN BOOLEAN IS
        v_status VARCHAR2(100);
    BEGIN
        SELECT status INTO v_status
        FROM Service
        WHERE service_id = p_service_id;
        
        RETURN UPPER(v_status) = 'COMPLETED';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error in is_service_completed: ' || SQLERRM);
    END is_service_completed;

END service_function_pkg;
/



--2 package for functions of inventory table
CREATE OR REPLACE PACKAGE inventory_function_pkg AS
    FUNCTION check_low_stock(p_item_id IN NUMBER) RETURN BOOLEAN;
    FUNCTION get_inventory_value(p_item_id IN NUMBER) RETURN NUMBER;
END inventory_function_pkg;
/

CREATE OR REPLACE PACKAGE BODY inventory_function_pkg AS
    FUNCTION check_low_stock(p_item_id IN NUMBER)
    RETURN BOOLEAN IS
        v_quantity NUMBER;
    BEGIN
        SELECT quantity INTO v_quantity
        FROM inventory
        WHERE item_id = p_item_id;
        
        RETURN v_quantity < 10;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'Error in check_low_stock: ' || SQLERRM);
    END check_low_stock;

    FUNCTION get_inventory_value(p_item_id IN NUMBER)
    RETURN NUMBER IS
        v_value NUMBER(10,2);
    BEGIN
        SELECT quantity * price_per_unit INTO v_value
        FROM inventory
        WHERE item_id = p_item_id;
        
        RETURN v_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20004, 'Error in get_inventory_value: ' || SQLERRM);
    END get_inventory_value;

END inventory_function_pkg;
/
--
--test check low function
DECLARE
    v_is_low_stock BOOLEAN;
BEGIN
    -- Test the function for a specific item ID 
    v_is_low_stock := inventory_function_pkg.check_low_stock(2041);

    -- Convert BOOLEAN to 'TRUE' or 'FALSE' for displaying
    IF v_is_low_stock THEN
        DBMS_OUTPUT.PUT_LINE('Is the stock low? TRUE');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Is the stock low? FALSE');
    END IF;
END;
/
--
-- Test for get_inventory_value function
DECLARE
    v_inventory_value NUMBER;
BEGIN
    -- Test the function for a specific item ID 
    v_inventory_value := inventory_function_pkg.get_inventory_value(2041);
    DBMS_OUTPUT.PUT_LINE('Inventory value: ' || v_inventory_value);
END;
/

--3 package for functions of servive_inventory table
CREATE OR REPLACE PACKAGE service_inventory_function_pkg AS
    FUNCTION get_usage_cost(p_service_id IN NUMBER) RETURN NUMBER;
END service_inventory_function_pkg;
/

CREATE OR REPLACE PACKAGE BODY service_inventory_function_pkg AS
    FUNCTION get_usage_cost(p_service_id IN NUMBER)
    RETURN NUMBER IS
        v_total_cost NUMBER(10,2);
    BEGIN
        SELECT SUM(i.price_per_unit * si.quantity_used)
        INTO v_total_cost
        FROM service_inventory si
        JOIN inventory i ON si.item_id = i.item_id
        WHERE si.service_id = p_service_id;
        
        RETURN NVL(v_total_cost, 0);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'Error in get_usage_cost: ' || SQLERRM);
    END get_usage_cost;

END service_inventory_function_pkg;
/


--INVOICE FUNCTIONS
--1 a.package specification
CREATE OR REPLACE PACKAGE invoice_functions_pkg AS
    -- Function to get the total amount of an invoice
    FUNCTION get_invoice_total(p_invoice_id IN NUMBER) RETURN NUMBER;
    
END invoice_functions_pkg;
/
--b.pavkage body
CREATE OR REPLACE PACKAGE BODY invoice_functions_pkg AS

    -- Function to get the total amount of an invoice
    FUNCTION get_invoice_total(p_invoice_id IN NUMBER) RETURN NUMBER 
    IS
        v_total_amount NUMBER;
    BEGIN
        SELECT total_amount 
        INTO v_total_amount 
        FROM INVOICE 
        WHERE invoice_id = p_invoice_id;

        RETURN v_total_amount;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL; -- If the invoice ID is not found
        WHEN OTHERS THEN
            RETURN NULL; -- Handles unexpected errors
    END get_invoice_total;

   
END invoice_functions_pkg;
/

set serveroutput on;
--execution
DECLARE
    v_total NUMBER;
BEGIN
    v_total := invoice_functions_pkg.get_invoice_total(1);
    DBMS_OUTPUT.PUT_LINE('Total Invoice Amount: ' || v_total);
END;
/


select * from payment

--2  PAYMENT FUNCTIONS
--a. package specification
CREATE OR REPLACE PACKAGE payment_functions_pkg AS
    -- Function to calculate remaining balance for an invoice
    FUNCTION get_payment_balance(p_invoice_id IN NUMBER) RETURN NUMBER;
END payment_functions_pkg;
/
--b package body
CREATE OR REPLACE PACKAGE BODY payment_functions_pkg AS

    FUNCTION get_payment_balance(p_invoice_id IN NUMBER) RETURN NUMBER 
    IS
        v_total_amount NUMBER := 0;
        v_total_paid NUMBER := 0;
        v_balance NUMBER;
    BEGIN
        -- Get total amount from INVOICE table
        SELECT total_amount 
        INTO v_total_amount 
        FROM INVOICE 
        WHERE invoice_id = p_invoice_id;
        
        -- Get total amount paid from PAYMENT table (if no payments, return 0)
        SELECT NVL(SUM(amount_paid), 0) 
        INTO v_total_paid 
        FROM PAYMENT 
        WHERE invoice_id = p_invoice_id;

        -- Calculate remaining balance
        v_balance := v_total_amount - v_total_paid;
        
        RETURN v_balance;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL; -- If invoice ID is not found
        WHEN OTHERS THEN
            RETURN NULL; -- Handles unexpected errors
    END get_payment_balance;

END payment_functions_pkg;
/
--execution of get_payment_balance function
SET SERVEROUTPUT ON;
DECLARE
    v_balance NUMBER;
BEGIN
    v_balance := payment_functions_pkg.get_payment_balance(1);
    DBMS_OUTPUT.PUT_LINE('Remaining Balance: ' || v_balance);
END;
/

