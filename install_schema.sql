DROP SCHEMA IF EXISTS fallout CASCADE;
CREATE SCHEMA fallout;

--Schema for projects-denormalized.csv
CREATE TABLE fallout.projects (
    project_id           integer PRIMARY KEY,
    date_created         date NOT NULL,
    date_start           date,
    date_end             date,
    is_viable            boolean,
    is_approved          boolean,
    preceding_project_id integer,
    FOREIGN KEY (preceding_project_id) REFERENCES fallout.projects (project_id)
);

--Schema for report-categories.csv
CREATE TABLE fallout.report_categories (
    category_name        text PRIMARY KEY,
    category_included    boolean,
    category_description text
);

