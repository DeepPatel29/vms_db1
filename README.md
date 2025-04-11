# Vehicle Management System - Backend (SQL)

## Purpose of the Project

This project is the backend part of the **Vehicle Management System** developed by **Aviato**. It consists of SQL scripts designed to handle database interactions including triggers, functions, procedures, and schema creation. The backend has been developed on Oracle SQL to manage data, automate processes, and ensure the integrity and consistency of the application's database.

## SQL Files Overview

- **Triggers.sql**: This file contains SQL triggers used for auditing, managing data changes, and enforcing business rules. Triggers are automatically executed based on certain actions on the database tables (e.g., insert, update, delete).

- **Functions.sql**: This file includes user-defined functions that encapsulate reusable logic for the application. These functions can be used to simplify queries and calculations that are needed throughout the system.

- **Procedures.sql**: This file contains stored procedures that perform complex operations or tasks. Procedures are used for actions that involve multiple steps, such as data processing, report generation, or handling business workflows.

- **Schema.sql**: This file defines the database schema, including the creation of tables, relationships, constraints, and other necessary elements for setting up the backend database.

- **TestBlocks.sql**: This file includes test blocks to validate the correct execution of functions, procedures, and triggers. It can be used to ensure the database logic works as expected before the full system is deployed.

## Setup and Requirements

- **Database Type**: Oracle SQL
- **Database Version**: Ensure you are using a compatible version of Oracle SQL that supports the features used in these scripts.
  
To set up the project:
1. **Create the database**: Set up an Oracle SQL database where the schema will be created.
2. **Execute SQL Scripts**:
   - Run the **Schema.sql** script first to create the necessary tables and relationships.
   - Then, execute the **Triggers.sql**, **Functions.sql**, and **Procedures.sql** files in that order to set up the business logic and data handling.
   - Finally, use the **TestBlocks.sql** to verify that everything is functioning correctly.

## How to Use

1. Open your Oracle SQL tool (e.g., SQL*Plus, SQLcl, or Oracle SQL Developer).
2. Connect to your Oracle SQL database.
3. Execute each of the SQL files in the order listed above (Schema -> Triggers -> Functions -> Procedures).
4. After execution, run the **TestBlocks.sql** to confirm everything is working correctly.

## Conclusion

This backend setup ensures that the **Vehicle Management System** runs smoothly with a well-structured database, efficient data handling through functions and procedures, and automated processes through triggers. The test blocks will allow you to confirm that the backend works as expected before integrating it with the frontend of the application.
