SET SERVEROUTPUT ON;

--============================= USE CASE 1 ==================================
--Use Case 1: User Authentication
DECLARE
    v_input_email VARCHAR2(100);    -- Input email
    v_input_password VARCHAR2(100); -- Input password
    v_user_id NUMBER;
    v_role_id NUMBER;
    v_username VARCHAR2(100); 
    v_email VARCHAR2(100);
    v_stored_password VARCHAR2(100);
    v_role_name VARCHAR2(100);
    v_cursor SYS_REFCURSOR;
    v_found BOOLEAN := FALSE;

BEGIN
    -- Prompt for user input 
    v_input_email := TRIM('&Enter_Email');       -- Trim whitespace from input email
    v_input_password := '&Enter_Password';       -- Password input 

    -- Fetch all users to find the matching email
    BEGIN
        user_procedures.get_user(NULL, v_cursor); -- Fetch all users
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error fetching users: ' || SQLERRM);
            RETURN;
    END;

    -- Loop through users to find a match for the email
    LOOP
        FETCH v_cursor INTO v_user_id, v_role_id, v_username, v_email, v_stored_password;
        EXIT WHEN v_cursor%NOTFOUND;

        IF UPPER(TRIM(v_input_email)) = UPPER(TRIM(v_email)) THEN -- Case-insensitive and trimmed comparison
            v_found := TRUE;
            EXIT; -- Exit loop once user is found
        END IF;
    END LOOP;
    CLOSE v_cursor;

    -- Validate user existence
    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid email. User with email "' || v_input_email || '" does not exist.');
        RETURN; -- Exit the block if user not found
    END IF;

    -- Verify password
    IF v_stored_password != v_input_password THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid password for user with email "' || v_input_email || '".');
        RETURN; -- Exit the block if password doesn't match
    END IF;

    -- Get the role name using the role_id from USER_TABLE and ROLE table
    BEGIN
        v_role_name := role_functions.get_role_name(v_role_id); -- Fetch role name using role_id
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error retrieving role for email "' || v_input_email || '": ' || SQLERRM);
            RETURN;
    END;

    -- Authenticate and display role-specific message
    DBMS_OUTPUT.PUT_LINE('Authentication successful! Welcome, ' || v_username || '.');
    IF UPPER(v_role_name) = 'ADMIN' THEN
        DBMS_OUTPUT.PUT_LINE('You are logged in as an Admin.');
    ELSIF UPPER(v_role_name) = 'SALES REPRESENTATIVE' THEN
        DBMS_OUTPUT.PUT_LINE('You are logged in as a Sales Representative.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('You are logged in with role: ' || v_role_name || '.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during authentication: ' || SQLERRM);
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/


--============================= USE CASE 2 ==================================

--Updating status and generating invoice
--Failure case
DECLARE
  v_service_id NUMBER;
  v_invoice_id NUMBER;
BEGIN
  -- Step 1: Update service status to 'Completed' using procedure
  service_pkg.update_service(
    p_service_id => 1006, -- initially 'Pending'
    p_status => 'Completed',
    p_cost => 30.00,
    p_service_id_out => v_service_id
  );
  DBMS_OUTPUT.PUT_LINE('Service updated: ' || v_service_id);

  -- Step 2: Check if invoice was auto-generated by trigger using invoice_seq
  -- The trigger should have inserted a new invoice with a unique ID
  FOR rec IN (SELECT invoice_id, total_amount 
              FROM INVOICE 
              WHERE service_id = 1006 
              AND app_id = 9006 
              AND invoice_id > 3010) 
  LOOP
    v_invoice_id := rec.invoice_id;
    DBMS_OUTPUT.PUT_LINE('Auto-Generated Invoice ID: ' || rec.invoice_id || ', Total Amount: ' || rec.total_amount);
  END LOOP;

  -- Step 3: If no invoice was found (e.g., due to data mismatch), manually generate using procedure
  IF v_invoice_id IS NULL THEN
    invoice_pkg.generate_invoice(
      p_service_id => 1006,
      p_app_id => 9006,
      p_total_amount => 30.00,
      p_invoice_id => v_invoice_id
    );
    DBMS_OUTPUT.PUT_LINE('Manually Generated Invoice ID: ' || v_invoice_id);
  END IF;
END;
/


--Successful case
DECLARE
  v_service_id NUMBER;
  v_invoice_id NUMBER;
BEGIN
  -- Step 1: Update service status to 'Completed' using procedure
  service_pkg.update_service(
    p_service_id => 1011, -- initially 'Pending'
    p_status => 'Completed',
    p_cost => 30.00,
    p_service_id_out => v_service_id
  );
  DBMS_OUTPUT.PUT_LINE('Service updated: ' || v_service_id);

  -- Step 2: Check if invoice was auto-generated by trigger using invoice_seq
  -- The trigger should have inserted a new invoice with a unique ID
  FOR rec IN (SELECT invoice_id, total_amount 
              FROM INVOICE 
              WHERE service_id = 1011 
              AND app_id = 9044
              AND invoice_id > 3010) 
  LOOP
    v_invoice_id := rec.invoice_id;
    DBMS_OUTPUT.PUT_LINE('Auto-Generated Invoice ID: ' || rec.invoice_id || ', Total Amount: ' || rec.total_amount);
  END LOOP;

  -- Step 3: If no invoice was found (e.g., due to data mismatch), manually generate using procedure
  IF v_invoice_id IS NULL THEN
    invoice_pkg.generate_invoice(
      p_service_id => 1011,
      p_app_id => 9044,
      p_total_amount => 30.00,
      p_invoice_id => v_invoice_id
    );
    DBMS_OUTPUT.PUT_LINE('Manually Generated Invoice ID: ' || v_invoice_id);
  END IF;
END;
/

--============================= USE CASE 3 ==================================
--Use case for Admin

DECLARE
    v_role_name VARCHAR2(100);
    v_total_value NUMBER;
BEGIN
    -- Call the authentication procedure with user input
    authenticate_user(
        p_email => TRIM('&Enter_Email'),
        p_password => '&Enter_Password',
        p_role_name => v_role_name
    );

    -- Proceed based on role (if authentication succeeds, execution continues)
    IF UPPER(v_role_name) = 'ADMIN' THEN

        -- Admin Task 1: Update inventory quantity
        BEGIN
            inventory_pkg.update_inventory(
                p_item_id => 2001, -- Spark Plugs
                p_quantity => 150, -- Update from 150 to 200
                p_price_per_unit => 10.00
            );
            DBMS_OUTPUT.PUT_LINE('Inventory for item 2001 updated to 200 units.');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error updating inventory: ' || SQLERRM);
        END;

        -- Admin Task 2: Get total inventory value
        BEGIN
            v_total_value := inventory_function_pkg.get_inventory_value(2001);
            DBMS_OUTPUT.PUT_LINE('Total value of Spark Plugs: $' || v_total_value);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error retrieving inventory value: ' || SQLERRM);
        END;

    ELSE
        DBMS_OUTPUT.PUT_LINE('Access denied. Admin privileges required.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/


--============================= USE CASE 4 ==================================
--Use case for Sales Representative
DECLARE
    v_role_name VARCHAR2(100);
    v_app_id NUMBER;
    v_invoice_total NUMBER;
    v_is_valid BOOLEAN;
BEGIN
    -- Call the authentication procedure with user input
    authenticate_user(
        p_email => TRIM('&Enter_Email'),
        p_password => '&Enter_Password',
        p_role_name => v_role_name
    );

    -- Proceed based on role (if authentication succeeds, execution continues)
    IF UPPER(v_role_name) = 'SALES REPRESENTATIVE' THEN

        -- Sales Rep Task 1: Validate a future appointment date
        BEGIN
            v_is_valid := appointment_functions.is_appointment_valid(TO_DATE('2025-04-20', 'YYYY-MM-DD'));
            IF v_is_valid THEN
                DBMS_OUTPUT.PUT_LINE('Date 2025-04-20 is valid for scheduling.');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Date 2025-04-20 is not valid for scheduling.');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error validating appointment date: ' || SQLERRM);
        END;

        -- Sales Rep Task 2: Check invoice total
        BEGIN
            v_invoice_total := invoice_functions_pkg.get_invoice_total(3001);
            IF v_invoice_total IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('Total for Invoice 3001: $' || v_invoice_total);
            ELSE
                DBMS_OUTPUT.PUT_LINE('Failed to retrieve total for Invoice 3001.');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error retrieving invoice total: ' || SQLERRM);
        END;

    ELSE
        DBMS_OUTPUT.PUT_LINE('Access denied. Sales Representative privileges required.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/


--============================= USE CASE 5 ==================================
--Update Inventory and Check Low Stock
SET SERVEROUTPUT ON;

DECLARE
  v_item_id NUMBER := 2001; -- Spark Plugs
  v_is_low BOOLEAN;
  CURSOR audit_cursor IS 
    SELECT audit_id, oldValue, newValue 
    FROM AUDIT_LOG 
    WHERE tablename = 'INVENTORY' AND action = 'UPDATE';
  v_audit_id NUMBER;
  v_old_value VARCHAR2(100);
  v_new_value VARCHAR2(100);
BEGIN
  -- Step 1: Update inventory quantity
  inventory_pkg.update_inventory(v_item_id, 5, 10.00); -- Reduce to 5 units
  DBMS_OUTPUT.PUT_LINE('Inventory Updated for Item ID: ' || v_item_id);

  -- Step 2: Check if stock is low
  v_is_low := inventory_function_pkg.check_low_stock(v_item_id);
  IF v_is_low THEN
    DBMS_OUTPUT.PUT_LINE('Item ID ' || v_item_id || ' is Low on Stock.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Item ID ' || v_item_id || ' has Sufficient Stock.');
  END IF;

  -- Step 3: Verify audit log
  OPEN audit_cursor;
  FETCH audit_cursor INTO v_audit_id, v_old_value, v_new_value;
  IF audit_cursor%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Audit Log - ID: ' || v_audit_id || 
                         ', Old Quantity: ' || v_old_value || 
                         ', New Quantity: ' || v_new_value);
  ELSE
    DBMS_OUTPUT.PUT_LINE('No Audit Log Found for Inventory Update.');
  END IF;
  CLOSE audit_cursor;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error in Use Case : ' || SQLERRM);
    ROLLBACK;
END;
/


--============================= USE CASE 6 ==================================
SET SERVEROUTPUT ON;

-- 1: Full Customer Journey with Exception Handling

DECLARE
    v_cust_id NUMBER;
    v_vehicle_id NUMBER;
    v_app_id NUMBER;
    v_invoice_id NUMBER;
    v_payment_id NUMBER;
    v_role_id NUMBER;
    v_user_id NUMBER;
    v_service_id NUMBER := 1001;
    v_inventory_value NUMBER;
    v_balance NUMBER;
    
    -- Cursor for appointment details
    CURSOR c_app_details IS
        SELECT app_id, app_date, status 
        FROM appointment 
        WHERE cust_id = v_cust_id;
    r_app c_app_details%ROWTYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('----- Starting Test Case: Full Customer Journey -----');

    -- 2. Create user with new role
    user_procedures.add_user(v_role_id, 'NewUser', 'newuser@example.com', 'securepass', v_user_id);
    DBMS_OUTPUT.PUT_LINE('Created user ID: ' || v_user_id);

    -- 3. Add customer using procedure
    customer_procedures.add_customer('Mukesh Doe', '9876543210', 'john.doe@example.com', '123 Main St', v_cust_id);
    DBMS_OUTPUT.PUT_LINE('Created customer ID: ' || v_cust_id);

    -- 4. Add vehicle using procedure
    vehicle_procedures.add_vehicle(v_cust_id, 'MH01AB1234', 'Toyota', 'Fortuner', 2020, v_vehicle_id);
    DBMS_OUTPUT.PUT_LINE('Added vehicle ID: ' || v_vehicle_id);

    -- 5. Schedule appointment using procedure
    appointment_procedures.schedule_appointment(
        v_cust_id, 
        v_vehicle_id, 
        SYSDATE + 7, 
        SYSTIMESTAMP + INTERVAL '2' HOUR, 
        'Scheduled', 
        v_service_id, 
        1,  -- emp_id
        v_app_id
    );
    DBMS_OUTPUT.PUT_LINE('Scheduled appointment ID: ' || v_app_id);

    -- 6. Complete service and generate invoice (trigger will fire)
    UPDATE service SET status = 'COMPLETED' WHERE service_id = v_service_id;
    DBMS_OUTPUT.PUT_LINE('Marked service as completed');

    -- 7. Get generated invoice using cursor
    DECLARE
        CURSOR c_invoice IS
            SELECT invoice_id, total_amount 
            FROM invoice 
            WHERE service_id = v_service_id;
    BEGIN
        OPEN c_invoice;
        FETCH c_invoice INTO v_invoice_id, v_balance;
        IF c_invoice%FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Generated invoice ID: ' || v_invoice_id || ' Amount: ' || v_balance);
        END IF;
        CLOSE c_invoice;
    END;

    -- 8. Make partial payment
    payment_pkg.record_payment(v_invoice_id, v_balance/2, 'Credit Card', 'Partial', v_payment_id);
    DBMS_OUTPUT.PUT_LINE('Made partial payment ID: ' || v_payment_id);

    -- 9. Check payment balance using function
    v_balance := payment_functions_pkg.get_payment_balance(v_invoice_id);
    DBMS_OUTPUT.PUT_LINE('Remaining balance: ' || v_balance);

    -- 10. Check inventory usage using function
    v_inventory_value := inventory_function_pkg.get_inventory_value(2001);
    DBMS_OUTPUT.PUT_LINE('Inventory value for item 2001: ' || v_inventory_value);

    -- 11. View appointments using cursor
    DBMS_OUTPUT.PUT_LINE('Appointment details:');
    OPEN c_app_details;
    LOOP
        FETCH c_app_details INTO r_app;
        EXIT WHEN c_app_details%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('App ID: ' || r_app.app_id || ' | Date: ' || r_app.app_date || ' | Status: ' || r_app.status);
    END LOOP;
    CLOSE c_app_details;

    -- Test exception handling
    BEGIN
        -- Try to create duplicate user
        user_procedures.add_user(1, 'Sarita', 'Sarita@example.com', 'pass123', v_user_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate user error handled: ' || SQLERRM);
    END;
END;
/
