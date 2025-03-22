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
