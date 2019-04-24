-- ***********************************************
-- Create a role called "hpsa_role"
-- ***********************************************
create role hpsa_role;
-- ***********************************************
-- Allow user to connect to DB
-- ***********************************************
grant create session to hpsa_role;
-- ***********************************************
-- Allow the following operations:
-- create/modify/drop tables
-- create comments
-- create indexes
-- create constraints (pk/fk)
-- ***********************************************
grant create table to hpsa_role;
-- ***********************************************
-- Allow user to create and drop sequences
-- ***********************************************
grant create sequence to hpsa_role;
-- ***********************************************
-- Allow user to create and drop triggers
-- ***********************************************
grant create trigger to hpsa_role;
-- ************************************************
-- Allow user to create and drop views
-- ************************************************
grant create view to hpsa_role;
commit;

-- ***********************************************
-- Create new user with unlimited quota
-- ***********************************************
create user hpsa identified by secret default tablespace USERS quota unlimited on USERS;
-- ***********************************************
-- Assign the "hpsa_role" to the newly created user
-- ***********************************************
grant hpsa_role to hpsa;
