SET DATABASE butterflynet;

DROP TABLE RECORDS;
DROP TABLE PROJECTS;
DROP TABLE USERS;
DROP TABLE USERS_OF_PROJECTS;

CREATE TABLE PROJECTS (
    id SERIAL PRIMARY KEY,
    auth_key VARCHAR(255) NOT NULL
);

CREATE TABLE RECORDS (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    timestamp BIGINT NOT NULL,
    content TEXT,
    FOREIGN KEY (project_id) REFERENCES PROJECTS(id)
);

CREATE TABLE USERS(
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password TEXT
);

CREATE TABLE USERS_OF_PROJECTS(
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (project_id) REFERENCES PROJECTS(id),
    FOREIGN KEY (user_id) REFERENCES USERS(id)
);

CREATE TABLE TYPES(
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    type VARCHAR(255),

    FOREIGN KEY (project_id) REFERENCES PROJECTS(id)
);

CREATE TABLE SELENIUM_RECORDS(
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL,
    timestamp BIGINT NOT NULL,
    page_path VARCHAR(255) NOT NULL,
    issues TEXT NOT NULL,

    FOREIGN KEY (project_id) REFERENCES PROJECTS(id)
);

CREATE OR REPLACE FUNCTION notify_on_insert()
    RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('record_inserted', 'raw_data');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER observe_inserts
    AFTER INSERT ON RECORDS
    FOR EACH STATEMENT
    EXECUTE FUNCTION notify_on_insert();


create role butterflynet_access;

GRANT SELECT, INSERT, UPDATE, DELETE ON PROJECTS TO butterflynet_access;
GRANT SELECT, INSERT, UPDATE, DELETE ON RECORDS TO butterflynet_access;
GRANT SELECT, INSERT, UPDATE, DELETE ON USERS TO butterflynet_access;
GRANT SELECT, INSERT, UPDATE, DELETE ON USERS_OF_PROJECTS TO butterflynet_access;
GRANT SELECT, INSERT, UPDATE, DELETE ON TYPES TO butterflynet_access;
GRANT SELECT, INSERT, UPDATE, DELETE ON SELENIUM_RECORDS TO butterflynet_access;

GRANT USAGE ON SEQUENCE projects_id_seq TO butterflynet_access;
GRANT USAGE ON SEQUENCE records_id_seq TO butterflynet_access;
GRANT USAGE ON SEQUENCE selenium_records_id_seq TO butterflynet_access;
GRANT USAGE ON SEQUENCE types_id_seq TO butterflynet_access;
GRANT USAGE ON SEQUENCE users_id_seq TO butterflynet_access;
GRANT USAGE ON SEQUENCE users_of_projects_id_seq TO butterflynet_access;

CREATE USER ingestion_api WITH PASSWORD 'ingestion_api_secret';
GRANT butterflynet_access TO ingestion_api;
CREATE USER dashboard_listener WITH PASSWORD 'dashboard_listener_secret';
GRANT butterflynet_access TO dashboard_listener;
CREATE USER dashboard_server WITH PASSWORD 'dashboard_server_secret';
GRANT butterflynet_access TO dashboard_server;
CREATE USER agent_manager WITH PASSWORD 'agent_manager_secret';
GRANT butterflynet_access TO agent_manager;