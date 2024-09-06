--Create the get_fallout_report function
CREATE OR REPLACE FUNCTION fallout.get_fallout_report
    (
        as_of_date    date,
        todays_date   date,
        dates_through date,
        include_all   boolean DEFAULT TRUE
    )
RETURNS TABLE (debug      text,
               project_id integer,
               status     text,
               follow_up  integer)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH relevant_projects AS (
        SELECT
            p.project_id,
            p.date_start,
            p.date_end,
            p.is_viable,
            p.is_approved,
            p.preceding_project_id
        FROM fallout.projects p
        WHERE (include_all
               OR (p.date_start BETWEEN as_of_date AND todays_date))
            AND (p.date_end IS NULL
                 OR p.date_end BETWEEN as_of_date AND dates_through)
    )
    , follow_up_projects AS (
        SELECT
            p.project_id            AS project_id,
            p.preceding_project_id  AS preceding_project_id,
            CASE
            WHEN p.is_approved
                THEN 'Approved'
            WHEN p.date_start > todays_date
                THEN 'Future Project'
            WHEN p.date_start BETWEEN as_of_date AND dates_through
                THEN
                    CASE WHEN p.is_viable
                        THEN 'Work-In-Process'
                    ELSE 'Not Viable' END
            ELSE 'Out-Of-Range' END AS status
        FROM relevant_projects p
        WHERE p.preceding_project_id IS NOT NULL
    )
    SELECT
        CASE WHEN p.date_start IS NULL
            THEN 'Out-Of-Bounds'
        WHEN p.date_start > todays_date
            THEN 'Future Project'
        WHEN p.date_start < as_of_date OR p.date_end > dates_through
            THEN 'Out-Of-Range'
        WHEN p.is_approved
            THEN 'Approved Project'
        WHEN p.is_viable AND f.preceding_project_id IS NULL
            THEN 'Not Sold'
        WHEN f.status = 'Approved'
            THEN 'Approved'
        WHEN f.status = 'Work-In-Process'
            THEN 'Work-In-Process'
        WHEN f.status = 'Not Viable'
            THEN 'Not Viable'
        ELSE 'Unexpected Outcome' END  AS debug,
        p.project_id,
        COALESCE(f.status, 'Not Sold') AS status,
        f.preceding_project_id         AS follow_up
    FROM relevant_projects p
        LEFT JOIN follow_up_projects f
            ON p.project_id = f.preceding_project_id;
END;
$function$;

