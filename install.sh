
function service_setup() {

    export PGPASSWORD='postgres'
    psql --quiet --host=localhost --port=5432 --username=postgres --dbname=postgres --set=ON_ERROR_STOP=1 "$@"
    
    #psql "postgresql://postgres@localhost:5432/postgres"
}


function initialize_schema () {
    touch "log.txt"
    service_setup  --quiet --file ./install_schema.sql > "log.txt"
}
function copy_data() {

    echo "Copying Data Starts"
    service_setup  --quiet \
               >/dev/null \
<<'SQL'

    \COPY fallout.projects from './input/projects-denormalized.csv' with delimiter ',' csv header;
    \COPY fallout.report_categories from './input/report-categories.csv' with delimiter ',' csv header;

SQL
  echo "Copying Data Ends"
}

function initialize_function () {
    touch "log.txt"
    service_setup  --quiet --file ./install_function.sql > "log.txt"
}

function generte_reports() {

    #Create a Directory for Results
    rm -rf actual
    mkdir -p actual

   #Run the Function and Export Results:
    echo "Starts Report Generation"
    service_setup  --quiet \
               >/dev/null \
<<'SQL'

   \COPY (SELECT * FROM fallout.get_fallout_report('2024-01-01'::date, '2024-06-30'::date, '2024-12-31'::date, TRUE)) TO './actual/report_all.csv' WITH CSV HEADER;
   \COPY (SELECT * FROM fallout.get_fallout_report('2024-01-01'::date, '2024-06-30'::date, '2024-12-31'::date, FALSE)) TO './actual/report_filtered.csv' WITH CSV HEADER;

SQL

    echo "Report Generation Ends"
}

function compare_reports() {

    echo "-------------------------------------------------------------"
    echo "Comparison of Report Filtered"
    echo "-------------------------------------------------------------"


    diff -q ./actual/report_filtered.csv ./expected/report_filtered.csv

    echo "-------------------------------------------------------------"
    echo "Comparison of Report All"
    echo "-------------------------------------------------------------"

    diff -q ./actual/report_all.csv ./expected/report_all.csv

}

initialize_schema
copy_data
initialize_function
generte_reports

compare_reports
