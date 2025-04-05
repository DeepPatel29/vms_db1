SET SERVEROUTPUT ON;

-- Prevent deletion if role is in use (Role table trigger)
CREATE OR REPLACE TRIGGER trg_role_before_delete
BEFORE DELETE ON ROLE
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM USER_TABLE
    WHERE role_id = :OLD.role_id;
    
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cannot delete role; it is assigned to users.');
    END IF;
END;
/

-- Testing Trigger
DELETE FROM ROLE WHERE ROLE_ID = 2;

--Prevent changing role_id to non-existent rolePrevent changing role_id to non-existent role(USER_TABLE)
CREATE OR REPLACE TRIGGER trg_user_before_update
BEFORE UPDATE OF role_id ON USER_TABLE
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM ROLE
    WHERE role_id = :NEW.role_id;
    
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid role_id; role does not exist.');
    END IF;
END;
/

--Testing Trigger
UPDATE USER_TABLE
SET role_id = 100  -- Non-existent role_id
WHERE user_id = 1;


--Audit triggers
-- Trigger for USER_TABLE
CREATE OR REPLACE TRIGGER trg_user_audit
FOR INSERT OR UPDATE OR DELETE ON USER_TABLE
COMPOUND TRIGGER
    v_user_name VARCHAR2(100);

    BEFORE STATEMENT IS
    BEGIN
        v_user_name := USER;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING THEN
            INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
            VALUES (audit_seq.NEXTVAL, v_user_name, 'USER_TABLE', 'INSERT', 
                    NULL, :NEW.user_id, SYSTIMESTAMP);
        
        ELSIF UPDATING THEN
            -- Handle username change
            IF (:OLD.username IS NULL AND :NEW.username IS NOT NULL) OR 
               (:OLD.username IS NOT NULL AND :NEW.username IS NULL) OR 
               (:OLD.username != :NEW.username) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'USER_TABLE', 'UPDATE', 
                        :OLD.username, :NEW.username, SYSTIMESTAMP);
            END IF;

            -- Handle email change
            IF (:OLD.email IS NULL AND :NEW.email IS NOT NULL) OR 
               (:OLD.email IS NOT NULL AND :NEW.email IS NULL) OR 
               (:OLD.email != :NEW.email) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'USER_TABLE', 'UPDATE', 
                        :OLD.email, :NEW.email, SYSTIMESTAMP);
            END IF;
        
        ELSIF DELETING THEN
            INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
            VALUES (audit_seq.NEXTVAL, v_user_name, 'USER_TABLE', 'DELETE', 
                    :OLD.user_id, NULL, SYSTIMESTAMP);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END AFTER EACH ROW;
END trg_user_audit;
/

-- Test USER_TABLE
BEGIN
    -- Test INSERT
    INSERT INTO USER_TABLE (user_id, role_id, username, Email, Password)
    VALUES (user_seq.NEXTVAL, 2, 'TestUser', 'test@example.com', 'test123');
    
    -- Test UPDATE
    UPDATE USER_TABLE
    SET username = 'UpdatedUser'
    WHERE user_id = 7;
    
    -- Test DELETE
    DELETE FROM USER_TABLE 
    WHERE user_id = 7;
    
    -- Commit the changes
    COMMIT;
END;
/


-- Trigger for INVOICE
CREATE OR REPLACE TRIGGER trg_invoice_audit
FOR INSERT OR UPDATE OR DELETE ON INVOICE
COMPOUND TRIGGER
    v_user_name VARCHAR2(100);

    BEFORE STATEMENT IS
    BEGIN
        v_user_name := USER;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING THEN
            INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
            VALUES (audit_seq.NEXTVAL, v_user_name, 'INVOICE', 'INSERT', 
                    NULL, :NEW.invoice_id, SYSTIMESTAMP);
        
        ELSIF UPDATING THEN
            -- Handle total_amount change
            IF :OLD.total_amount != :NEW.total_amount THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'INVOICE', 'UPDATE', 
                        TO_CHAR(:OLD.total_amount), TO_CHAR(:NEW.total_amount), SYSTIMESTAMP);
            END IF;
        
        ELSIF DELETING THEN
            INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
            VALUES (audit_seq.NEXTVAL, v_user_name, 'INVOICE', 'DELETE', 
                    :OLD.invoice_id, NULL, SYSTIMESTAMP);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END AFTER EACH ROW;
END trg_invoice_audit;
/


-- Test INVOICE

    -- Test INSERT
    INSERT INTO INVOICE (invoice_id, service_id, app_id, invoice_date, total_amount)
    VALUES (invoice_seq.NEXTVAL, 1, 1, SYSDATE, 100.00);
    
    -- Test UPDATE
    UPDATE INVOICE
    SET total_amount = 150.00
    WHERE invoice_id = 23;
    
    -- Test DELETE
    DELETE FROM INVOICE 
    WHERE invoice_id = 23;
    


-- Compound Trigger for PAYMENT
CREATE OR REPLACE TRIGGER trg_payment_audit
FOR INSERT OR UPDATE OR DELETE ON PAYMENT
COMPOUND TRIGGER
    v_user_name VARCHAR2(100);

    BEFORE STATEMENT IS
    BEGIN
        v_user_name := USER;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING THEN
            INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
            VALUES (audit_seq.NEXTVAL, v_user_name, 'PAYMENT', 'INSERT', 
                    NULL, :NEW.payment_id, SYSTIMESTAMP);
        
        ELSIF UPDATING THEN
            -- Handle amount_paid change
            IF :OLD.amount_paid != :NEW.amount_paid THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'PAYMENT', 'UPDATE', 
                        TO_CHAR(:OLD.amount_paid), TO_CHAR(:NEW.amount_paid), SYSTIMESTAMP);
            END IF;

            -- Handle payment_method change
            IF (:OLD.payment_method IS NULL AND :NEW.payment_method IS NOT NULL) OR 
               (:OLD.payment_method IS NOT NULL AND :NEW.payment_method IS NULL) OR 
               (:OLD.payment_method != :NEW.payment_method) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'PAYMENT', 'UPDATE', 
                        :OLD.payment_method, :NEW.payment_method, SYSTIMESTAMP);
            END IF;
        
        ELSIF DELETING THEN
            INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
            VALUES (audit_seq.NEXTVAL, v_user_name, 'PAYMENT', 'DELETE', 
                     :OLD.payment_id, NULL, SYSTIMESTAMP);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END AFTER EACH ROW;
END trg_payment_audit;
/


--TEST Payment

    -- Test INSERT
    INSERT INTO PAYMENT (payment_id, invoice_id, payment_date, amount_paid, payment_method, Status)
    VALUES (payment_seq.NEXTVAL, 1, SYSDATE, 50.00, 'Debit Card', 'Completed');
    
    -- Test UPDATE
    UPDATE PAYMENT
    SET Payment_method = 'Debit card'
    WHERE payment_id = 3;
    
    -- Test DELETE
    DELETE FROM PAYMENT 
    WHERE payment_id = 22;
    



-- Trigger for INVENTORY
CREATE OR REPLACE TRIGGER trg_inventory_audit
FOR INSERT OR UPDATE OR DELETE ON INVENTORY
COMPOUND TRIGGER
    v_user_name VARCHAR2(100);

    BEFORE STATEMENT IS
    BEGIN
        v_user_name := USER;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING THEN
            INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
            VALUES (audit_seq.NEXTVAL, v_user_name, 'INVENTORY', 'INSERT', 
                    NULL, :NEW.item_id, SYSTIMESTAMP);
        
        ELSIF UPDATING THEN
            -- Handle quantity change
            IF :OLD.quantity != :NEW.quantity THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'INVENTORY', 'UPDATE', 
                        TO_CHAR(:OLD.quantity), TO_CHAR(:NEW.quantity), SYSTIMESTAMP);
            END IF;
        
        ELSIF DELETING THEN
            INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
            VALUES (audit_seq.NEXTVAL, v_user_name, 'INVENTORY', 'DELETE', 
                     :OLD.item_id, NULL, SYSTIMESTAMP);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END AFTER EACH ROW;
END trg_inventory_audit;
/

--TEST Inventory

    -- Test INSERT
    INSERT INTO INVENTORY (item_id, item_name, quantity, price_per_unit)
    VALUES (inventory_seq.NEXTVAL, 'TestItem', 10, 25.00); 
    
    -- Test UPDATE
    UPDATE INVENTORY
    SET quantity = 15
    WHERE item_name = 'TestItem';
    
    -- Test DELETE
    DELETE FROM INVENTORY 
    WHERE item_name = 'TestItem';
    


--Trigger for CUSTOMER
CREATE OR REPLACE TRIGGER trg_customer_audit
FOR UPDATE ON CUSTOMER
COMPOUND TRIGGER
    v_user_name VARCHAR2(100);

    BEFORE STATEMENT IS
    BEGIN
        v_user_name := USER;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF UPDATING THEN
            -- Handle cust_name change
            IF (:OLD.cust_name IS NULL AND :NEW.cust_name IS NOT NULL) OR 
               (:OLD.cust_name IS NOT NULL AND :NEW.cust_name IS NULL) OR 
               (:OLD.cust_name != :NEW.cust_name) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'CUSTOMER', 'UPDATE', 
                        :OLD.cust_name, :NEW.cust_name, SYSTIMESTAMP);
            END IF;

            -- Handle email change
            IF (:OLD.email IS NULL AND :NEW.email IS NOT NULL) OR 
               (:OLD.email IS NOT NULL AND :NEW.email IS NULL) OR 
               (:OLD.email != :NEW.email) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'CUSTOMER', 'UPDATE', 
                        :OLD.email, :NEW.email, SYSTIMESTAMP);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END AFTER EACH ROW;
END trg_customer_audit;
/


INSERT INTO CUSTOMER (cust_id, cust_name, phone, email, address) VALUES
(customer_seq.NEXTVAL, 'Sarita', '4644654321', 'Sarita@example.com', '123 Main Road, Karnal');

--TEST Customer
BEGIN
-- Test UPDATE
    UPDATE CUSTOMER
    SET cust_name = 'UpdatedCust', email = 'updatedcust@example.com'
    WHERE cust_name = 'Sarita';
    COMMIT;
END;
/

-- Trigger for VEHICLE
CREATE OR REPLACE TRIGGER trg_vehicle_audit
FOR UPDATE ON VEHICLE
COMPOUND TRIGGER
    v_user_name VARCHAR2(100);

    BEFORE STATEMENT IS
    BEGIN
        v_user_name := USER;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF UPDATING THEN
            -- Handle licence_plate change
            IF (:OLD.licence_plate IS NULL AND :NEW.licence_plate IS NOT NULL) OR 
               (:OLD.licence_plate IS NOT NULL AND :NEW.licence_plate IS NULL) OR 
               (:OLD.licence_plate != :NEW.licence_plate) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'VEHICLE', 'UPDATE', 
                        :OLD.licence_plate, :NEW.licence_plate, SYSTIMESTAMP);
            END IF;

            -- Handle make change
            IF (:OLD.make IS NULL AND :NEW.make IS NOT NULL) OR 
               (:OLD.make IS NOT NULL AND :NEW.make IS NULL) OR 
               (:OLD.make != :NEW.make) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'VEHICLE', 'UPDATE', 
                        :OLD.make, :NEW.make, SYSTIMESTAMP);
            END IF;

            -- Handle model change
            IF (:OLD.model IS NULL AND :NEW.model IS NOT NULL) OR 
               (:OLD.model IS NOT NULL AND :NEW.model IS NULL) OR 
               (:OLD.model != :NEW.model) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'VEHICLE', 'UPDATE', 
                        :OLD.model, :NEW.model, SYSTIMESTAMP);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END AFTER EACH ROW;
END trg_vehicle_audit;
/


INSERT INTO VEHICLE (Vehicle_id, cust_id, Licence_plate, Make, Model, Year) VALUES
(vehicle_seq.NEXTVAL, 1, 'TEST123', 'Toyota', 'Corolla', 2020);


-- Test VEHICLE
BEGIN
--Test update
    UPDATE VEHICLE
    SET licence_plate = 'UPDATEDTEST', make = 'Ford'
    WHERE vehicle_id = 21;
    
    COMMIT;
END;
/


-- Trigger for APPOINTMENT
CREATE OR REPLACE TRIGGER trg_appointment_audit
FOR UPDATE ON APPOINTMENT
COMPOUND TRIGGER
    v_user_name VARCHAR2(100);

    BEFORE STATEMENT IS
    BEGIN
        v_user_name := USER;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF UPDATING THEN
            -- Handle status change
            IF (:OLD.status IS NULL AND :NEW.status IS NOT NULL) OR 
               (:OLD.status IS NOT NULL AND :NEW.status IS NULL) OR 
               (:OLD.status != :NEW.status) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'APPOINTMENT', 'UPDATE', 
                        :OLD.status, :NEW.status, SYSTIMESTAMP);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END AFTER EACH ROW;
END trg_appointment_audit;
/


INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id) VALUES
(appointment_seq.NEXTVAL, 3, 3, TO_DATE('2023-10-10', 'YYYY-MM-DD'), TO_TIMESTAMP('10:45:00', 'HH24:MI:SS'), 'Pending', 3, 3);


BEGIN
    
    -- Test UPDATE
    UPDATE APPOINTMENT
    SET status = 'Completed'
    WHERE app_id = 41;
    
    COMMIT;
END;
/


-- Trigger for SERVICE
CREATE OR REPLACE TRIGGER trg_service_audit
FOR UPDATE ON SERVICE
COMPOUND TRIGGER
    v_user_name VARCHAR2(100);

    BEFORE STATEMENT IS
    BEGIN
        v_user_name := USER;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF UPDATING THEN
            -- Handle status change
            IF (:OLD.status IS NULL AND :NEW.status IS NOT NULL) OR 
               (:OLD.status IS NOT NULL AND :NEW.status IS NULL) OR 
               (:OLD.status != :NEW.status) THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'SERVICE', 'UPDATE', 
                        :OLD.status, :NEW.status, SYSTIMESTAMP);
            END IF;

            -- Handle cost change
            IF :OLD.cost != :NEW.cost THEN
                INSERT INTO AUDIT_LOG (audit_id, user_name, tablename, action, oldValue, newValue, Updated_at)
                VALUES (audit_seq.NEXTVAL, v_user_name, 'SERVICE', 'UPDATE', 
                        TO_CHAR(:OLD.cost), TO_CHAR(:NEW.cost), SYSTIMESTAMP);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END AFTER EACH ROW;
END trg_service_audit;
/


INSERT INTO Service (service_id, service_type, service_date, status, cost)
VALUES (4, 'Test service', TO_DATE(SYSDATE, 'YYYY-MM-DD'), 'Completed', 50.00);

BEGIN
    -- Test UPDATE
    UPDATE SERVICE
    SET cost = 150.00
    WHERE service_id = 4;
    
    COMMIT;
END;
/


--=================================================Audit triggers End=====================================================================

--=================================================Vehicle and Appointment triggers start=====================================================================


--Triggers for VEHICLE
CREATE OR REPLACE TRIGGER trg_vehicle_year_check
BEFORE INSERT OR UPDATE OF Year ON VEHICLE
FOR EACH ROW
BEGIN
    IF :NEW.Year > EXTRACT(YEAR FROM SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20032, 'Vehicle year cannot be in the future.');
    ELSIF :NEW.Year < 1900 THEN
        RAISE_APPLICATION_ERROR(-20033, 'Vehicle year cannot be before 1900.');
    END IF;
END;
/

-- Valid year
INSERT INTO VEHICLE (Vehicle_id, cust_id, Licence_plate, Make, Model, Year)
VALUES (vehicle_seq.NEXTVAL, 5001, 'ABC123', 'Toyota', 'Camry', 2020);  -- Succeeds

-- Future year (fails)
INSERT INTO VEHICLE (Vehicle_id, cust_id, Licence_plate, Make, Model, Year)
VALUES (vehicle_seq.NEXTVAL, 5001, 'XYZ789', 'Honda', 'Civic', 2026);  -- Fails


-- Past year (fails)
CREATE OR REPLACE TRIGGER trg_appointment_date_check
BEFORE INSERT ON APPOINTMENT
FOR EACH ROW
BEGIN
    IF :NEW.app_date < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20036, 'Appointment date cannot be in the past.');
    END IF;
END;
/

-- Future date (succeeds)
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id)
VALUES (appointment_seq.NEXTVAL, 5001, 7002, SYSDATE + 1, TO_TIMESTAMP('14:00:00', 'HH24:MI:SS'), 'Scheduled', 1001, 1);

-- Past date (fails)
INSERT INTO APPOINTMENT (app_id, cust_id, vehicle_id, app_date, app_time, status, service_id, emp_id)
VALUES (appointment_seq.NEXTVAL, 5001, 7002, SYSDATE - 1, TO_TIMESTAMP('14:00:00', 'HH24:MI:SS'), 'Scheduled', 1001, 1);


--=================================================Vehicle and Appointment triggers End=====================================================================

--TRIGGERS :

-------
--triggers for trg_service_auto_cost_update

CREATE OR REPLACE TRIGGER trg_service_auto_cost_update
AFTER INSERT OR UPDATE ON service_inventory
FOR EACH ROW
DECLARE
    v_item_price NUMBER(10, 2);
    v_total_cost NUMBER(10, 2) := 0;
BEGIN
    -- Calculate the total cost based on items used in the service
    SELECT price_per_unit INTO v_item_price
    FROM inventory
    WHERE item_id = :NEW.item_id;

    v_total_cost := v_item_price * :NEW.quantity_used;

    -- Update the service cost
    UPDATE Service
    SET cost = cost + v_total_cost
    WHERE service_id = :NEW.service_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Item not found for the given item_id');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred in trg_service_auto_cost_update: ' || SQLERRM);
END trg_service_auto_cost_update;
/

--testing Auto cost update 
-- Insert service_inventory 
INSERT INTO service_inventory (service_id, item_id, quantity_used)
VALUES (23, 2, 1);  -- Used 1 Engine Oil

-- Now check the Service table to see if the cost gets updated
SELECT * FROM Service WHERE service_id = 23;

select * from service_inventory
select * from service


--=========INVOICE TIGGERS===========
-- 1..Trigger to auto generate invoices when a service is marked 'Completed'. 
CREATE OR REPLACE TRIGGER trg_auto_generate_invoice
AFTER UPDATE ON service
FOR EACH ROW
WHEN (NEW.status = 'Completed') -- Fires only when status is updated to 'Completed'
DECLARE
    v_invoice_count NUMBER;
    v_app_id NUMBER;
    v_cost NUMBER;
BEGIN
    -- Fetch app_id from appointment 
    BEGIN
        SELECT app_id INTO v_app_id
        FROM appointment
        WHERE service_id = :NEW.service_id
        AND ROWNUM = 1; -- Ensure only one row is returned
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'No appointment found for service ID: ' || :NEW.service_id);
        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(-20004, 'Multiple appointments found for service ID: ' || :NEW.service_id);
    END;

    -- Check for existing invoice
    SELECT COUNT(*) INTO v_invoice_count
    FROM invoice
    WHERE service_id = :NEW.service_id
    AND app_id = v_app_id;

    v_cost := :NEW.cost;

    -- Generate invoice if none exists
    IF v_invoice_count = 0 THEN
        INSERT INTO invoice (invoice_id, service_id, app_id, total_amount, invoice_date, created_at)
        VALUES (
            invoice_seq.NEXTVAL,  -- Auto-incremented ID
            :NEW.service_id,
            v_app_id,
            v_cost,  -- Use fetched cost
            SYSDATE,
            SYSTIMESTAMP
        );
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20005, 'Service cost not found for service ID: ' || :NEW.service_id);
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20001, 'Duplicate invoice detected for service ID: ' || :NEW.service_id);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Unexpected error in trg_auto_generate_invoice: ' || SQLERRM);
END;
/

--Test the trigger (trg_auto_generate_invoice)
UPDATE service 
SET status = 'completed' 
WHERE service_id = 4;

SELECT * FROM invoice WHERE service_id = 4;


-- 2. Trigger to Prevent Duplicate Invoices for the Same Service and Appointment
CREATE OR REPLACE TRIGGER trg_prevent_duplicate_invoices
BEFORE INSERT ON invoice
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Check if an invoice already exists for this service and appointment
    SELECT COUNT(*) INTO v_count 
    FROM invoice 
    WHERE service_id = :NEW.service_id AND app_id = :NEW.app_id;

    -- If an invoice already exists, prevent insertion
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Duplicate invoice detected! An invoice already exists for this service and appointment.');
    END IF;
END;
/
--inserted a duplicate invoice to test the trigger (trg_prevent_duplicate_invoices)
INSERT INTO invoice (invoice_id, service_id, app_id, total_amount, invoice_date, created_at)
VALUES (3, 3, 3, 50, SYSDATE, SYSTIMESTAMP);


--=======TRIGGER FOR PAYMENT TABLE========

-- 1..Trigger to Prevent Duplicate Payments for the Same Invoice:
CREATE OR REPLACE TRIGGER trg_prevent_duplicate_payments
BEFORE INSERT ON payment
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    -- Check if a payment already exists for this invoice
    SELECT COUNT(*) INTO v_count 
    FROM payment 
    WHERE invoice_id = :NEW.invoice_id;

    -- If a payment already exists, prevent insertion
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Duplicate payment detected! A payment has already been made for this invoice.');
    END IF;
END;
/

-- Inserted  a duplicate payment for the same invoice to test the trigger
INSERT INTO payment (payment_id, invoice_id, payment_date, amount_paid , payment_method, status)
VALUES (1, 1, SYSDATE,  50, 'credit-card', 'successful');

