SET SERVEROUTPUT ON;

-- ROLE Table Procedures Package
CREATE OR REPLACE PACKAGE role_procedures AS
    PROCEDURE add_role(p_role_name IN VARCHAR2);
    PROCEDURE get_role(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_role(p_role_id IN NUMBER, p_new_role_name IN VARCHAR2);
    PROCEDURE delete_role(p_role_id IN NUMBER);
END role_procedures;
/

CREATE OR REPLACE PACKAGE BODY role_procedures AS
    PROCEDURE add_role(p_role_name IN VARCHAR2) IS
    BEGIN
        -- Uses sequence to generate unique role_id and inserts new role
        INSERT INTO ROLE (role_id, role_name)
        VALUES (role_seq.NEXTVAL, p_role_name);
        COMMIT; -- Save the changes
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback on error and provide error message
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Error adding role: ' || SQLERRM);
    END add_role;
    
    PROCEDURE get_role(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        -- Opens a cursor with all roles for retrieval
        OPEN p_cursor FOR
        SELECT * FROM ROLE;
    END get_role;
    
    PROCEDURE update_role(p_role_id IN NUMBER, p_new_role_name IN VARCHAR2) IS
    BEGIN
        -- Updates role name for specified role_id
        UPDATE ROLE 
        SET role_name = p_new_role_name
        WHERE role_id = p_role_id;
        COMMIT; -- Save the update
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback on error (including constraint violation)
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'Error updating role: ' || SQLERRM);
    END update_role;
    
    PROCEDURE delete_role(p_role_id IN NUMBER) IS
        v_count NUMBER;
    BEGIN
        -- Check if any users reference this role
        SELECT COUNT(*) INTO v_count 
        FROM USER_TABLE 
        WHERE role_id = p_role_id;
        
        -- Prevent deletion if role is in use
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Cannot delete role - users exist with this role');
        END IF;
        
        -- Delete the role if no dependencies found
        DELETE FROM ROLE WHERE role_id = p_role_id;
        COMMIT; -- Save the deletion
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20004, 'Error deleting role: ' || SQLERRM);
    END delete_role;
END role_procedures;
/


select * from role;


-- Execute ROLE Table Procedures

-- Add a new role
EXEC role_procedures.add_role('Manager');


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
EXEC role_procedures.update_role(3, 'Administrator');


-- Delete a role (will fail due to dependency)
EXEC role_procedures.delete_role(1);

-- Delete a role (will execute successfully)
EXEC role_procedures.delete_role(3);


-- USER_TABLE Procedures Package
CREATE OR REPLACE PACKAGE user_procedures AS
    PROCEDURE add_user(p_role_id IN NUMBER, p_username IN VARCHAR2, 
                      p_email IN VARCHAR2, p_password IN VARCHAR2);
    PROCEDURE get_user(p_user_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE update_user(p_user_id IN NUMBER, p_username IN VARCHAR2, p_email IN VARCHAR2);
    PROCEDURE delete_user(p_user_id IN NUMBER);
END user_procedures;
/

CREATE OR REPLACE PACKAGE BODY user_procedures AS
    PROCEDURE add_user(p_role_id IN NUMBER, p_username IN VARCHAR2, 
                      p_email IN VARCHAR2, p_password IN VARCHAR2) IS
    BEGIN
        -- Insert new user with sequence-generated user_id
        -- Foreign key ensures valid role_id
        INSERT INTO USER_TABLE (user_id, role_id, username, Email, Password)
        VALUES (user_seq.NEXTVAL, p_role_id, p_username, p_email, p_password);
        COMMIT; -- Save the new user
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback on error (e.g., duplicate email or invalid role_id)
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20005, 'Error adding user: ' || SQLERRM);
    END add_user;
    
    PROCEDURE get_user(p_user_id IN NUMBER DEFAULT NULL, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        -- Retriving all users if no ID provided, otherwise retrieves specific user 
        IF p_user_id IS NULL THEN
            OPEN p_cursor FOR
            SELECT * FROM USER_TABLE;
        ELSE
            OPEN p_cursor FOR
            SELECT * FROM USER_TABLE WHERE user_id = p_user_id;
        END IF;
    END get_user;
    
    PROCEDURE update_user(p_user_id IN NUMBER, p_username IN VARCHAR2, p_email IN VARCHAR2) IS
    BEGIN
        -- Update username and email for specified user
        -- UNIQUE constraint on Email ensures no duplicates
        UPDATE USER_TABLE 
        SET username = p_username,
            Email = p_email
        WHERE user_id = p_user_id;
        COMMIT; -- Save the update
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20006, 'Error updating user: ' || SQLERRM);
    END update_user;
    
    PROCEDURE delete_user(p_user_id IN NUMBER) IS
    BEGIN
        -- Delete user by ID
        DELETE FROM USER_TABLE WHERE user_id = p_user_id;
        COMMIT; -- Save the deletion
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
EXEC user_procedures.add_user(2, 'Amit', 'Amit@example.com', 'amit123');

-- Add a new user ( with duplicate email)
EXEC user_procedures.add_user(2, 'Aman', 'Amit@example.com', 'amit123');


-- Get all users
DECLARE
    l_cursor SYS_REFCURSOR;
    l_user_id NUMBER;
    l_role_id NUMBER;
    l_username VARCHAR2(100);
    l_email VARCHAR2(100);
    l_password VARCHAR2(100);
BEGIN
    user_procedures.get_user(NULL, l_cursor);
    LOOP
        FETCH l_cursor INTO l_user_id, l_role_id, l_username, l_email, l_password;
        EXIT WHEN l_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('User ID: ' || l_user_id || ', Username: ' || l_username || 
                            ', Email: ' || l_email || ', Role ID: ' || l_role_id);
    END LOOP;
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
    user_procedures.get_user(1, l_cursor);
    FETCH l_cursor INTO l_user_id, l_role_id, l_username, l_email, l_password;
    DBMS_OUTPUT.PUT_LINE('User ID: ' || l_user_id || ', Username: ' || l_username || 
                        ', Email: ' || l_email || ', Role ID: ' || l_role_id);
    CLOSE l_cursor;
END;
/


-- Update a user
EXEC user_procedures.update_user(7, 'SaritaUpdated', 'Sarita.updated@example.com');

-- Delete a user
EXEC user_procedures.delete_user(7);


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
    PROCEDURE get_audit_logs(p_tablename IN VARCHAR2 DEFAULT NULL, 
                           p_start_date IN TIMESTAMP DEFAULT NULL,
                           p_end_date IN TIMESTAMP DEFAULT NULL,
                           p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        -- Opens a cursor to fetch audit logs
        -- Filters are optional: if parameters are NULL, they are ignored
        -- With sample data, returns all logs if no filters applied
        OPEN p_cursor FOR
        SELECT * FROM AUDIT_LOG
        WHERE (p_tablename IS NULL OR tablename = p_tablename)
        AND (p_start_date IS NULL OR Updated_at >= p_start_date)
        AND (p_end_date IS NULL OR Updated_at <= p_end_date);
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
