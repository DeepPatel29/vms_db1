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


---
-------
-- SERVICE Table Function for get service cost by service_id
SET SERVEROUTPUT ON;
CREATE OR REPLACE FUNCTION get_service_cost(p_service_id IN NUMBER)
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
/

-- Execution for get_service_cost
BEGIN
    DBMS_OUTPUT.PUT_LINE('Service Cost (service_id 1): ' || 
        NVL(TO_CHAR(get_service_cost(1), '999.99'), 'Not Found'));
END;
/

-- Function to check if service is completed or not
CREATE OR REPLACE FUNCTION is_service_completed(p_service_id IN NUMBER)
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
/

-- Execution for is_service_completed
BEGIN
    DBMS_OUTPUT.PUT_LINE('Is Service Completed (service_id 1): ' || 
        CASE WHEN is_service_completed(1) THEN 'TRUE' ELSE 'FALSE' END);
    DBMS_OUTPUT.PUT_LINE('Is Service Completed (service_id 2): ' || 
        CASE WHEN is_service_completed(2) THEN 'TRUE' ELSE 'FALSE' END);
END;
/


-- Function on INVENTORY table to check if item stock is low (< 10)
CREATE OR REPLACE FUNCTION check_low_stock(p_item_id IN NUMBER)
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
/

-- Execution for check_low_stock
BEGIN
    DBMS_OUTPUT.PUT_LINE('Is Low Stock (item_id 1): ' || 
        CASE WHEN check_low_stock(1) THEN 'TRUE' ELSE 'FALSE' END);
END;
/

-- Function to get total value of an inventory item
CREATE OR REPLACE FUNCTION get_inventory_value(p_item_id IN NUMBER)
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
/

-- Execution for get_inventory_value
BEGIN
    DBMS_OUTPUT.PUT_LINE('Inventory Value (item_id 1): ' || 
        NVL(TO_CHAR(get_inventory_value(1), '9999.99'), 'Not Found'));
    DBMS_OUTPUT.PUT_LINE('Inventory Value (item_id 2): ' || 
        NVL(TO_CHAR(get_inventory_value(2), '9999.99'), 'Not Found'));
END;
/

-- Function to get total cost of inventory
CREATE OR REPLACE FUNCTION get_usage_cost(p_service_id IN NUMBER)
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
/

-- Execution for get_usage_cost
BEGIN
    DBMS_OUTPUT.PUT_LINE('Usage Cost (service_id 1): ' || 
        NVL(TO_CHAR(get_usage_cost(1), '999.99'), 'Not Found'));
    DBMS_OUTPUT.PUT_LINE('Usage Cost (service_id 2): ' || 
        NVL(TO_CHAR(get_usage_cost(2), '999.99'), 'Not Found'));
END;
/

