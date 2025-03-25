SET SERVEROUTPUT ON;

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

-- CUSTOMER Procedures 
CREATE OR REPLACE PACKAGE customer_procedures AS
    PROCEDURE add_customer(p_cust_name IN VARCHAR2, p_phone IN VARCHAR2, p_email IN VARCHAR2, p_address IN VARCHAR2);
    PROCEDURE get_customer(p_cust_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_customer(p_cust_id IN NUMBER, p_cust_name IN VARCHAR2, p_phone IN VARCHAR2, p_email IN VARCHAR2, p_address IN VARCHAR2);
    PROCEDURE delete_customer(p_cust_id IN NUMBER);
END customer_procedures;
/

CREATE OR REPLACE PACKAGE BODY customer_procedures AS
    PROCEDURE add_customer(p_cust_name IN VARCHAR2, p_phone IN VARCHAR2, p_email IN VARCHAR2, p_address IN VARCHAR2) IS
    BEGIN
        INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address)
        VALUES (customer_seq.NEXTVAL, p_cust_name, p_phone, p_email, p_address);
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

    PROCEDURE update_customer(p_cust_id IN NUMBER, p_cust_name IN VARCHAR2, p_phone IN VARCHAR2, p_email IN VARCHAR2, p_address IN VARCHAR2) IS
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
END customer_procedures;
/

-- Add a new customer
SET SERVEROUTPUT ON;
EXEC customer_procedures.add_customer('Khush Santoki', '9865321470', 'Khush@example.com', '123 vadnagar Street');

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


-- VEHICLE Procedures 
CREATE OR REPLACE PACKAGE vehicle_procedures AS
    PROCEDURE add_vehicle(p_cust_id IN NUMBER, p_licence_plate IN VARCHAR2, p_make IN VARCHAR2, p_model IN VARCHAR2, p_year IN NUMBER);
    PROCEDURE get_vehicle(p_vehicle_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_vehicle(p_vehicle_id IN NUMBER, p_licence_plate IN VARCHAR2, p_make IN VARCHAR2, p_model IN VARCHAR2, p_year IN NUMBER);
    PROCEDURE delete_vehicle(p_vehicle_id IN NUMBER);
END vehicle_procedures;
/



CREATE OR REPLACE PACKAGE BODY vehicle_procedures AS
    PROCEDURE add_vehicle(p_cust_id IN NUMBER, p_licence_plate IN VARCHAR2, p_make IN VARCHAR2, p_model IN VARCHAR2, p_year IN NUMBER) IS
    BEGIN
        INSERT INTO VEHICLE (Vehicle_id, cust_id, Licence_plate, Make, Model, Year)
        VALUES (vehicle_seq.NEXTVAL, p_cust_id, p_licence_plate, p_make, p_model, p_year);
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


-- Add a new vehicle
EXEC vehicle_procedures.add_vehicle(4, 'ABC123', 'Toyota', 'Camry', 2022);

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
    PROCEDURE schedule_appointment(p_cust_id IN NUMBER, p_vehicle_id IN NUMBER, p_app_date IN DATE, p_app_time IN TIMESTAMP, p_status IN VARCHAR2, p_service_id IN NUMBER, p_emp_id IN NUMBER);
    PROCEDURE get_appointment(p_app_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_appointment_status(p_app_id IN NUMBER, p_status IN VARCHAR2);
    PROCEDURE delete_appointment(p_app_id IN NUMBER);
END appointment_procedures;
/

CREATE OR REPLACE PACKAGE BODY appointment_procedures AS
    PROCEDURE schedule_appointment(p_cust_id IN NUMBER, p_vehicle_id IN NUMBER, p_app_date IN DATE, p_app_time IN TIMESTAMP, p_status IN VARCHAR2, p_service_id IN NUMBER, p_emp_id IN NUMBER) IS
    BEGIN
        INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id)
        VALUES (appointment_seq.NEXTVAL, p_cust_id, p_vehicle_id, p_app_date, p_app_time, p_status, p_service_id, p_emp_id);
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

-- Schedule a new appointment
EXEC appointment_procedures.schedule_appointment(1, 1, TO_DATE('23-10-01', 'YYYY-MM-DD'), TO_TIMESTAMP('11:30:00', 'HH24:MI:SS'), 'Scheduled', 1, 1);

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



-- EMPLOYEE Procedures 
CREATE OR REPLACE PACKAGE employee_procedures AS
    PROCEDURE add_employee(p_emp_name IN VARCHAR2, p_position IN VARCHAR2, p_emp_phn IN VARCHAR2, p_email IN VARCHAR2, p_salary IN NUMBER, p_hire_date IN DATE, p_hours_worked IN NUMBER);
    PROCEDURE get_employee(p_emp_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_employee(p_emp_id IN NUMBER, p_emp_name IN VARCHAR2, p_position IN VARCHAR2, p_emp_phn IN VARCHAR2, p_email IN VARCHAR2, p_salary IN NUMBER, p_hire_date IN DATE, p_hours_worked IN NUMBER);
    PROCEDURE delete_employee(p_emp_id IN NUMBER);
END employee_procedures;
/

CREATE OR REPLACE PACKAGE BODY employee_procedures AS
    PROCEDURE add_employee(p_emp_name IN VARCHAR2, p_position IN VARCHAR2, p_emp_phn IN VARCHAR2, p_email IN VARCHAR2, p_salary IN NUMBER, p_hire_date IN DATE, p_hours_worked IN NUMBER) IS
    BEGIN
        INSERT INTO EMPLOYEE (emp_id, emp_name, position, emp_phn, email, salary, hire_date, hours_worked)
        VALUES (employee_seq.NEXTVAL, p_emp_name, p_position, p_emp_phn, p_email, p_salary, p_hire_date, p_hours_worked);
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
EXEC employee_procedures.add_employee('Alice Johnson', 'Manager', '1928374650', 'alice@example.com', 60000.00, TO_DATE('2018-03-25', 'YYYY-MM-DD'), 45.75);

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




--INVOICE PROCEDURES
--Package Specification
CREATE OR REPLACE PACKAGE invoice_pkg AS
    -- Procedure to generate an invoice
    PROCEDURE generate_invoice (
        p_invoice_id IN NUMBER,
        p_service_id IN NUMBER,
        p_app_id IN NUMBER,
        p_total_amount IN NUMBER
    );

    -- Procedure to get invoice details by ID
    PROCEDURE get_invoice_by_id (
        p_invoice_id IN NUMBER
    );
END invoice_pkg;
/

--Package Body
CREATE OR REPLACE PACKAGE BODY invoice_pkg AS

    -- Generate an invoice for an appointment
    PROCEDURE generate_invoice (
        p_invoice_id IN NUMBER,
        p_service_id IN NUMBER,
        p_app_id IN NUMBER,
        p_total_amount IN NUMBER
    ) AS
    BEGIN
        -- Insert a new invoice into the INVOICE table
        INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount, created_at)
        VALUES (p_invoice_id, p_service_id, p_app_id, SYSDATE, p_total_amount, SYSTIMESTAMP);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Invoice generated successfully. Invoice ID: ' || p_invoice_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error while generating invoice: ' || SQLERRM);
    END generate_invoice;

    -- Retrieve invoice details by invoice ID
    PROCEDURE get_invoice_by_id (
        p_invoice_id IN NUMBER
    ) AS
        v_service_id NUMBER;
        v_app_id NUMBER;
        v_invoice_date DATE;
        v_total_amount NUMBER;
        v_created_at TIMESTAMP;
    BEGIN
        -- Retrieve invoice details
        SELECT service_id, app_id, invoice_date, total_amount, created_at
        INTO v_service_id, v_app_id, v_invoice_date, v_total_amount, v_created_at
        FROM INVOICE
        WHERE invoice_id = p_invoice_id;

        -- Output the invoice details
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

--Calling the generate_invoice procedure
BEGIN
    invoice_pkg.generate_invoice(5, 5, 5, 250.00);
END;
/

--Calling the get_invoice_by_id procedure
BEGIN
    invoice_pkg.get_invoice_by_id(1);
END;
/


--PAYMENT PROCEDURES
--PACKAGE SPECIFICATION
CREATE OR REPLACE PACKAGE payment_pkg AS
    PROCEDURE record_payment (
        p_payment_id IN NUMBER,
        p_invoice_id IN NUMBER,
        p_amount_paid IN NUMBER,
        p_payment_method IN VARCHAR2,
        p_status IN VARCHAR2
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
--PACKAGE BODY
CREATE OR REPLACE PACKAGE BODY payment_pkg AS

    -- Record Payment Procedure
    PROCEDURE record_payment (
        p_payment_id IN NUMBER,
        p_invoice_id IN NUMBER,
        p_amount_paid IN NUMBER,
        p_payment_method IN VARCHAR2,
        p_status IN VARCHAR2
    ) AS
    BEGIN
        -- Insert payment into PAYMENT table
        INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, status)
        VALUES (p_payment_id, p_invoice_id, SYSDATE, p_amount_paid, p_payment_method, p_status);

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Payment recorded successfully. Payment ID: ' || p_payment_id);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: Invoice not found.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error while recording payment: ' || SQLERRM);
    END record_payment;


    -- Get Payment Details Procedure
    PROCEDURE get_payment_by_id (
        p_payment_id IN NUMBER
    ) AS
        v_invoice_id NUMBER;
        v_payment_date DATE;
        v_amount_paid NUMBER(10,2);
        v_payment_method VARCHAR2(50);
        v_status VARCHAR2(20);
    BEGIN
        -- Retrieve payment details
        SELECT invoice_id, payment_date, amount_paid, payment_method, status
        INTO v_invoice_id, v_payment_date, v_amount_paid, v_payment_method, v_status
        FROM PAYMENT
        WHERE payment_id = p_payment_id;

        -- Display payment details
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


    -- Update Payment Status Procedure
    PROCEDURE update_payment_status (
        p_payment_id IN NUMBER,
        p_new_status IN VARCHAR2
    ) AS
        v_count NUMBER;
    BEGIN
        -- Check if payment exists
        SELECT COUNT(*) INTO v_count FROM PAYMENT WHERE payment_id = p_payment_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error: Payment ID does not exist.');
        END IF;

        -- Update status
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
--Record a Payment (EXECUTION)
BEGIN
    payment_pkg.record_payment(3, 2, 500, 'Credit Card', 'Pending');
END;
/

-- Get Payment by ID(EXECUTION)
BEGIN
    payment_pkg.get_payment_by_id(2);
END;
/
--Update Payment Status(EXEXCUTION)
BEGIN
    payment_pkg.update_payment_status(1, 'Successful');
END;
/

---

SET SERVEROUTPUT ON;
---- SERVICE Table Procedures for add_service
CREATE OR REPLACE PROCEDURE add_service (
    p_service_type IN VARCHAR2,
    p_service_date IN DATE,
    p_status IN VARCHAR2,
    p_cost IN NUMBER
) AS
BEGIN
    INSERT INTO Service (service_id, service_type, service_date, status, cost)
    VALUES (service_seq.NEXTVAL, p_service_type, p_service_date, p_status, p_cost);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Error adding service: ' || SQLERRM);
END add_service;
/

---execution for service table procedure for add_service
BEGIN
    add_service('Engine Tune-Up', TO_DATE('2025-03-20', 'YYYY-MM-DD'), 'Pending', 150.00);
END;
/

select * from service 

------ SERVICE Table Procedures for get service

CREATE OR REPLACE PROCEDURE get_service (
    p_service_id IN NUMBER DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    IF p_service_id IS NULL THEN
        OPEN p_cursor FOR
            SELECT * FROM Service;
    ELSE
        OPEN p_cursor FOR
            SELECT * FROM Service WHERE service_id = p_service_id;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error retrieving service: ' || SQLERRM);
END get_service;
/


--execution for get all services 
DECLARE
    l_cursor SYS_REFCURSOR;
    l_service_id NUMBER;
    l_service_type VARCHAR2(100);
    l_service_date DATE;
    l_status VARCHAR2(100);
    l_cost NUMBER(10,2);
BEGIN
    get_service(NULL, l_cursor);
    LOOP
        FETCH l_cursor INTO l_service_id, l_service_type, l_service_date, l_status, l_cost;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || l_service_id || ', Type: ' || l_service_type || 
                            ', Date: ' || TO_CHAR(l_service_date, 'YYYY-MM-DD') || 
                            ', Status: ' || l_status || ', Cost: ' || l_cost);
    END LOOP;
    CLOSE l_cursor;
END;
/


------ SERVICE Table Procedures for update service 
CREATE OR REPLACE PROCEDURE update_service (
    p_service_id IN NUMBER,
    p_status IN VARCHAR2,
    p_cost IN NUMBER
) AS
BEGIN
    UPDATE Service
    SET status = p_status,
        cost = p_cost
    WHERE service_id = p_service_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Service ID not found');
    END IF;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'Error updating service: ' || SQLERRM);
END update_service;
/

---execution for update service 
BEGIN
    update_service(1, 'Completed', 55.00); 
END;
/

select * from service 


------ SERVICE Table Procedures for delete service 
CREATE OR REPLACE PROCEDURE delete_service (
    p_service_id IN NUMBER
) AS
BEGIN
    DELETE FROM service_inventory WHERE service_id = p_service_id;
    DELETE FROM Service WHERE service_id = p_service_id;
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Service ID not found');
    END IF;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006, 'Error deleting service: ' || SQLERRM);
END delete_service;
/


--execution for delete service 
BEGIN
    delete_service(1); 
END;
/

SELECT * FROM Service WHERE service_id = 1;
SELECT * FROM service_inventory WHERE service_id = 1; 


---- INVENTORY Table Procedures for add_inventory_item 
CREATE OR REPLACE PROCEDURE add_inventory_item (
    p_item_name IN VARCHAR2,
    p_quantity IN NUMBER,
    p_price_per_unit IN NUMBER
) AS
BEGIN
    INSERT INTO inventory (item_id, item_name, quantity, price_per_unit)
    VALUES (inventory_seq.NEXTVAL, p_item_name, p_quantity, p_price_per_unit);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'Error adding inventory item: ' || SQLERRM);
END add_inventory_item;
/


----Executions add_inventory_item
BEGIN
    add_inventory_item('Air Filter', 20, 25.00);
END;
/

select * from Inventory

--- INVENTORY Table Procedures for get_inventory 
CREATE OR REPLACE PROCEDURE get_inventory (
    p_item_id IN NUMBER DEFAULT NULL,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    IF p_item_id IS NULL THEN
        OPEN p_cursor FOR
            SELECT * FROM inventory;
    ELSE
        OPEN p_cursor FOR
            SELECT * FROM inventory WHERE item_id = p_item_id;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Error retrieving inventory: ' || SQLERRM);
END get_inventory;
/


--execution get_inventory 
DECLARE
    l_cursor SYS_REFCURSOR;
    l_item_id NUMBER;
    l_item_name VARCHAR2(100);
    l_quantity NUMBER;
    l_price_per_unit NUMBER(10,2);
BEGIN
    get_inventory(NULL, l_cursor);
    LOOP
        FETCH l_cursor INTO l_item_id, l_item_name, l_quantity, l_price_per_unit;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || l_item_id || ', Name: ' || l_item_name || 
                            ', Quantity: ' || l_quantity || ', Price: ' || l_price_per_unit);
    END LOOP;
    CLOSE l_cursor;
END;
/


--- INVENTORY Table Procedures for update_inventory 
CREATE OR REPLACE PROCEDURE update_inventory (
    p_item_id IN NUMBER,
    p_quantity IN NUMBER,
    p_price_per_unit IN NUMBER
) AS
BEGIN
    UPDATE inventory
    SET quantity = p_quantity,
        price_per_unit = p_price_per_unit
    WHERE item_id = p_item_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20009, 'Inventory item ID not found');
    END IF;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, 'Error updating inventory: ' || SQLERRM);
END update_inventory;
/

--execution update_inventory
BEGIN
    update_inventory(1, 90, 16.00); 
END;
/

select * from inventory


--Inventory table procedure for delete_inventory 
CREATE OR REPLACE PROCEDURE delete_inventory (
    p_item_id IN NUMBER
) AS
BEGIN
    DELETE FROM inventory
    WHERE item_id = p_item_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Inventory item ID not found');
    END IF;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20012, 'Error deleting inventory: ' || SQLERRM);
END delete_inventory;
/

--execution for delete_inventory
BEGIN
    delete_inventory(1);
END;
/

----SERVICE_INVENTORY Table Procedures  use_inventory 
CREATE OR REPLACE PROCEDURE use_inventory (
    p_service_id IN NUMBER,
    p_item_id IN NUMBER,
    p_quantity_used IN NUMBER
) AS
    v_quantity NUMBER;
BEGIN
    INSERT INTO service_inventory (service_id, item_id, quantity_used)
    VALUES (p_service_id, p_item_id, p_quantity_used);
    UPDATE inventory
    SET quantity = quantity - p_quantity_used
    WHERE item_id = p_item_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20013, 'Inventory item ID not found');
    END IF;

    -- Retrieve the updated inventory quantity
    SELECT quantity INTO v_quantity
    FROM inventory
    WHERE item_id = p_item_id;
    IF v_quantity < 0 THEN
        RAISE_APPLICATION_ERROR(-20014, 'Insufficient inventory quantity');
    END IF;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20015, 'Error using inventory: ' || SQLERRM);
END use_inventory;
/
--execution for use inventory 

BEGIN
    use_inventory(1, 2, 3); 
END;
/

--procedure for get service_inventory 
CREATE OR REPLACE PROCEDURE get_service_inventory (
    p_service_id IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT si.service_id, si.item_id, si.quantity_used, i.item_name, i.price_per_unit
        FROM service_inventory si
        JOIN inventory i ON si.item_id = i.item_id
        WHERE si.service_id = p_service_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20016, 'Error retrieving service inventory: ' || SQLERRM);
END get_service_inventory;
/


--execution get service_inventory 
DECLARE
    l_cursor SYS_REFCURSOR;
    l_service_id NUMBER;
    l_item_id NUMBER;
    l_quantity_used NUMBER;
    l_item_name VARCHAR2(100);
    l_price_per_unit NUMBER(10,2);
BEGIN
    get_service_inventory(2, l_cursor); 
    LOOP
        FETCH l_cursor INTO l_service_id, l_item_id, l_quantity_used, l_item_name, l_price_per_unit;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Service ID: ' || l_service_id || ', Item ID: ' || l_item_id || 
                            ', Qty Used: ' || l_quantity_used || ', Item: ' || l_item_name || 
                            ', Price: ' || l_price_per_unit);
    END LOOP;
    CLOSE l_cursor;
END;
/

--procedure for delete service_inventory 
CREATE OR REPLACE PROCEDURE delete_service_inventory (
    p_service_id IN NUMBER,
    p_item_id IN NUMBER
) AS
BEGIN
    DELETE FROM service_inventory
    WHERE service_id = p_service_id AND item_id = p_item_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20017, 'Service inventory record not found');
    END IF;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20018, 'Error deleting service inventory: ' || SQLERRM);
END delete_service_inventory;
/

--execution delete service_inventory
BEGIN
    delete_service_inventory(1, 2); 
END;
/

