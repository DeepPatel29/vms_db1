SET SERVEROUTPUT ON;


--Authenticate user Procedure
CREATE OR REPLACE PROCEDURE authenticate_user(
    p_email IN VARCHAR2,
    p_password IN VARCHAR2,
    p_role_name OUT VARCHAR2
) AS
    v_user_id NUMBER;
    v_role_id NUMBER;
    v_username VARCHAR2(100);
    v_email VARCHAR2(100);
    v_stored_password VARCHAR2(100);
    v_cursor SYS_REFCURSOR;
    v_found BOOLEAN := FALSE;
BEGIN
    -- Fetch all users to find the matching email
    BEGIN
        user_procedures.get_user(NULL, v_cursor);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error fetching users: ' || SQLERRM);
            RETURN;
    END;

    -- Loop through users to find a match
    LOOP
        FETCH v_cursor INTO v_user_id, v_role_id, v_username, v_email, v_stored_password;
        EXIT WHEN v_cursor%NOTFOUND;

        IF UPPER(TRIM(p_email)) = UPPER(TRIM(v_email)) THEN
            v_found := TRUE;
            EXIT;
        END IF;
    END LOOP;
    CLOSE v_cursor;

    -- Validate user existence
    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid email. User with email "' || p_email || '" does not exist.');
        RETURN;
    END IF;

    -- Verify password
    IF v_stored_password != p_password THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid password for user with email "' || p_email || '".');
        RETURN;
    END IF;

    -- Get the role name and assign it to the OUT parameter
    BEGIN
        p_role_name := role_functions.get_role_name(v_role_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error retrieving role for email "' || p_email || '": ' || SQLERRM);
            RETURN;
    END;

    -- Display authentication result
    DBMS_OUTPUT.PUT_LINE('Authentication successful! Welcome, ' || v_username || '.');
    IF UPPER(p_role_name) = 'ADMIN' THEN
        DBMS_OUTPUT.PUT_LINE('You are logged in as an Admin.');
    ELSIF UPPER(p_role_name) = 'SALES REPRESENTATIVE' THEN
        DBMS_OUTPUT.PUT_LINE('You are logged in as a Sales Representative.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('You are logged in with role: ' || p_role_name || '.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during authentication: ' || SQLERRM);
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END authenticate_user;
/

--Testing user authenticate procedure
-- Anonymous block to call the procedure with user input
DECLARE
    v_role_name VARCHAR2(100);
BEGIN
    authenticate_user(
        p_email => TRIM('&Enter_Email'),
        p_password => '&Enter_Password',
        p_role_name => v_role_name
    );
    DBMS_OUTPUT.PUT_LINE('Returned role: ' || v_role_name);
END;
/
--=======================================================================================================
-- ROLE Table Procedures Package

CREATE OR REPLACE PACKAGE role_procedures AS
    PROCEDURE add_role(p_role_name IN VARCHAR2, p_role_id OUT NUMBER);
    PROCEDURE get_role(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_role(p_role_id IN NUMBER, p_new_role_name IN VARCHAR2);
    PROCEDURE delete_role(p_role_id IN NUMBER);
END role_procedures;
/

CREATE OR REPLACE PACKAGE BODY role_procedures AS
    -- Add Role Procedure
    PROCEDURE add_role(p_role_name IN VARCHAR2, p_role_id OUT NUMBER) IS
    BEGIN
        -- Check if role already exists
        DECLARE
            v_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_count 
            FROM ROLE 
            WHERE role_name = p_role_name;
            
            IF v_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20001, 'Role already exists: ' || p_role_name);
            END IF;
        END;

        -- Insert the new role and capture the generated role_id
        INSERT INTO ROLE (role_id, role_name)
        VALUES (role_seq.NEXTVAL, p_role_name)
        RETURNING role_id INTO p_role_id;  -- Get the newly generated role_id

        COMMIT;  -- Save the changes

        -- Display message
        DBMS_OUTPUT.PUT_LINE('Role added successfully with role_id: ' || p_role_id);
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback on error and provide error message
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'Error adding role: ' || SQLERRM);
    END add_role;
    
    -- Get Role Procedure
    PROCEDURE get_role(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        -- Opens a cursor with all roles for retrieval
        OPEN p_cursor FOR
        SELECT * FROM ROLE;
    END get_role;
    
    -- Update Role Procedure
    PROCEDURE update_role(p_role_id IN NUMBER, p_new_role_name IN VARCHAR2) IS
    BEGIN
        -- Check if the role exists
        DECLARE
            v_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_count 
            FROM ROLE 
            WHERE role_id = p_role_id;
            
            IF v_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20003, 'Role does not exist with ID: ' || p_role_id);
            END IF;
        END;

        -- Update role name
        UPDATE ROLE 
        SET role_name = p_new_role_name
        WHERE role_id = p_role_id;
        COMMIT; -- Save the update
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback on error and provide error message
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20004, 'Error updating role: ' || SQLERRM);
    END update_role;
    
    -- Delete Role Procedure
    PROCEDURE delete_role(p_role_id IN NUMBER) IS
        v_count NUMBER;
    BEGIN
        -- Check if any users reference this role
        SELECT COUNT(*) INTO v_count 
        FROM USER_TABLE 
        WHERE role_id = p_role_id;
        
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Cannot delete role - users exist with this role');
        END IF;

        -- Check if the role exists
        DECLARE
            v_role_count NUMBER;
        BEGIN
            SELECT COUNT(*) INTO v_role_count
            FROM ROLE
            WHERE role_id = p_role_id;

            IF v_role_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20006, 'Role does not exist with ID: ' || p_role_id);
            END IF;
        END;

        -- Delete the role if no dependencies found
        DELETE FROM ROLE WHERE role_id = p_role_id;
        COMMIT; -- Save the deletion
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20007, 'Error deleting role: ' || SQLERRM);
    END delete_role;

END role_procedures;
/


select * from role;

-- Execute ROLE Table Procedures

-- Add a new role
DECLARE
    v_role_id NUMBER;
BEGIN
    -- Adding the role 'Manager' and capturing the role_id in v_role_id
    role_procedures.add_role('Manager', v_role_id);
END;
/

-- Get all roles
DECLARE
    l_cursor SYS_REFCURSOR;
    l_role_id NUMBER;
    l_role_name VARCHAR2(100);
BEGIN
    role_procedures.get_role(l_cursor);
    LOOP
        FETCH l_cursor INTO l_role_id, l_role_name;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Role ID: ' || l_role_id || ', Role Name: ' || l_role_name);
    END LOOP;
    CLOSE l_cursor;
END;
/

-- Updating a role
EXEC role_procedures.update_role(21, 'Administrator');


-- Delete a role (will fail due to dependency)
EXEC role_procedures.delete_role(1);

-- Delete a role (will execute successfully)
EXEC role_procedures.delete_role(21);

--===================================================================================================

--USER_TABLE Procedures Package 
CREATE OR REPLACE PACKAGE user_procedures AS
    PROCEDURE add_user(
        p_role_id IN NUMBER, 
        p_username IN VARCHAR2, 
        p_email IN VARCHAR2, 
        p_password IN VARCHAR2, 
        p_user_id OUT NUMBER  
    );
    
    PROCEDURE get_user(p_user_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE update_user(
        p_user_id IN NUMBER, 
        p_username IN VARCHAR2, 
        p_email IN VARCHAR2, 
        p_password IN VARCHAR2, 
        p_role_id IN NUMBER
    );
    
    PROCEDURE delete_user(p_user_id IN NUMBER);
END user_procedures;
/

    
CREATE OR REPLACE PACKAGE BODY user_procedures AS

    -- Add User Procedure
    PROCEDURE add_user(
        p_role_id IN NUMBER, 
        p_username IN VARCHAR2, 
        p_email IN VARCHAR2, 
        p_password IN VARCHAR2, 
        p_user_id OUT NUMBER  
    ) IS
        v_count NUMBER;
    BEGIN
        -- Check if a user with the same username or email already exists
        SELECT COUNT(*) INTO v_count
        FROM USER_TABLE
        WHERE username = p_username OR email = p_email;

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'A user with the same username or email already exists.');
        END IF;

        -- Insert the user and return the ID using RETURNING INTO
        INSERT INTO USER_TABLE (user_id, role_id, username, Email, Password)
        VALUES (user_seq.NEXTVAL, p_role_id, p_username, p_email, p_password)
        RETURNING user_id INTO p_user_id;  -- Capture the generated ID

        COMMIT;  -- Save the changes

        -- Display message
        DBMS_OUTPUT.PUT_LINE('User added successfully with ID: ' || p_user_id);

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20005, 'Error adding user: ' || SQLERRM);
    END add_user;

    -- Get User Procedure
    PROCEDURE get_user(p_user_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        IF p_user_id IS NULL THEN
            OPEN p_cursor FOR
            SELECT * FROM USER_TABLE;

            -- Display message
            DBMS_OUTPUT.PUT_LINE('Fetched all users successfully.');
        ELSE
            OPEN p_cursor FOR
            SELECT * FROM USER_TABLE WHERE user_id = p_user_id;

            -- Check if user exists
            IF SQL%ROWCOUNT = 0 THEN
                DBMS_OUTPUT.PUT_LINE('No user found with ID: ' || p_user_id);
            ELSE
                DBMS_OUTPUT.PUT_LINE('Fetched user with ID: ' || p_user_id);
            END IF;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20008, 'Error fetching user: ' || SQLERRM);
    END get_user;

    -- Update User Procedure
    PROCEDURE update_user(
        p_user_id IN NUMBER, 
        p_username IN VARCHAR2, 
        p_email IN VARCHAR2, 
        p_password IN VARCHAR2, 
        p_role_id IN NUMBER
    ) IS
        v_count NUMBER;
    BEGIN
        -- Check if a user with the same username or email already exists (other than the current user)
        SELECT COUNT(*) INTO v_count
        FROM USER_TABLE
        WHERE (username = p_username OR email = p_email) AND user_id != p_user_id;

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'A user with the same username or email already exists.');
        END IF;

        -- Update the user details
        UPDATE USER_TABLE
        SET username = p_username,
            email = p_email,
            password = p_password,
            role_id = p_role_id
        WHERE user_id = p_user_id;

        -- Check if any row was affected
        IF SQL%ROWCOUNT > 0 THEN
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('User updated successfully with ID: ' || p_user_id);
        ELSE
            DBMS_OUTPUT.PUT_LINE('No user found with ID: ' || p_user_id);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20006, 'Error updating user: ' || SQLERRM);
    END update_user;

    -- Delete User Procedure
    PROCEDURE delete_user(p_user_id IN NUMBER) IS
    BEGIN
        -- Check if the user exists
        DELETE FROM USER_TABLE WHERE user_id = p_user_id;

        -- Check if any row was affected
        IF SQL%ROWCOUNT > 0 THEN
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('User deleted successfully with ID: ' || p_user_id);
        ELSE
            DBMS_OUTPUT.PUT_LINE('No user found with ID: ' || p_user_id);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20007, 'Error deleting user: ' || SQLERRM);
    END delete_user;

END user_procedures;
/


select * from user_table;


-- Execute USER_TABLE Procedures

-- Add a new user
DECLARE
    v_user_id NUMBER;
BEGIN
    user_procedures.add_user(2, 'Amit', 'Amit@example.com', 'amit123', v_user_id);
END;
/


-- Add a new user ( with duplicate email)
DECLARE
    v_user_id NUMBER;
BEGIN
    user_procedures.add_user(2, 'Aman', 'Amit@example.com', 'amit123', v_user_id);
END;
/



-- Get all users
DECLARE
    l_cursor SYS_REFCURSOR;
    l_user_id NUMBER;
    l_role_id NUMBER;
    l_username VARCHAR2(100);
    l_email VARCHAR2(100);
    l_password VARCHAR2(100);
BEGIN
    -- Fetch all users
    user_procedures.get_user(NULL, l_cursor);
    
    LOOP
        FETCH l_cursor INTO l_user_id, l_role_id, l_username, l_email, l_password;
        EXIT WHEN l_cursor%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('User ID: ' || l_user_id || 
                             ', Username: ' || l_username || 
                             ', Email: ' || l_email || 
                             ', Role ID: ' || l_role_id);
    END LOOP;
    
    -- Close the cursor
    CLOSE l_cursor;
END;
/



-- Get specific user
DECLARE
    l_cursor SYS_REFCURSOR;
    l_user_id NUMBER;
    l_role_id NUMBER;
    l_username VARCHAR2(100);
    l_email VARCHAR2(100);
    l_password VARCHAR2(100);
BEGIN
    -- Fetch a specific user
    user_procedures.get_user(1, l_cursor);
    
    FETCH l_cursor INTO l_user_id, l_role_id, l_username, l_email, l_password;
    
    DBMS_OUTPUT.PUT_LINE('User ID: ' || l_user_id || 
                         ', Username: ' || l_username || 
                         ', Email: ' || l_email || 
                         ', Role ID: ' || l_role_id);
    
    -- Close the cursor
    CLOSE l_cursor;
END;
/



-- Update a user
BEGIN
    user_procedures.update_user(23, 'AmitUpdated', 'amit.updated@example.com', 'newpass123', 3);
END;
/


-- Delete a user
BEGIN
    user_procedures.delete_user(23);
END;
/

--=============================================================================================================
    
-- AUDIT_LOG Procedures Package
CREATE OR REPLACE PACKAGE audit_procedures AS
    -- Procedure to retrieve audit logs with optional filters
    PROCEDURE get_audit_logs(p_tablename IN VARCHAR2 DEFAULT NULL, 
                           p_start_date IN TIMESTAMP DEFAULT NULL,
                           p_end_date IN TIMESTAMP DEFAULT NULL,
                           p_cursor OUT SYS_REFCURSOR);
END audit_procedures;
/

CREATE OR REPLACE PACKAGE BODY audit_procedures AS
    PROCEDURE get_audit_logs(
        p_tablename IN VARCHAR2 DEFAULT NULL, 
        p_start_date IN TIMESTAMP DEFAULT NULL,
        p_end_date IN TIMESTAMP DEFAULT NULL,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_count NUMBER;
    BEGIN
        -- Opens a cursor to fetch audit logs
        -- Filters are optional: if parameters are NULL, they are ignored
        -- With sample data, returns all logs if no filters applied
        OPEN p_cursor FOR
        SELECT * FROM AUDIT_LOG
        WHERE (p_tablename IS NULL OR tablename = p_tablename)
        AND (p_start_date IS NULL OR Updated_at >= p_start_date)
        AND (p_end_date IS NULL OR Updated_at <= p_end_date);
        
        -- Check if any records were found
        SELECT COUNT(*) INTO v_count
        FROM AUDIT_LOG
        WHERE (p_tablename IS NULL OR tablename = p_tablename)
        AND (p_start_date IS NULL OR Updated_at >= p_start_date)
        AND (p_end_date IS NULL OR Updated_at <= p_end_date);
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'No audit logs found for the given filters.');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error fetching audit logs: ' || SQLERRM);
    END get_audit_logs;
END audit_procedures;
/

select * from Audit_log;


-- Execute AUDIT_LOG Procedure 
DECLARE
    l_cursor SYS_REFCURSOR;
    l_audit_id NUMBER;
    l_user_name VARCHAR2(100);
    l_tablename VARCHAR2(100);
    l_action VARCHAR2(100);
    l_oldValue VARCHAR2(100);
    l_newValue VARCHAR2(100);
    l_updated_at TIMESTAMP;
BEGIN
    -- Call get_audit_logs with no filters to retrieve all audit entries
    audit_procedures.get_audit_logs(NULL, NULL, NULL, l_cursor);
    LOOP
        FETCH l_cursor INTO l_audit_id, l_user_name, l_tablename, l_action, 
                           l_oldValue, l_newValue, l_updated_at;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Audit ID: ' || l_audit_id || 
                            ', User: ' || l_user_name || 
                            ', Table: ' || l_tablename || 
                            ', Action: ' || l_action || 
                            ', Old Value: ' || l_oldValue || 
                            ', New Value: ' || l_newValue || 
                            ', Updated At: ' || TO_CHAR(l_updated_at, 'YYYY-MM-DD HH24:MI:SS'));
    END LOOP;
    CLOSE l_cursor;
END;
/


-- Execute AUDIT_LOG Procedure with Filter (for USER_TABLE)
DECLARE
    l_cursor SYS_REFCURSOR;
    l_audit_id NUMBER;
    l_user_name VARCHAR2(100);
    l_tablename VARCHAR2(100);
    l_action VARCHAR2(100);
    l_oldValue VARCHAR2(100);
    l_newValue VARCHAR2(100);
    l_updated_at TIMESTAMP;
BEGIN
    -- Call get_audit_logs with filter for USER_TABLE only
    audit_procedures.get_audit_logs('USER_TABLE', NULL, NULL, l_cursor);
    
    -- Fetch and display the results from the cursor
    LOOP
        FETCH l_cursor INTO l_audit_id, l_user_name, l_tablename, l_action, 
                           l_oldValue, l_newValue, l_updated_at;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Audit ID: ' || l_audit_id || 
                            ', User: ' || l_user_name || 
                            ', Table: ' || l_tablename || 
                            ', Action: ' || l_action || 
                            ', Old Value: ' || l_oldValue || 
                            ', New Value: ' || l_newValue || 
                            ', Updated At: ' || TO_CHAR(l_updated_at, 'YYYY-MM-DD HH24:MI:SS'));
    END LOOP;
    CLOSE l_cursor;
END;
/

--==========================================================================================================================
    
-- CUSTOMER Procedures 
CREATE OR REPLACE PACKAGE customer_procedures AS
    PROCEDURE add_customer(p_cust_name IN VARCHAR2, p_phone IN VARCHAR2, 
                         p_email IN VARCHAR2, p_address IN VARCHAR2, 
                         p_cust_id OUT NUMBER);
    PROCEDURE get_customer(p_cust_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_customer(p_cust_id IN NUMBER, p_cust_name IN VARCHAR2, p_phone IN VARCHAR2, p_email IN VARCHAR2, p_address IN VARCHAR2);
    PROCEDURE delete_customer(p_cust_id IN NUMBER);
    PROCEDURE CustomerSearchByPartialName(
        p_SearchTerm IN VARCHAR2,
        p_Result OUT SYS_REFCURSOR
    );
END customer_procedures;
/

CREATE OR REPLACE PACKAGE BODY customer_procedures AS
    PROCEDURE add_customer(p_cust_name IN VARCHAR2, p_phone IN VARCHAR2, 
                         p_email IN VARCHAR2, p_address IN VARCHAR2, 
                         p_cust_id OUT NUMBER) IS
    BEGIN
        p_cust_id := customer_seq.NEXTVAL;
        INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address)
        VALUES (p_cust_id, p_cust_name, p_phone, p_email, p_address);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20008, 'Error adding customer: ' || SQLERRM);
    END add_customer;

    PROCEDURE get_customer(p_cust_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        IF p_cust_id IS NULL THEN
            OPEN p_cursor FOR SELECT * FROM CUSTOMER;
        ELSE
            OPEN p_cursor FOR SELECT * FROM CUSTOMER WHERE cust_id = p_cust_id;
        END IF;
    END get_customer;

    PROCEDURE update_customer(p_cust_id IN NUMBER, p_cust_name IN VARCHAR2, 
                            p_phone IN VARCHAR2, p_email IN VARCHAR2, 
                            p_address IN VARCHAR2) IS
    BEGIN
        UPDATE CUSTOMER
        SET cust_name = p_cust_name,
            phone = p_phone,
            email = p_email,
            address = p_address
        WHERE cust_id = p_cust_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20009, 'Error updating customer: ' || SQLERRM);
    END update_customer;

    PROCEDURE delete_customer(p_cust_id IN NUMBER) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM VEHICLE WHERE cust_id = p_cust_id;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Cannot delete customer - vehicles exist for this customer');
        END IF;

        DELETE FROM CUSTOMER WHERE cust_id = p_cust_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20011, 'Error deleting customer: ' || SQLERRM);
    END delete_customer;

    PROCEDURE CustomerSearchByPartialName(
        p_SearchTerm IN VARCHAR2,
        p_Result OUT SYS_REFCURSOR
    )
    IS
    BEGIN
        OPEN p_Result FOR
            SELECT 
                cust_id,
                cust_name,
                email,
                phone,
                address
            FROM 
                CUSTOMER
            WHERE 
                UPPER(cust_name) LIKE '%' || UPPER(p_SearchTerm) || '%'
            ORDER BY 
                cust_name;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Error in CustomerSearchByPartialName: ' || SQLERRM);
    END CustomerSearchByPartialName;
END customer_procedures;
/


-- Add a new customer
SET SERVEROUTPUT ON;
DECLARE
  v_cust_id NUMBER;
BEGIN
  customer_procedures.add_customer('Khush Santoki', '9865321470', 
                                 'Khush@example.com', '123 vadnagar Street', 
                                 v_cust_id);
  DBMS_OUTPUT.PUT_LINE('New Customer ID: ' || v_cust_id);
END;
/

-- Get all customers
SET SERVEROUTPUT ON;
DECLARE
    l_cursor SYS_REFCURSOR;
    l_cust_id NUMBER;
    l_cust_name VARCHAR2(100);
    l_phone VARCHAR2(20);
    l_email VARCHAR2(100);
    l_address VARCHAR2(255);
BEGIN
    customer_procedures.get_customer(NULL, l_cursor);
    LOOP
        FETCH l_cursor INTO l_cust_id, l_cust_name, l_phone, l_email, l_address;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Customer ID: ' || l_cust_id || ', Name: ' || l_cust_name || ', Phone: ' || l_phone || ', Email: ' || l_email || ', Address: ' || l_address);
    END LOOP;
    CLOSE l_cursor;
END;
/



-- Update a customer
SET SERVEROUTPUT ON;
EXEC customer_procedures.update_customer(2, 'Vatsal Mistry', '8765432109', 'vatsal@example.com', '456 Oak Avenue');

-- Delete a customer 
SET SERVEROUTPUT ON;
EXEC customer_procedures.delete_customer(5);

-- Execute using anonymous block
SET SERVEROUTPUT ON;
DECLARE
    l_cursor SYS_REFCURSOR;
    l_cust_id NUMBER;
    l_cust_name VARCHAR2(100);
    l_email VARCHAR2(100);
    l_phone VARCHAR2(20);
    l_address VARCHAR2(200);
BEGIN
    customer_procedures.CustomerSearchByPartialName(
        p_SearchTerm => 'test',
        p_Result => l_cursor
    );
    
    LOOP
        FETCH l_cursor INTO 
            l_cust_id,
            l_cust_name,
            l_email,
            l_phone,
            l_address;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Customer: ' || l_cust_name || ' - ' || l_email);
    END LOOP;
    CLOSE l_cursor;
END;
/


-- VEHICLE Procedures 
CREATE OR REPLACE PACKAGE vehicle_procedures AS
    PROCEDURE add_vehicle(p_cust_id IN NUMBER, p_licence_plate IN VARCHAR2, 
                         p_make IN VARCHAR2, p_model IN VARCHAR2, 
                         p_year IN NUMBER, p_vehicle_id OUT NUMBER);
    PROCEDURE get_vehicle(p_vehicle_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_vehicle(p_vehicle_id IN NUMBER, p_licence_plate IN VARCHAR2, p_make IN VARCHAR2, p_model IN VARCHAR2, p_year IN NUMBER);
    PROCEDURE delete_vehicle(p_vehicle_id IN NUMBER);
END vehicle_procedures;
/



CREATE OR REPLACE PACKAGE BODY vehicle_procedures AS
    PROCEDURE add_vehicle(p_cust_id IN NUMBER, p_licence_plate IN VARCHAR2, 
                         p_make IN VARCHAR2, p_model IN VARCHAR2, 
                         p_year IN NUMBER, p_vehicle_id OUT NUMBER) IS
    BEGIN
        p_vehicle_id := vehicle_seq.NEXTVAL;
        INSERT INTO VEHICLE (Vehicle_id, cust_id, Licence_plate, Make, Model, Year)
        VALUES (p_vehicle_id, p_cust_id, p_licence_plate, p_make, p_model, p_year);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20012, 'Error adding vehicle: ' || SQLERRM);
    END add_vehicle;

    PROCEDURE get_vehicle(p_vehicle_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        IF p_vehicle_id IS NULL THEN
            OPEN p_cursor FOR SELECT * FROM VEHICLE;
        ELSE
            OPEN p_cursor FOR SELECT * FROM VEHICLE WHERE Vehicle_id = p_vehicle_id;
        END IF;
    END get_vehicle;

    PROCEDURE update_vehicle(p_vehicle_id IN NUMBER, p_licence_plate IN VARCHAR2, p_make IN VARCHAR2, p_model IN VARCHAR2, p_year IN NUMBER) IS
    BEGIN
        UPDATE VEHICLE
        SET Licence_plate = p_licence_plate,
            Make = p_make,
            Model = p_model,
            Year = p_year
        WHERE Vehicle_id = p_vehicle_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20013, 'Error updating vehicle: ' || SQLERRM);
    END update_vehicle;

    PROCEDURE delete_vehicle(p_vehicle_id IN NUMBER) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM APPOINTMENT WHERE vehicle_id = p_vehicle_id;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20014, 'Cannot delete vehicle - appointments exist for this vehicle');
        END IF;

        DELETE FROM VEHICLE WHERE Vehicle_id = p_vehicle_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20015, 'Error deleting vehicle: ' || SQLERRM);
    END delete_vehicle;
END vehicle_procedures;
/


SET SERVEROUTPUT ON;

-- Add a new vehicle
DECLARE
  v_vehicle_id NUMBER;
BEGIN
  vehicle_procedures.add_vehicle(4, 'ABC123', 'Toyota', 'Camry', 2022, v_vehicle_id);
  DBMS_OUTPUT.PUT_LINE('New Vehicle ID: ' || v_vehicle_id);
END;
/

-- Get all vehicles
SET SERVEROUTPUT ON;
DECLARE
    l_cursor SYS_REFCURSOR;
    l_vehicle_id NUMBER;
    l_cust_id NUMBER;
    l_licence_plate VARCHAR2(50);
    l_make VARCHAR2(50);
    l_model VARCHAR2(50);
    l_year NUMBER;
BEGIN
    vehicle_procedures.get_vehicle(NULL, l_cursor);
    LOOP
        FETCH l_cursor INTO l_vehicle_id, l_cust_id, l_licence_plate, l_make, l_model, l_year;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Vehicle ID: ' || l_vehicle_id || ', License Plate: ' || l_licence_plate || ', Make: ' || l_make || ', Model: ' || l_model || ', Year: ' || l_year);
    END LOOP;
    CLOSE l_cursor;
END;
/

-- Update a vehicle
EXEC vehicle_procedures.update_vehicle(1, 'XYZ789', 'Honda', 'Accord', 2021);

-- Delete a vehicle (will fail if appointments exist)
EXEC vehicle_procedures.delete_vehicle(4);






-- APPOINTMENT Procedures 
CREATE OR REPLACE PACKAGE appointment_procedures AS
PROCEDURE schedule_appointment(p_cust_id IN NUMBER, p_vehicle_id IN NUMBER, 
                                 p_app_date IN DATE, p_app_time IN TIMESTAMP, 
                                 p_status IN VARCHAR2, p_service_id IN NUMBER, 
                                 p_emp_id IN NUMBER, p_app_id OUT NUMBER);
    PROCEDURE get_appointment(p_app_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_appointment_status(p_app_id IN NUMBER, p_status IN VARCHAR2);
    PROCEDURE delete_appointment(p_app_id IN NUMBER);
END appointment_procedures;
/

CREATE OR REPLACE PACKAGE BODY appointment_procedures AS
    PROCEDURE schedule_appointment(p_cust_id IN NUMBER, p_vehicle_id IN NUMBER, 
                                 p_app_date IN DATE, p_app_time IN TIMESTAMP, 
                                 p_status IN VARCHAR2, p_service_id IN NUMBER, 
                                 p_emp_id IN NUMBER, p_app_id OUT NUMBER) IS
    BEGIN
        p_app_id := appointment_seq.NEXTVAL;
        INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, 
                               status, service_id, emp_id)
        VALUES (p_app_id, p_cust_id, p_vehicle_id, p_app_date, p_app_time, 
                p_status, p_service_id, p_emp_id);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20016, 'Error scheduling appointment: ' || SQLERRM);
    END schedule_appointment;

    PROCEDURE get_appointment(p_app_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        IF p_app_id IS NULL THEN
            OPEN p_cursor FOR SELECT * FROM APPOINTMENT;
        ELSE
            OPEN p_cursor FOR SELECT * FROM APPOINTMENT WHERE app_id = p_app_id;
        END IF;
    END get_appointment;

    PROCEDURE update_appointment_status(p_app_id IN NUMBER, p_status IN VARCHAR2) IS
    BEGIN
        UPDATE APPOINTMENT
        SET status = p_status
        WHERE app_id = p_app_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20017, 'Error updating appointment status: ' || SQLERRM);
    END update_appointment_status;

    PROCEDURE delete_appointment(p_app_id IN NUMBER) IS
    BEGIN
        DELETE FROM APPOINTMENT WHERE app_id = p_app_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20018, 'Error deleting appointment: ' || SQLERRM);
    END delete_appointment;
END appointment_procedures;
/

SET SERVEROUTPUT ON;

-- Schedule a new appointment
DECLARE
  v_app_id NUMBER;
BEGIN
  appointment_procedures.schedule_appointment(1, 1, TO_DATE('23-10-01', 'YYYY-MM-DD'), 
                                            TO_TIMESTAMP('11:30:00', 'HH24:MI:SS'), 
                                            'Scheduled', 1, 1, v_app_id);
  DBMS_OUTPUT.PUT_LINE('New Appointment ID: ' || v_app_id);
END;
/

-- Get all appointments
SET SERVEROUTPUT ON;
DECLARE
    l_cursor SYS_REFCURSOR;
    l_app_id NUMBER;
    l_cust_id NUMBER;
    l_vehicle_id NUMBER;
    l_app_date DATE;
    l_app_time TIMESTAMP;
    l_status VARCHAR2(50);
    l_service_id NUMBER;
    l_emp_id NUMBER;
BEGIN
    appointment_procedures.get_appointment(NULL, l_cursor);
    LOOP
        FETCH l_cursor INTO l_app_id, l_cust_id, l_vehicle_id, l_app_date, l_app_time, l_status, l_service_id, l_emp_id;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Appointment ID: ' || l_app_id || ', Date: ' || l_app_date || ', Time: ' || l_app_time || ', Status: ' || l_status);
    END LOOP;
    CLOSE l_cursor;
END;
/

-- Update appointment status
EXEC appointment_procedures.update_appointment_status(1, 'Completed');

-- Delete an appointment
EXEC appointment_procedures.delete_appointment(22);





-- EMPLOYEE Procedures Package
CREATE OR REPLACE PACKAGE employee_procedures AS
    PROCEDURE add_employee(p_emp_name IN VARCHAR2, p_position IN VARCHAR2, 
                         p_emp_phn IN VARCHAR2, p_email IN VARCHAR2, 
                         p_salary IN NUMBER, p_hire_date IN DATE, 
                         p_hours_worked IN NUMBER, p_emp_id OUT NUMBER);
    PROCEDURE get_employee(p_emp_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_employee(p_emp_id IN NUMBER, p_emp_name IN VARCHAR2, p_position IN VARCHAR2, p_emp_phn IN VARCHAR2, p_email IN VARCHAR2, p_salary IN NUMBER, p_hire_date IN DATE, p_hours_worked IN NUMBER);
    PROCEDURE delete_employee(p_emp_id IN NUMBER);
END employee_procedures;
/

CREATE OR REPLACE PACKAGE BODY employee_procedures AS
    PROCEDURE add_employee(p_emp_name IN VARCHAR2, p_position IN VARCHAR2, 
                         p_emp_phn IN VARCHAR2, p_email IN VARCHAR2, 
                         p_salary IN NUMBER, p_hire_date IN DATE, 
                         p_hours_worked IN NUMBER, p_emp_id OUT NUMBER) IS
    BEGIN
        p_emp_id := employee_seq.NEXTVAL;
        INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, 
                            salary, hire_date, hours_worked)
        VALUES (p_emp_id, p_emp_name, p_position, p_emp_phn, p_email, 
                p_salary, p_hire_date, p_hours_worked);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20019, 'Error adding employee: ' || SQLERRM);
    END add_employee;

    PROCEDURE get_employee(p_emp_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        IF p_emp_id IS NULL THEN
            OPEN p_cursor FOR SELECT * FROM EMPLOYEE;
        ELSE
            OPEN p_cursor FOR SELECT * FROM EMPLOYEE WHERE emp_id = p_emp_id;
        END IF;
    END get_employee;

    PROCEDURE update_employee(p_emp_id IN NUMBER, p_emp_name IN VARCHAR2, p_position IN VARCHAR2, p_emp_phn IN VARCHAR2, p_email IN VARCHAR2, p_salary IN NUMBER, p_hire_date IN DATE, p_hours_worked IN NUMBER) IS
    BEGIN
        UPDATE EMPLOYEE
        SET emp_name = p_emp_name,
            position = p_position,
            emp_phn = p_emp_phn,
            email = p_email,
            salary = p_salary,
            hire_date = p_hire_date,
            hours_worked = p_hours_worked
        WHERE emp_id = p_emp_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20020, 'Error updating employee: ' || SQLERRM);
    END update_employee;

    PROCEDURE delete_employee(p_emp_id IN NUMBER) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM APPOINTMENT WHERE emp_id = p_emp_id;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20021, 'Cannot delete employee - appointments exist for this employee');
        END IF;

        DELETE FROM EMPLOYEE WHERE emp_id = p_emp_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20022, 'Error deleting employee: ' || SQLERRM);
    END delete_employee;
END employee_procedures;
/



SET SERVEROUTPUT ON;

-- Add a new employee
DECLARE
  v_emp_id NUMBER;
BEGIN
  employee_procedures.add_employee('Alice Johnson', 'Manager', '1928374650', 
                                 'alice@example.com', 60000.00, 
                                 TO_DATE('2018-03-25', 'YYYY-MM-DD'), 
                                 45.75, v_emp_id);
  DBMS_OUTPUT.PUT_LINE('New Employee ID: ' || v_emp_id);
END;
/

-- Get all employees
SET SERVEROUTPUT ON;
DECLARE
    l_cursor SYS_REFCURSOR;
    l_emp_id NUMBER;
    l_emp_name VARCHAR2(100);
    l_position VARCHAR2(50);
    l_emp_phn VARCHAR2(20);
    l_email VARCHAR2(100);
    l_salary NUMBER;
    l_hire_date DATE;
    l_hours_worked NUMBER;
BEGIN
    employee_procedures.get_employee(NULL, l_cursor);
    LOOP
        FETCH l_cursor INTO l_emp_id, l_emp_name, l_position, l_emp_phn, l_email, l_salary, l_hire_date, l_hours_worked;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Employee ID: ' || l_emp_id || ', Name: ' || l_emp_name || ', Position: ' || l_position || ', Phone: ' || l_emp_phn);
    END LOOP;
    CLOSE l_cursor;
END;
/

-- Update an employee
EXEC employee_procedures.update_employee(1, 'Alice Smith', 'Senior Manager', '1928374651', 'alice.smith@example.com', 65000.00, TO_DATE('2018-03-25', 'YYYY-MM-DD'), 48.00);

-- Delete an employee (will fail if appointments exist)
EXEC employee_procedures.delete_employee(21);





--  Invoice Package Specification
CREATE OR REPLACE PACKAGE invoice_pkg AS
    PROCEDURE generate_invoice (
        p_service_id IN NUMBER,
        p_app_id IN NUMBER,
        p_total_amount IN NUMBER,
        p_invoice_id OUT NUMBER
    );

    PROCEDURE get_invoice_by_id (
        p_invoice_id IN NUMBER
    );
END invoice_pkg;
/

--  Invoice Package Body
CREATE OR REPLACE PACKAGE BODY invoice_pkg AS
    -- generate_invoice procedure
    PROCEDURE generate_invoice (
        p_service_id IN NUMBER,
        p_app_id IN NUMBER,
        p_total_amount IN NUMBER,
        p_invoice_id OUT NUMBER
    ) AS
    BEGIN
        p_invoice_id := invoice_seq.NEXTVAL;
        INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount, created_at)
        VALUES (p_invoice_id, p_service_id, p_app_id, SYSDATE, p_total_amount, SYSTIMESTAMP);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Invoice generated successfully. Invoice ID: ' || p_invoice_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error while generating invoice: ' || SQLERRM);
    END generate_invoice;

    -- get_invoice_by_id procedure
    PROCEDURE get_invoice_by_id (
        p_invoice_id IN NUMBER
    ) AS
        v_service_id NUMBER;
        v_app_id NUMBER;
        v_invoice_date DATE;
        v_total_amount NUMBER;
        v_created_at TIMESTAMP;
    BEGIN
        SELECT service_id, app_id, invoice_date, total_amount, created_at
        INTO v_service_id, v_app_id, v_invoice_date, v_total_amount, v_created_at
        FROM INVOICE
        WHERE invoice_id = p_invoice_id;

        DBMS_OUTPUT.PUT_LINE('Invoice ID: ' || p_invoice_id);
        DBMS_OUTPUT.PUT_LINE('Service ID: ' || v_service_id);
        DBMS_OUTPUT.PUT_LINE('Appointment ID: ' || v_app_id);
        DBMS_OUTPUT.PUT_LINE('Invoice Date: ' || v_invoice_date);
        DBMS_OUTPUT.PUT_LINE('Total Amount: ' || v_total_amount);
        DBMS_OUTPUT.PUT_LINE('Created At: ' || v_created_at);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: Invoice with ID ' || p_invoice_id || ' not found.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END get_invoice_by_id;

END invoice_pkg;
/

--Execution of generate_invoice
DECLARE
    v_invoice_id NUMBER;  -- Declare a variable to store the returned invoice_id
BEGIN
    invoice_pkg.generate_invoice(6, 6, 250.00, v_invoice_id);  -- Pass the OUT parameter to get the ID
    DBMS_OUTPUT.PUT_LINE('Generated Invoice ID: ' || v_invoice_id);  -- Output the returned ID
END;
/
--execution of get_invoice_by_id
BEGIN
    invoice_pkg.get_invoice_by_id(1);
END;
/


--procedure to get all invoices
CREATE OR REPLACE PROCEDURE get_all_invoices
IS
BEGIN
    FOR inv IN (
        SELECT invoice_id, service_id, invoice_date, total_amount, created_at
        FROM invoice
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Invoice ID: ' || inv.invoice_id ||
                             ', Service ID: ' || inv.service_id ||
                             ', Invoice Date: ' || TO_CHAR(inv.invoice_date, 'YYYY-MM-DD') ||
                             ', Total Amount: ' || inv.total_amount ||
                             ', Created At: ' || TO_CHAR(inv.created_at, 'YYYY-MM-DD HH24:MI:SS'));
    END LOOP;
END;
/
--execution of get_all_invoices
SET SERVEROUTPUT ON;
EXEC get_all_invoices;


--PAYMENT PACKAGEB SPECIFICATION
CREATE OR REPLACE PACKAGE payment_pkg AS
    PROCEDURE record_payment (
        p_invoice_id IN NUMBER,
        p_amount_paid IN NUMBER,
        p_payment_method IN VARCHAR2,
        p_status IN VARCHAR2,
        p_payment_id OUT NUMBER
    );

    PROCEDURE get_payment_by_id (
        p_payment_id IN NUMBER
    );

    PROCEDURE update_payment_status (
        p_payment_id IN NUMBER,
        p_new_status IN VARCHAR2
    );
END payment_pkg;
/

 Payment Package Body
CREATE OR REPLACE PACKAGE BODY payment_pkg AS

     -- record_payment procedure
    PROCEDURE record_payment (
        p_invoice_id IN NUMBER,
        p_amount_paid IN NUMBER,
        p_payment_method IN VARCHAR2,
        p_status IN VARCHAR2,
        p_payment_id OUT NUMBER
    ) AS
    BEGIN
        p_payment_id := payment_seq.NEXTVAL;
        INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status)
        VALUES (p_payment_id, p_invoice_id, SYSDATE, p_amount_paid, p_payment_method, p_status);
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Payment recorded successfully. Payment ID: ' || p_payment_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error while recording payment: ' || SQLERRM);
    END record_payment;

    --get_payment_by_id procedure
    PROCEDURE get_payment_by_id (
        p_payment_id IN NUMBER
    ) AS
        v_invoice_id NUMBER;
        v_payment_date DATE;
        v_amount_paid NUMBER(10,2);
        v_payment_method VARCHAR2(50);
        v_status VARCHAR2(20);
    BEGIN
        SELECT invoice_id, payment_date, amount_paid, payment_method, status
        INTO v_invoice_id, v_payment_date, v_amount_paid, v_payment_method, v_status
        FROM PAYMENT
        WHERE payment_id = p_payment_id;

        DBMS_OUTPUT.PUT_LINE('Payment ID: ' || p_payment_id);
        DBMS_OUTPUT.PUT_LINE('Invoice ID: ' || v_invoice_id);
        DBMS_OUTPUT.PUT_LINE('Payment Date: ' || v_payment_date);
        DBMS_OUTPUT.PUT_LINE('Amount Paid: ' || v_amount_paid);
        DBMS_OUTPUT.PUT_LINE('Payment Method: ' || v_payment_method);
        DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: Payment not found.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error while retrieving payment: ' || SQLERRM);
    END get_payment_by_id; 
 
     -- update_payment_status procedure
    PROCEDURE update_payment_status (
        p_payment_id IN NUMBER,
        p_new_status IN VARCHAR2
    ) AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM PAYMENT WHERE payment_id = p_payment_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error: Payment ID does not exist.');
        END IF;

        UPDATE PAYMENT
        SET status = p_new_status
        WHERE payment_id = p_payment_id;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Payment status updated successfully for Payment ID: ' || p_payment_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error while updating payment status: ' || SQLERRM);
    END update_payment_status;

END payment_pkg;
/

select * from payment
select * from invoice 

SET SERVEROUTPUT ON;

-- 1. Executing the 'record_payment' procedure
DECLARE
    v_payment_id NUMBER; 
BEGIN
    payment_pkg.record_payment(4, 100, 'Credit Card', 'successful', v_payment_id);
    DBMS_OUTPUT.PUT_LINE('Generated Payment ID: ' || v_payment_id);
END;
/


-- 2. Executing the 'get_payment_by_id' procedure
BEGIN
    payment_pkg.get_payment_by_id(2);
END;
/

-- 3. Executing the 'update_payment_status' procedure
BEGIN
    payment_pkg.update_payment_status(1, 'Successful');
END;
/
---

--procedure to get all payment
CREATE OR REPLACE PROCEDURE get_all_payments
IS
BEGIN
    FOR pay IN (
        SELECT payment_id, invoice_id, payment_date, amount_paid, payment_method, status
        FROM payment
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Payment ID: ' || pay.payment_id ||
                             ', Invoice ID: ' || pay.invoice_id ||
                             ', Payment Date: ' || TO_CHAR(pay.payment_date, 'YYYY-MM-DD') ||
                             ', Amount Paid: ' || pay.amount_paid ||
                             ', Method: ' || pay.payment_method ||
                             ', Status: ' || pay.status);
    END LOOP;
END;
/

SET SERVEROUTPUT ON;
EXEC get_all_payments;

--------------------------------------------------------------------------
==========================================================================
--Procedure for service, service_inventory and inventory table
SET SERVEROUTPUT ON;

--1 package for service table
CREATE OR REPLACE PACKAGE service_pkg AS
    PROCEDURE add_service(p_service_type IN VARCHAR2, p_service_date IN DATE, p_status IN VARCHAR2, p_cost IN NUMBER, p_service_id OUT NUMBER);
    PROCEDURE get_service(p_service_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR, p_service_id_out OUT NUMBER);
    PROCEDURE update_service(p_service_id IN NUMBER, p_status IN VARCHAR2, p_cost IN NUMBER, p_service_id_out OUT NUMBER);
    PROCEDURE delete_service(p_service_id IN NUMBER, p_service_id_out OUT NUMBER);
END service_pkg;
/
--body of service_pkg
CREATE OR REPLACE PACKAGE BODY service_pkg AS

    PROCEDURE add_service (
        p_service_type IN VARCHAR2,
        p_service_date IN DATE,
        p_status IN VARCHAR2,
        p_cost IN NUMBER,
        p_service_id OUT NUMBER  
    ) AS
    BEGIN
        INSERT INTO Service (service_id, service_type, service_date, status, cost)
        VALUES (service_seq.NEXTVAL, p_service_type, p_service_date, p_status, p_cost)
        RETURNING service_id INTO p_service_id;  
        COMMIT;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'Error : Duplicate service ID error.');
        WHEN VALUE_ERROR THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20003, 'Invalid value.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Error while adding service: ' || SQLERRM);
    END add_service;

    PROCEDURE get_service (
        p_service_id IN NUMBER DEFAULT NULL,
        p_cursor OUT SYS_REFCURSOR,
        p_service_id_out OUT NUMBER  
    ) AS
    BEGIN
        p_service_id_out := p_service_id;
        IF p_service_id IS NULL THEN
            OPEN p_cursor FOR SELECT * FROM Service;
        ELSE
            OPEN p_cursor FOR SELECT * FROM Service WHERE service_id = p_service_id;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error retrieving service: ' || SQLERRM);
    END get_service;

    PROCEDURE update_service (
        p_service_id IN NUMBER,
        p_status IN VARCHAR2,
        p_cost IN NUMBER,
        p_service_id_out OUT NUMBER 
    ) AS
    BEGIN
        UPDATE Service
        SET status = p_status, cost = p_cost
        WHERE service_id = p_service_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Service ID not found');
        END IF;

        p_service_id_out := p_service_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20004, 'Error while updating service: ' || SQLERRM);
    END update_service;

    PROCEDURE delete_service (
        p_service_id IN NUMBER,
        p_service_id_out OUT NUMBER 
    ) AS
    BEGIN
        DELETE FROM service_inventory WHERE service_id = p_service_id;
        DELETE FROM Service WHERE service_id = p_service_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Service ID not found');
        END IF;

        p_service_id_out := p_service_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20006, 'Error while deleting service: ' || SQLERRM);
    END delete_service;

END service_pkg;
/


--2 package for inventory table
CREATE OR REPLACE PACKAGE inventory_pkg AS
    PROCEDURE add_inventory_item(p_item_name IN VARCHAR2, p_quantity IN NUMBER, p_price_per_unit IN NUMBER, p_item_id_out OUT NUMBER);
    PROCEDURE get_inventory(p_item_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_inventory(p_item_id IN NUMBER, p_quantity IN NUMBER, p_price_per_unit IN NUMBER);
    PROCEDURE delete_inventory(p_item_id IN NUMBER, p_deleted_item_id OUT NUMBER);
END inventory_pkg;
/
--body of inventory_pkg
CREATE OR REPLACE PACKAGE BODY inventory_pkg AS

    PROCEDURE add_inventory_item (
        p_item_name IN VARCHAR2,
        p_quantity IN NUMBER,
        p_price_per_unit IN NUMBER,
        p_item_id_out OUT NUMBER  
    ) AS
    BEGIN
        INSERT INTO inventory (item_id, item_name, quantity, price_per_unit)
        VALUES (inventory_seq.NEXTVAL, p_item_name, p_quantity, p_price_per_unit)
        RETURNING item_id INTO p_item_id_out; 
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20007, 'Error adding inventory item: ' || SQLERRM);
    END add_inventory_item;

    PROCEDURE get_inventory (
        p_item_id IN NUMBER DEFAULT NULL,
        p_cursor OUT SYS_REFCURSOR
    ) AS
    BEGIN
        IF p_item_id IS NULL THEN
            OPEN p_cursor FOR SELECT * FROM inventory;
        ELSE
            OPEN p_cursor FOR SELECT * FROM inventory WHERE item_id = p_item_id;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20008, 'Error while retrieving inventory: ' || SQLERRM);
    END get_inventory;

    PROCEDURE update_inventory (
        p_item_id IN NUMBER,
        p_quantity IN NUMBER,
        p_price_per_unit IN NUMBER
    ) AS
    BEGIN
        UPDATE inventory
        SET quantity = p_quantity, price_per_unit = p_price_per_unit
        WHERE item_id = p_item_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'Inventory item ID not found');
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20010, 'Error while updating inventory: ' || SQLERRM);
    END update_inventory;

    PROCEDURE delete_inventory (
        p_item_id IN NUMBER,
        p_deleted_item_id OUT NUMBER       
    ) AS
    BEGIN
        DELETE FROM inventory WHERE item_id = p_item_id;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Inventory item ID not found');
        ELSE
            p_deleted_item_id := p_item_id;
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20012, 'Error deleting inventory: ' || SQLERRM);
    END delete_inventory;

END inventory_pkg;
/


--3 package for service_inventory table
CREATE OR REPLACE PACKAGE service_inventory_pkg AS
    PROCEDURE use_inventory(p_service_id IN OUT NUMBER, p_item_id IN NUMBER, p_quantity_used IN OUT NUMBER);
    PROCEDURE get_service_inventory(p_service_id IN NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE delete_service_inventory(p_service_id IN NUMBER, p_item_id IN NUMBER);
END service_inventory_pkg;
/

-- body of service_inventory_pkg
CREATE OR REPLACE PACKAGE BODY service_inventory_pkg AS

    PROCEDURE use_inventory (
        p_service_id IN OUT NUMBER,
        p_item_id IN NUMBER,
        p_quantity_used IN OUT NUMBER
    ) AS
    BEGIN
        INSERT INTO service_inventory (service_id, item_id, quantity_used)
        VALUES (p_service_id, p_item_id, p_quantity_used);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20014, 'Error while using inventory: ' || SQLERRM);
    END use_inventory;

    PROCEDURE get_service_inventory (
        p_service_id IN NUMBER,
        p_cursor OUT SYS_REFCURSOR
    ) AS
    BEGIN
        OPEN p_cursor FOR SELECT * FROM service_inventory WHERE service_id = p_service_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20015, 'Error retrieving service inventory: ' || SQLERRM);
    END get_service_inventory;

    PROCEDURE delete_service_inventory (
        p_service_id IN NUMBER,
        p_item_id IN NUMBER
    ) AS
    BEGIN
        DELETE FROM service_inventory WHERE service_id = p_service_id AND item_id = p_item_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20016, 'Error deleting service inventory: ' || SQLERRM);
    END delete_service_inventory;

END service_inventory_pkg;
/
-- procedure for search_service_by_type
CREATE OR REPLACE PROCEDURE search_service_by_type (
    p_type_name IN VARCHAR2
)
IS
    v_found BOOLEAN := FALSE;
BEGIN
    FOR rec IN (
        SELECT service_id, service_type, service_date, status, cost
        FROM service
        WHERE LOWER(service_type) LIKE '%' || LOWER(p_type_name) || '%'
    ) LOOP
        v_found := TRUE;
        DBMS_OUTPUT.PUT_LINE('ID: ' || rec.service_id || 
                             ', Type: ' || rec.service_type || 
                             ', Status: ' || rec.status || 
                             ', Cost: ' || rec.cost);
    END LOOP;

    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE('No services found for type: ' || p_type_name);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

---procedure for search_service_inventory_by_item_id
CREATE OR REPLACE PROCEDURE search_service_inventory_by_item_id (
    p_item_id IN VARCHAR2
)
IS
    v_found BOOLEAN := FALSE;
BEGIN
    FOR rec IN (
        SELECT service_id, item_id, quantity_used
        FROM service_inventory
        WHERE LOWER(item_id) LIKE '%' || LOWER(p_item_id) || '%'
    ) LOOP
        v_found := TRUE;
        DBMS_OUTPUT.PUT_LINE('Service ID: ' || rec.service_id ||
                             ', Item ID: ' || rec.item_id ||
                             ', Quantity Used: ' || rec.quantity_used);
    END LOOP;

    IF NOT v_found THEN
        DBMS_OUTPUT.PUT_LINE('No service inventory records found for item ID: ' || p_item_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/
-------------------------------------
---EXECUTION---
-------------------------------------
--execution add service

SET SERVEROUTPUT ON;

DECLARE
   v_service_id NUMBER;
BEGIN
   service_pkg.add_service(
      'Air filter change', 
      SYSDATE, 
      'pending', 
      120.00, 
      v_service_id 
   );

   DBMS_OUTPUT.PUT_LINE('Service added with ID: ' || v_service_id);
END;
/


--execution for get all services 
DECLARE
   v_service_id NUMBER;
   v_service_type VARCHAR2(100);
   v_service_date DATE;
   v_status VARCHAR2(50);
   v_cost NUMBER;
   v_cursor SYS_REFCURSOR;
BEGIN
   -- Call the procedure
   service_pkg.get_service(NULL, v_cursor, v_service_id);
   DBMS_OUTPUT.PUT_LINE('Services : ' || v_service_id);
   -- Loop through all services and fetch their details
   LOOP
      FETCH v_cursor INTO v_service_id, v_service_type, v_service_date, v_status, v_cost;
      EXIT WHEN v_cursor%NOTFOUND; 
      DBMS_OUTPUT.PUT_LINE('Service ID: ' || v_service_id);
      DBMS_OUTPUT.PUT_LINE('Service Type: ' || v_service_type);
      DBMS_OUTPUT.PUT_LINE('Service Date: ' || v_service_date);
      DBMS_OUTPUT.PUT_LINE('Status: ' || v_status);
      DBMS_OUTPUT.PUT_LINE('Cost: ' || v_cost);
   END LOOP;

   CLOSE v_cursor;
END;
/

----execution for update service 
DECLARE
   v_service_id_out NUMBER; 
BEGIN
   service_pkg.update_service(1030,'pending',80.00,v_service_id_out);
   DBMS_OUTPUT.PUT_LINE('Updated Service ID: ' || v_service_id_out);

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: while updating service ' || SQLERRM);  
END;
/


--execution for delete service 
DECLARE
   v_service_id_out NUMBER;
BEGIN
   service_pkg.delete_service(1024, v_service_id_out);
   DBMS_OUTPUT.PUT_LINE('Deleted Service ID: ' || v_service_id_out);

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error occurred while deleting service: ' || SQLERRM);  
END;
/

---execution for add inventory items
DECLARE
   v_item_id_out NUMBER;
BEGIN
   inventory_pkg.add_inventory_item('Wheel', 8, 100, v_item_id_out);
   DBMS_OUTPUT.PUT_LINE('Added Inventory Item ID: ' || v_item_id_out);

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error occured while add new inventory ' || SQLERRM);  
END;
/


--execution for get inventory
DECLARE
   v_cursor SYS_REFCURSOR;
   v_item_id   inventory.item_id%TYPE;
   v_item_name inventory.item_name%TYPE;
   v_quantity  inventory.quantity%TYPE;
   v_price     inventory.price_per_unit%TYPE;
BEGIN
   -- To retrieve all inventory items
   inventory_pkg.get_inventory(NULL, v_cursor);
   -- Fetch and display records
   LOOP
      FETCH v_cursor INTO v_item_id, v_item_name, v_quantity, v_price;
      EXIT WHEN v_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('Item ID: ' || v_item_id || 
                           ', Name: ' || v_item_name || 
                           ', Quantity: ' || v_quantity || 
                           ', Price/Unit: ' || v_price);
   END LOOP;
   CLOSE v_cursor;
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error occured while getting all inventory ' || SQLERRM);  
END;
/

--execution for update inventory
DECLARE
   v_item_id_out NUMBER;
BEGIN
   inventory_pkg.update_inventory(2010, 8, 120);
   v_item_id_out := 2003;
   DBMS_OUTPUT.PUT_LINE('Updated Inventory Item ID: ' || v_item_id_out);

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

--execution for delete inventory
DECLARE
   v_deleted_item_id NUMBER;
BEGIN
   inventory_pkg.delete_inventory(2061, v_deleted_item_id);
   DBMS_OUTPUT.PUT_LINE('Deleted Inventory Item ID: ' || v_deleted_item_id);

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error occured while deleteing inventory ' || SQLERRM);
END;
/


--execution for use inventory 
DECLARE
   v_service_id     NUMBER := 1001;   
   v_item_id        NUMBER := 2001; 
   v_quantity_used  NUMBER := 4;      
BEGIN
   -- Call the use_inventory procedure
   service_inventory_pkg.use_inventory(v_service_id, v_item_id, v_quantity_used);

   -- Optional: Output a confirmation message
   DBMS_OUTPUT.PUT_LINE('Inventory usage recorded: Service ID = ' ||
                        v_service_id || ', Item ID = ' ||
                        v_item_id || ', Quantity Used = ' ||
                        v_quantity_used);
EXCEPTION
   WHEN OTHERS THEN
      -- Handle exceptions by outputting the error message
      DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/


--execution for get service inventory
SET SERVEROUTPUT ON;

DECLARE
    v_service_id NUMBER := 1003; 
    v_cursor SYS_REFCURSOR;
    v_service_id_out NUMBER;
    v_item_id NUMBER;
    v_quantity_used NUMBER;
BEGIN
    -- Call the get_service_inventory procedure
    service_inventory_pkg.get_service_inventory(p_service_id => v_service_id, p_cursor => v_cursor);

    -- Loop through the cursor and display the results
    LOOP
        FETCH v_cursor INTO v_service_id_out, v_item_id, v_quantity_used;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Service ID: ' || v_service_id_out || 
                             ', Item ID: ' || v_item_id || 
                             ', Quantity Used: ' || v_quantity_used);
    END LOOP;

    -- Close the cursor
    CLOSE v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

--execution for delete_service_inventory
DECLARE
    -- Declare variables for service_id and item_id
    v_service_id   NUMBER := 1001;  
    v_item_id      NUMBER := 2001;  
BEGIN
    -- Call the delete_service_inventory procedure
    service_inventory_pkg.delete_service_inventory(p_service_id => v_service_id, p_item_id => v_item_id);

    -- Output a confirmation message
    DBMS_OUTPUT.PUT_LINE('Service inventory record deleted successfully for Service ID: ' || v_service_id || ' and Item ID: ' || v_item_id);
EXCEPTION
    WHEN OTHERS THEN
        -- Handle exceptions by outputting the error message
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/
 --execution for search_service_by_type

BEGIN
    search_service_by_type('oil'); 
END;
/

BEGIN
    search_service_by_type('OIL'); 
END;
/

BEGIN
    search_service_by_type('Wh'); 
END;
/
--execution for search_service_inventory_by_item_id
BEGIN
    search_service_inventory_by_item_id('2002');
END;
===================================================


--procedure for customer search by partial name
CREATE OR REPLACE PROCEDURE customer_search_by_partial_name (
    p_partial_name IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT cust_id, cust_name, phone, email, address
        FROM CUSTOMER
        WHERE UPPER(cust_name) LIKE UPPER('%' || TRIM(p_partial_name) || '%');
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error searching customers by name: ' || SQLERRM);
END customer_search_by_partial_name;
/

-- Test the procedure
SET SERVEROUTPUT ON;
DECLARE
    v_cursor SYS_REFCURSOR;
    v_cust_id NUMBER;
    v_cust_name VARCHAR2(100);
    v_phone VARCHAR2(20);
    v_email VARCHAR2(100);
    v_address VARCHAR2(200);
BEGIN
    customer_search_by_partial_name('test', v_cursor);
    LOOP
        FETCH v_cursor INTO v_cust_id, v_cust_name, v_phone, v_email, v_address;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_cust_id || ', Name: ' || v_cust_name || ', Email: ' || v_email);
    END LOOP;
    CLOSE v_cursor;
END;
/


--procedure for customer search by email
CREATE OR REPLACE PROCEDURE customer_search_by_email (
    p_email IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT cust_id, cust_name, phone, email, address
        FROM CUSTOMER
        WHERE UPPER(email) = UPPER(TRIM(p_email));
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error searching customer by email: ' || SQLERRM);
END customer_search_by_email;
/


-- Procedure for vehicle search by customer ID
CREATE OR REPLACE PROCEDURE vehicle_search_by_cust_id (
    p_cust_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT vehicle_id, cust_id, licence_plate, make, model, year
        FROM VEHICLE
        WHERE cust_id = p_cust_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error searching vehicles by customer ID: ' || SQLERRM);
END vehicle_search_by_cust_id;
/


-- Procedure for employee search by partial name
CREATE OR REPLACE PROCEDURE employee_search_by_partial_name (
    p_partial_name IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked
        FROM EMPLOYEE
        WHERE UPPER(emp_name) LIKE UPPER('%' || TRIM(p_partial_name) || '%');
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Error searching employees by name: ' || SQLERRM);
END employee_search_by_partial_name;
/


-- Procedure for employee search by position
CREATE OR REPLACE PROCEDURE employee_search_by_position (
    p_position IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked
        FROM EMPLOYEE
        WHERE UPPER(position) = UPPER(TRIM(p_position));
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20005, 'Error searching employees by position: ' || SQLERRM);
END employee_search_by_position;
/


-- Procedure for appointment search by vehicle ID
CREATE OR REPLACE PROCEDURE appointment_search_by_vehicle_id (
    p_vehicle_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id
        FROM APPOINTMENT
        WHERE vehicle_id = p_vehicle_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error searching appointments by vehicle ID: ' || SQLERRM);
END appointment_search_by_vehicle_id;
/

-- Procedure for appointment search by customer ID
CREATE OR REPLACE PROCEDURE appointment_search_by_cust_id (
    p_cust_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id
        FROM APPOINTMENT
        WHERE cust_id = p_cust_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20007, 'Error searching appointments by customer ID: ' || SQLERRM);
END appointment_search_by_cust_id;
/

--genrate invoices
CREATE OR REPLACE PROCEDURE generate_invoice (
    p_app_id IN NUMBER,
    p_description IN VARCHAR2,
    p_total_amount IN NUMBER,
    p_invoice_id OUT NUMBER,
    p_invoice_date OUT DATE,
    p_total_amount_out OUT NUMBER,
    p_cust_name OUT VARCHAR2,
    p_address OUT VARCHAR2,
    p_email OUT VARCHAR2,
    p_contact OUT VARCHAR2,
    p_licence_plate OUT VARCHAR2,
    p_description_out OUT VARCHAR2
) AS
BEGIN
    -- Validate inputs
    IF p_app_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Appointment ID cannot be null.');
    END IF;

    IF p_description IS NULL OR LENGTH(TRIM(p_description)) = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Description cannot be null or empty.');
    END IF;

    IF p_total_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Total amount must be greater than zero.');
    END IF;

    -- Fetch invoice, customer, and vehicle details using app_id
    SELECT 
        i.invoice_id,
        i.invoice_date,
        c.cust_name,
        c.address,
        c.email,
        c.phone,
        v.licence_plate
    INTO 
        p_invoice_id,
        p_invoice_date,
        p_cust_name,
        p_address,
        p_email,
        p_contact,
        p_licence_plate
    FROM INVOICE i
    JOIN APPOINTMENT a ON i.app_id = a.app_id
    JOIN CUSTOMER c ON a.cust_id = c.cust_id
    JOIN VEHICLE v ON a.vehicle_id = v.vehicle_id
    WHERE a.app_id = p_app_id;

    -- Set the total_amount_out to the input total_amount
    p_total_amount_out := p_total_amount;

    -- Set the description
    p_description_out := p_description;

    -- Output success message
    DBMS_OUTPUT.PUT_LINE('Invoice details retrieved successfully for Appointment ID: ' || p_app_id);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'No invoice found for Appointment ID: ' || p_app_id);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error in generate_invoice for Appointment ID ' || p_app_id || ': ' || SQLERRM);
END generate_invoice;
/

--Execution of generate_invoice procedure
-- This block demonstrates how to call the generate_invoice procedure and display the results.
SET SERVEROUTPUT ON;

DECLARE
    v_invoice_id NUMBER;
    v_invoice_date DATE;
    v_total_amount NUMBER;
    v_cust_name VARCHAR2(50);
    v_address VARCHAR2(255);
    v_email VARCHAR2(50);
    v_contact VARCHAR2(13);
    v_licence_plate VARCHAR2(20);
    v_description VARCHAR2(250);
BEGIN
    -- Call the procedure
    generate_invoice(
        p_app_id => 9004,
        p_description => 'Website Development',
        p_total_amount => 25000.00,
        p_invoice_id => v_invoice_id,
        p_invoice_date => v_invoice_date,
        p_total_amount_out => v_total_amount,
        p_cust_name => v_cust_name,
        p_address => v_address,
        p_email => v_email,
        p_contact => v_contact,
        p_licence_plate => v_licence_plate,
        p_description_out => v_description
    );

    -- Display the results
    DBMS_OUTPUT.PUT_LINE('Invoice ID: ' || v_invoice_id);
    DBMS_OUTPUT.PUT_LINE('Invoice Date: ' || TO_CHAR(v_invoice_date, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('Total Amount: ' || v_total_amount);
    DBMS_OUTPUT.PUT_LINE('Customer Name: ' || v_cust_name);
    DBMS_OUTPUT.PUT_LINE('Address: ' || v_address);
    DBMS_OUTPUT.PUT_LINE('Email: ' || v_email);
    DBMS_OUTPUT.PUT_LINE('Contact: ' || v_contact);
    DBMS_OUTPUT.PUT_LINE('Licence Plate: ' || v_licence_plate);
    DBMS_OUTPUT.PUT_LINE('Description: ' || v_description);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/


CREATE OR REPLACE PROCEDURE customer_search_by_partial_name (
    p_partial_name IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT cust_id, cust_name, phone, email, address
        FROM CUSTOMER
        WHERE UPPER(cust_name) LIKE UPPER('%' || TRIM(p_partial_name) || '%');
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error searching customers by name: ' || SQLERRM);
END customer_search_by_partial_name;
/

SET SERVEROUTPUT ON;
DECLARE
    v_cursor SYS_REFCURSOR;
    v_cust_id NUMBER;
    v_cust_name VARCHAR2(100);
    v_phone VARCHAR2(20);
    v_email VARCHAR2(100);
    v_address VARCHAR2(200);
BEGIN
    customer_search_by_partial_name('te', v_cursor);
    LOOP
        FETCH v_cursor INTO v_cust_id, v_cust_name, v_phone, v_email, v_address;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_cust_id || ', Name: ' || v_cust_name || ', Email: ' || v_email || ', Address: ' || v_address);
    END LOOP;
    CLOSE v_cursor;
END;
/


CREATE OR REPLACE PROCEDURE customer_search_by_email (
    p_email IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT cust_id, cust_name, phone, email, address
        FROM CUSTOMER
        WHERE UPPER(email) = UPPER(TRIM(p_email));
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error searching customer by email: ' || SQLERRM);
END customer_search_by_email;
/


CREATE OR REPLACE PROCEDURE vehicle_search_by_cust_id (
    p_cust_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT vehicle_id, cust_id, licence_plate, make, model, year
        FROM VEHICLE
        WHERE cust_id = p_cust_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error searching vehicles by customer ID: ' || SQLERRM);
END vehicle_search_by_cust_id;
/



CREATE OR REPLACE PROCEDURE employee_search_by_partial_name (
    p_partial_name IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked
        FROM EMPLOYEE
        WHERE UPPER(emp_name) LIKE UPPER('%' || TRIM(p_partial_name) || '%');
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Error searching employees by name: ' || SQLERRM);
END employee_search_by_partial_name;
/



CREATE OR REPLACE PROCEDURE employee_search_by_position (
    p_position IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked
        FROM EMPLOYEE
        WHERE UPPER(position) = UPPER(TRIM(p_position));
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20005, 'Error searching employees by position: ' || SQLERRM);
END employee_search_by_position;
/



CREATE OR REPLACE PROCEDURE appointment_search_by_vehicle_id (
    p_vehicle_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id
        FROM APPOINTMENT
        WHERE vehicle_id = p_vehicle_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Error searching appointments by vehicle ID: ' || SQLERRM);
END appointment_search_by_vehicle_id;
/


CREATE OR REPLACE PROCEDURE appointment_search_by_cust_id (
    p_cust_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id
        FROM APPOINTMENT
        WHERE cust_id = p_cust_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20007, 'Error searching appointments by customer ID: ' || SQLERRM);
END appointment_search_by_cust_id;
/


--Remove Employee (With Appointment Check)
CREATE OR REPLACE PROCEDURE employee_remove (
    p_emp_id IN NUMBER
) AS
    v_pending_count NUMBER;
    v_total_count NUMBER;
BEGIN
    -- Check for pending appointments (status not 'Completed')
    SELECT COUNT(*)
    INTO v_pending_count
    FROM APPOINTMENT
    WHERE emp_id = p_emp_id
    AND UPPER(status) != 'COMPLETED';

    -- Check for total appointments (including completed)
    SELECT COUNT(*)
    INTO v_total_count
    FROM APPOINTMENT
    WHERE emp_id = p_emp_id;

    IF v_pending_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Cannot remove employee: They have ' || v_pending_count || ' pending appointments.');
    ELSE
        -- Delete all appointments (pending or completed) for the employee
        DELETE FROM APPOINTMENT
        WHERE emp_id = p_emp_id;

        DBMS_OUTPUT.PUT_LINE('Deleted ' || SQL%ROWCOUNT || ' appointment(s) for employee ID ' || p_emp_id);

        -- Now delete the employee
        DELETE FROM EMPLOYEE
        WHERE emp_id = p_emp_id;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20009, 'Employee with ID ' || p_emp_id || ' not found.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Employee with ID ' || p_emp_id || ' successfully removed.');
            COMMIT;
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Error removing employee: ' || SQLERRM);
END employee_remove;
/


SET SERVEROUTPUT ON;
BEGIN
    employee_remove(8); -- Replace with an existing emp_id
END;
/


CREATE OR REPLACE PROCEDURE search_service_by_type (
    p_service_type IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT service_id, service_type, service_date, status, cost
        FROM Service
        WHERE UPPER(service_type) = UPPER(TRIM(p_service_type));

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20007, 'Error searching service by type: ' || SQLERRM);
END search_service_by_type;
/



SET SERVEROUTPUT ON;
DECLARE
    v_cursor SYS_REFCURSOR;
    v_service_id NUMBER;
    v_service_type VARCHAR2(100);
    v_service_date DATE;
    v_status VARCHAR2(100);
    v_cost NUMBER;
BEGIN
    -- Call the procedure to search for services with type 'Oil Change'
    search_service_by_type(p_service_type => 'Oil Change', p_cursor => v_cursor);

    -- Fetch and display the results
    DBMS_OUTPUT.PUT_LINE('Services with Type "Oil Change":');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Service ID | Service Type | Service Date | Status | Cost');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    LOOP
        FETCH v_cursor
        INTO v_service_id, v_service_type, v_service_date, v_status, v_cost;

        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            v_service_id || ' | ' ||
            v_service_type || ' | ' ||
            TO_CHAR(v_service_date, 'YYYY-MM-DD') || ' | ' ||
            v_status || ' | ' ||
            v_cost
        );
    END LOOP;

    -- Close the cursor
    CLOSE v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        -- Ensure the cursor is closed even if an error occurs
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/


CREATE OR REPLACE PROCEDURE get_all_invoices (
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    -- Open the cursor to select relevant columns from the INVOICE table
    OPEN p_cursor FOR
        SELECT invoice_id, service_id, app_id, invoice_date, total_amount
        FROM INVOICE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Error retrieving all invoices: ' || SQLERRM);
END get_all_invoices;
/

SET SERVEROUTPUT ON;
DECLARE
    v_cursor SYS_REFCURSOR;
    v_invoice_id NUMBER;
    v_service_id NUMBER;
    v_app_id NUMBER;
    v_invoice_date DATE;
    v_total_amount NUMBER;
BEGIN
    -- Call the procedure to get all invoices
    get_all_invoices(p_cursor => v_cursor);

    -- Fetch and display the results
    DBMS_OUTPUT.PUT_LINE('All Invoices:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Invoice ID | Service ID | App ID | Invoice Date | Total Amount');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    LOOP
        FETCH v_cursor
        INTO v_invoice_id, v_service_id, v_app_id, v_invoice_date, v_total_amount;

        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            v_invoice_id || ' | ' ||
            v_service_id || ' | ' ||
            v_app_id || ' | ' ||
            TO_CHAR(v_invoice_date, 'YYYY-MM-DD') || ' | ' ||
            v_total_amount
        );
    END LOOP;

    -- Close the cursor
    CLOSE v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        -- Ensure the cursor is closed even if an error occurs
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/

CREATE OR REPLACE PROCEDURE get_all_service_inventory (
    p_item_id IN NUMBER DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    -- Open the cursor to select all columns from the service_inventory table
    OPEN p_cursor FOR
        SELECT service_id, item_id, quantity_used
        FROM service_inventory
        WHERE (p_item_id IS NULL OR item_id = p_item_id);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'Error retrieving all service inventory: ' || SQLERRM);
END get_all_service_inventory;
/


SET SERVEROUTPUT ON;
DECLARE
    v_cursor SYS_REFCURSOR;
    v_service_id NUMBER;
    v_item_id NUMBER;
    v_quantity_used NUMBER;
BEGIN
    -- Call the procedure to get all service inventory records
    get_all_service_inventory(p_item_id => NULL, p_cursor => v_cursor);

    -- Fetch and display the results
    DBMS_OUTPUT.PUT_LINE('All Service Inventory:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Service ID | Item ID | Quantity Used');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    LOOP
        FETCH v_cursor
        INTO v_service_id, v_item_id, v_quantity_used;

        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            v_service_id || ' | ' ||
            v_item_id || ' | ' ||
            v_quantity_used
        );
    END LOOP;

    -- Close the cursor
    CLOSE v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        -- Ensure the cursor is closed even if an error occurs
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/

CREATE OR REPLACE PROCEDURE search_service_inventory_by_item_id (
    p_item_id IN NUMBER DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    -- Open the cursor to select all columns from the service_inventory table
    OPEN p_cursor FOR
        SELECT service_id, item_id, quantity_used
        FROM service_inventory
        WHERE (p_item_id IS NULL OR item_id = p_item_id);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'Error searching service inventory by item ID: ' || SQLERRM);
END search_service_inventory_by_item_id;
/


SET SERVEROUTPUT ON;
DECLARE
    v_cursor SYS_REFCURSOR;
    v_service_id NUMBER;
    v_item_id NUMBER;
    v_quantity_used NUMBER;
BEGIN
    -- Call the procedure to search service inventory records for item_id = 2001
    search_service_inventory_by_item_id(p_item_id => 2002, p_cursor => v_cursor);

    -- Fetch and display the results
    DBMS_OUTPUT.PUT_LINE('Service Inventory for Item ID 2002:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Service ID | Item ID | Quantity Used');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    LOOP
        FETCH v_cursor
        INTO v_service_id, v_item_id, v_quantity_used;

        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            v_service_id || ' | ' ||
            v_item_id || ' | ' ||
            v_quantity_used
        );
    END LOOP;

    -- Close the cursor
    CLOSE v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        -- Ensure the cursor is closed even if an error occurs
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/



CREATE OR REPLACE PROCEDURE get_todays_appointments (
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    -- Open the cursor to select appointments for today using SYSDATE
    OPEN p_cursor FOR
        SELECT app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id
        FROM APPOINTMENT
        WHERE TRUNC(app_date) = TRUNC(SYSDATE) -- Dynamically get today's date
        ORDER BY app_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20011, 'Error retrieving today''s appointments: ' || SQLERRM);
END get_todays_appointments;
/



SET SERVEROUTPUT ON;
DECLARE
    v_cursor SYS_REFCURSOR;
    v_app_id NUMBER;
    v_cust_id NUMBER;
    v_vehicle_id NUMBER;
    v_app_date DATE;
    v_app_time TIMESTAMP;
    v_status VARCHAR2(50);
    v_service_id NUMBER;
    v_emp_id NUMBER;
BEGIN
    -- Call the procedure to get today's appointments
    get_todays_appointments(p_cursor => v_cursor);

    -- Fetch and display the results
    DBMS_OUTPUT.PUT_LINE('Today''s Appointments:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('App ID | Cust ID | Vehicle ID | App Date | App Time | Status | Service ID | Emp ID');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    LOOP
        FETCH v_cursor
        INTO v_app_id, v_cust_id, v_vehicle_id, v_app_date, v_app_time, v_status, v_service_id, v_emp_id;

        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            v_app_id || ' | ' ||
            v_cust_id || ' | ' ||
            v_vehicle_id || ' | ' ||
            TO_CHAR(v_app_date, 'YYYY-MM-DD') || ' | ' ||
            TO_CHAR(v_app_time, 'HH24:MI:SS') || ' | ' ||
            v_status || ' | ' ||
            v_service_id || ' | ' ||
            v_emp_id
        );
    END LOOP;

    -- Close the cursor
    CLOSE v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/

CREATE OR REPLACE PROCEDURE get_inventory_alerts (
    p_cursor OUT SYS_REFCURSOR
) AS
    v_threshold NUMBER := 10;
BEGIN
    -- Open the cursor to select inventory items below threshold
    OPEN p_cursor FOR
        SELECT i.item_id, i.item_name, i.quantity, i.price_per_unit, si.service_id, si.quantity_used
        FROM inventory i
        LEFT JOIN service_inventory si ON i.item_id = si.item_id
        WHERE i.quantity < v_threshold
        ORDER BY i.item_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20012, 'Error retrieving inventory alerts: ' || SQLERRM);
END get_inventory_alerts;
/

SET SERVEROUTPUT ON;

DECLARE
    v_cursor SYS_REFCURSOR;
    v_item_id NUMBER;
    v_item_name VARCHAR2(100);
    v_quantity NUMBER;
    v_price_per_unit NUMBER;
    v_service_id NUMBER;
    v_quantity_used NUMBER;
BEGIN
    -- Call the procedure to get inventory alerts
    get_inventory_alerts(p_cursor => v_cursor);

    -- Fetch and display the results
    DBMS_OUTPUT.PUT_LINE('Inventory Alerts:');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Item ID | Item Name | Quantity | Price/Unit | Service ID | Quantity Used');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    LOOP
        FETCH v_cursor
        INTO v_item_id, v_item_name, v_quantity, v_price_per_unit, v_service_id, v_quantity_used;

        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            v_item_id || ' | ' ||
            v_item_name || ' | ' ||
            v_quantity || ' | ' ||
            v_price_per_unit || ' | ' ||
            NVL(TO_CHAR(v_service_id), 'N/A') || ' | ' ||
            NVL(TO_CHAR(v_quantity_used), 'N/A')
        );
    END LOOP;

    -- Close the cursor
    CLOSE v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/