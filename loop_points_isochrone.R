
eisenberg_connection <- DBI::dbConnect(RPostgres::Postgres(),
                                       user= "docker",
                                       password = "docker",
                                       host = "localhost",
                                       dbname="gis",
                                       port = 25432)

table_end <- glue_sql("CREATE TABLE table_end
                (start_vid integer,
                end_vid integer,
                path smallint,
                length float,
                cost float)")
#idx <- 1

to <- sf::read_sf(eisenberg_connection,
                  "hospital_rs_node_v2") |> st_as_sf()

tic.clear()

table_end_db <- dbGetQuery(conn=eisenberg_connection,table_end )
library(tictoc)

for (idx in 1:length(from$id)) {
  tic(glue("run {idx}/{length(from$id)}")) 
  hospital_name <- from$ds_cnes[idx]
  origin_id <- from$id[idx]
  
  table_name_1 <- glue("first_path_point_{as.character(idx)}")
  table_name_2 <- glue("second_path_point_{as.character(idx)}")
  table_name_3 <- glue("second_route_point_{as.character(idx)}")
  table_name_4 <- glue("third_path_point_{as.character(idx)}")
  table_name_5 <- glue("third_route_point_{as.character(idx)}")
  table_name_6 <- glue("three_alternative_routes_point_{as.character(idx)}")
  table_name_7 <- glue("table_end_point_{as.character(idx)}")
  
  
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_1`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  
  # Assuming you have an open PostgreSQL connection in con
  query_1 <- glue_sql("
CREATE TABLE {`table_name_1`} AS
SELECT 
        seq,
        path_seq,
        start_vid,
        end_vid,
        net.the_geom,
        node,
        edge,
        1 AS path
  FROM pgr_dijkstra('
        SELECT
            id,
            source,
            target,
            cost
        FROM porto_alegre_net_largest',
                    ARRAY(SELECT id FROM isochrones_sampling_points WHERE id ={origin_id}),
                    ARRAY(SELECT id AS end_id FROM hospital_rs_node_v2 WHERE cd_cnes = {hospital_name}),
                    directed:=TRUE) AS path
LEFT JOIN porto_alegre_net_largest AS net
ON Path.edge = net.id", .con = eisenberg_connection)
  # Send the query
  result_q1 <- dbGetQuery(conn= eisenberg_connection, query_1)
  # dijkstra_second_route
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_2`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  query_2 <- glue_sql("
CREATE TABLE {`table_name_2`} AS
WITH pgr_doubled_dijkstra AS (
    SELECT 
        *
    FROM  pgr_dijkstra('
            SELECT 
                id,
                source,
                target,
                cost
            FROM porto_alegre_net_largest',
            ARRAY(SELECT id FROM points_cardiologia WHERE id = {origin_id}),
            ARRAY(SELECT id FROM hospital_rs_node_v2 WHERE ds_cnes = {hospital_name}),
            directed := TRUE  -- This clause should be inside the pgr_dijkstra function
        )
),  -- Corrected closing of pgr_dijkstra CTE
second_route AS (
    SELECT 
        net.*,
        CASE 
            WHEN route.node = net.source THEN net.cost * 20
            ELSE net.cost
        END AS cost_updated
    FROM            
        porto_alegre_net_largest AS net
    LEFT JOIN 
        pgr_doubled_dijkstra  AS route 
    ON  
        route.edge = net.id
) 
SELECT * 
FROM second_route", .con = eisenberg_connection)
  
  result_2 <- dbGetQuery(conn= eisenberg_connection, query_2)
  
  ## Calculate teh second route
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_3`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  
  query_3 <- glue_sql("
CREATE TABLE {`table_name_3`} AS
SELECT 
    seq,
    path_seq,
    start_vid,
    end_vid,
    node,
    edge,
    net.the_geom,
    2 AS path
FROM 
    pgr_dijkstra('
        SELECT
            id,
            source,
            target,
            cost_updated AS cost
        FROM
            second_path_point_1',
        ARRAY(SELECT id FROM points_cardiologia WHERE id = {origin_id}),
        ARRAY(SELECT id FROM hospital_rs_node_v2 WHERE ds_cnes = {hospital_name}), directed:=TRUE
    ) AS path
LEFT JOIN
    second_path_point_1 AS net 
    ON path.edge = net.id;
", .con = eisenberg_connection)
  
  # Run the CREATE TABLE query
  dbExecute(conn = eisenberg_connection, query_3)
  select_query <- "SELECT * FROM second_route_point_1;"
  
  # Fetch the data
  result_3 <- dbGetQuery(conn = eisenberg_connection, select_query)
  
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_4`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  # Third route
  query_4 <- glue_sql("
CREATE TABLE {`table_name_4`} AS
WITH pgr_doubled_dijkstra AS (
SELECT 
    *
FROM  pgr_dijkstra('
                SELECT 
                        id,
                        source,
                        target,
                        cost_updated AS cost
                FROM second_path_point_1',
                ARRAY(SELECT id FROM points_cardiologia WHERE id = {origin_id}),
        ARRAY(SELECT id FROM hospital_rs_node_v2 WHERE ds_cnes = {hospital_name}),
                directed:=TRUE)), ----node 9372, network = source, target)
second_route AS (
            SELECT 
            net.*,
            CASE 
                WHEN route.node = net.source THEN net.cost_updated * 20
                ELSE net.cost_updated
            END AS cost_updated_nd
            FROM            
                second_path_point_1 AS net
            LEFT JOIN 
                pgr_doubled_dijkstra  AS route 
            ON  
                route.edge= net.id) 
        SELECT * FROM second_route", .con=eisenberg_connection);
  result_4 <- dbGetQuery(conn = eisenberg_connection, query_4)
  
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_5`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  # third route
  query_5 <- glue_sql("
CREATE TABLE {`table_name_5`} AS
SELECT 
            seq,
            path_seq,
            start_vid,
            end_vid,
            node,
            edge,
            net.the_geom,
            3 AS path
        FROM 
            pgr_Dijkstra('
                    SELECT
                        id,
                        source,
                        target,
                        cost_updated_nd AS cost
                    FROM
                        third_path_point_1',
                   ARRAY(SELECT id FROM points_cardiologia WHERE id = {origin_id}),
        ARRAY(SELECT id FROM hospital_rs_node_v2 WHERE ds_cnes = {hospital_name}))  AS path
        LEFT JOIN
                third_path_point_1 AS net ON
            path.edge = net.id;", .con= eisenberg_connection)
  result <- dbGetQuery(conn = eisenberg_connection, query_5)

  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_6`}", .con=eisenberg_connection),
            conn=eisenberg_connection)  
  alterantive_point_1 <- glue_sql("
CREATE TABLE {`table_name_6`} AS 
SELECT start_vid, end_vid,path, the_geom, edge FROM {`table_name_1`}
UNION
SELECT start_vid, end_vid,path, the_geom, edge FROM {`table_name_3`}
UNION
SELECT start_vid, end_vid,path, the_geom, edge FROM {`table_name_5`}", .con = eisenberg_connection)
  
  result_6 <- dbGetQuery(conn = eisenberg_connection, alterantive_point_1)
  
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_7`}", .con=eisenberg_connection),
            conn=eisenberg_connection)  
  table_end_point_1 <- glue_sql("
CREATE TABLE {`table_name_7`} AS
SELECT
            alternative.*,
            ceil(st_length(alternative.the_geom::geography)/1000) As length,
            original.cost AS cost
          FROM
            {`table_name_6`} AS alternative
          LEFT JOIN
           porto_alegre_net_largest  AS original
          ON
          alternative.edge = original.id
          WHERE
            edge!= -1", .con=eisenberg_connection)
  result_7 <- dbGetQuery(conn=eisenberg_connection,table_end_point_1 )
  
  
  calculations <- glue_sql("
  INSERT INTO table_end (start_vid, end_vid, path, length, cost)
        SELECT 
          start_vid,
          end_vid,
          path,
          st_union(the_geom),
          sum(length) AS length,
          sum(cost) AS cost
        FROM 
            {`table_name_7`} 
        GROUP BY
        start_vid,
        end_vid,
        path
        ORDER BY path ASC", .con=eisenberg_connection)
  
  dbExecute(con=eisenberg_connection, calculations)
 toc() 
}

## Test 2
to <- sf::read_sf(eisenberg_connection,
                  "hospital_rs_node_v2") |> st_as_sf()


table_end_v2 <- glue_sql("CREATE TABLE table_end_v2
                (start_vid integer,
                end_vid integer,
                path smallint,
                length float,
                cost float,
                the_geom geometry)")
table_end_db <- dbGetQuery(conn=eisenberg_connection,table_end_v2 )

isochrones_sampling_points <-st_read(eisenberg_connection, "isochrones_snapped")
df_isochrone_points  <- isochrones_sampling_points 

DBI::dbWriteTable(eisenberg_connection,"isochrones_sampling_points",isochrones_sampling_points)
# we have the id of the hospital, then we nned all the points that are in the isochrone of the hospital. How do we get this?


idx_hospital <- 15
for (idx_hospital in 1:length(unique(isochrones_sampling_points$cd_cnes))){
  tic(glue("hospital run {idx_hospital}/{length(unique(isochrones_sampling_points$cd_cnes))}"))
      code_hospital<-unique(isochrones_sampling_points$cd_cnes)[idx_hospital]
      points_for_isochrone <- filter(isochrones_sampling_points,
                                    cd_cnes == code_hospital)
      alternative_routes(
        df_isochrone_points=points_for_isochrone)
  toc()
  }


#idx <- 1



tic.clear()


library(tictoc)
## data= isochrones_sampling_points
alternative_routes <- function(df_isochrone_points){
for (idx in 1:length(df_isochrone_points$id)) {
  tic(glue("run {idx}/{length(df_isochrone_points$id)}")) 
  hospital_name <- df_isochrone_points$cd_cnes[idx]
  origin_id <- df_isochrone_points$id[idx]
  
  table_name_1 <- glue("first_path_point_{as.character(idx)}")
  table_name_2 <- glue("second_path_point_{as.character(idx)}")
  table_name_3 <- glue("second_route_point_{as.character(idx)}")
  table_name_4 <- glue("third_path_point_{as.character(idx)}")
  table_name_5 <- glue("third_route_point_{as.character(idx)}")
  table_name_6 <- glue("three_alternative_routes_point_{as.character(idx)}")
  table_name_7 <- glue("table_end_point_{as.character(idx)}")
  
  
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_1`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  
  # Assuming you have an open PostgreSQL connection in con
  query_1 <- glue_sql("
CREATE TABLE {`table_name_1`} AS
SELECT 
        seq,
        path_seq,
        start_vid,
        end_vid,
        net.the_geom,
        node,
        edge,
        1 AS path
  FROM pgr_dijkstra('
        SELECT
            id,
            source,
            target,
            cost
        FROM porto_alegre_net_largest',
                    ARRAY(SELECT id FROM isochrones_snapped WHERE id ={origin_id}),
                    ARRAY(SELECT id AS end_id FROM hospital_rs_node_v2 WHERE cd_cnes = {hospital_name}),
                    directed:=TRUE) AS path
LEFT JOIN porto_alegre_net_largest AS net
ON path.edge = net.id", .con = eisenberg_connection)
  # Send the query
  result_q1 <- dbGetQuery(conn= eisenberg_connection, query_1)
  # dijkstra_second_route
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_2`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  query_2 <- glue_sql("
CREATE TABLE {`table_name_2`} AS
WITH pgr_doubled_dijkstra AS (
    SELECT 
        *
    FROM  pgr_dijkstra('
            SELECT 
                id,
                source,
                target,
                cost
            FROM porto_alegre_net_largest',
            ARRAY(SELECT id FROM isochrones_snapped WHERE id = {origin_id}),
            ARRAY(SELECT id FROM hospital_rs_node_v2 WHERE cd_cnes = {hospital_name}),
            directed := TRUE  -- This clause should be inside the pgr_dijkstra function
        )
),  -- Corrected closing of pgr_dijkstra CTE
second_route AS (
    SELECT 
        net.*,
        CASE 
            WHEN route.node = net.source THEN net.cost * 20
            ELSE net.cost
        END AS cost_updated
    FROM            
        porto_alegre_net_largest AS net
    LEFT JOIN 
        pgr_doubled_dijkstra  AS route 
    ON  
        route.edge = net.id
) 
SELECT * 
FROM second_route", .con = eisenberg_connection)
  
  result_2 <- dbGetQuery(conn= eisenberg_connection, query_2)
  
  ## Calculate teh second route
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_3`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  
  query_3 <- glue_sql("
CREATE TABLE {`table_name_3`} AS
SELECT 
    seq,
    path_seq,
    start_vid,
    end_vid,
    node,
    edge,
    net.the_geom,
    2 AS path
FROM 
    pgr_dijkstra('
        SELECT
            id,
            source,
            target,
            cost_updated AS cost
        FROM
            {`table_name_2`}',
        ARRAY(SELECT id FROM isochrones_snapped WHERE id = {origin_id}),
        ARRAY(SELECT id FROM hospital_rs_node_v2 WHERE cd_cnes = {hospital_name}),
        directed:=TRUE
    ) AS path
LEFT JOIN
    {`table_name_2`} AS net 
    ON path.edge = net.id;
", .con = eisenberg_connection)
  
  # Run the CREATE TABLE query
  dbExecute(conn = eisenberg_connection, query_3)
  select_query <- glue_sql("SELECT * FROM {`table_name_3`} ;",.con=eisenberg_connection) 
  
  # Fetch the data
  result_3 <- dbGetQuery(conn = eisenberg_connection, select_query)
  
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_4`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  # Third route
  query_4 <- glue_sql("
CREATE TABLE {`table_name_4`} AS
WITH pgr_doubled_dijkstra AS (
SELECT 
    *
FROM  pgr_dijkstra('
                SELECT 
                        id,
                        source,
                        target,
                        cost_updated AS cost
                FROM {`table_name_2`}',
                ARRAY(SELECT id FROM isochrones_snapped WHERE id = {origin_id}),
        ARRAY(SELECT id FROM hospital_rs_node_v2 WHERE cd_cnes = {hospital_name}),
                directed:=TRUE)), ----node 9372, network = source, target)
second_route AS (
            SELECT 
            net.*,
            CASE 
                WHEN route.node = net.source THEN net.cost_updated * 20
                ELSE net.cost_updated
            END AS cost_updated_nd
            FROM            
                {`table_name_2`} AS net
            LEFT JOIN 
                pgr_doubled_dijkstra  AS route 
            ON  
                route.edge= net.id) 
        SELECT * FROM second_route", .con=eisenberg_connection);
  
  result_4 <- dbGetQuery(conn = eisenberg_connection, query_4)
  
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_5`}", .con=eisenberg_connection),
            conn=eisenberg_connection)
  # third route
  query_5 <- glue_sql("
CREATE TABLE {`table_name_5`} AS
SELECT 
            seq,
            path_seq,
            start_vid,
            end_vid,
            node,
            edge,
            net.the_geom,
            3 AS path
        FROM 
            pgr_Dijkstra('
                    SELECT
                        id,
                        source,
                        target,
                        cost_updated_nd AS cost
                    FROM
                        {`table_name_4`}',
                   ARRAY(SELECT id FROM isochrones_snapped WHERE id = {origin_id}),
        ARRAY(SELECT id FROM hospital_rs_node_v2 WHERE cd_cnes = {hospital_name}),
        directed:=TRUE)  AS path
        LEFT JOIN
                {`table_name_4`} AS net ON
            path.edge = net.id;", .con= eisenberg_connection)
  result <- dbGetQuery(conn = eisenberg_connection, query_5)
  
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_6`}", .con=eisenberg_connection),
            conn=eisenberg_connection)  
  alterantive_point_1 <- glue_sql("
CREATE TABLE {`table_name_6`} AS 
SELECT start_vid, end_vid,path, the_geom, edge FROM {`table_name_1`}
UNION
SELECT start_vid, end_vid,path, the_geom, edge FROM {`table_name_3`}
UNION
SELECT start_vid, end_vid,path, the_geom, edge FROM {`table_name_5`}", .con = eisenberg_connection)
  
  result_6 <- dbGetQuery(conn = eisenberg_connection, alterantive_point_1)
  
  dbExecute(glue_sql("DROP TABLE IF EXISTS {`table_name_7`}", .con=eisenberg_connection),
            conn=eisenberg_connection)  
  table_end_point_1 <- glue_sql("
CREATE TABLE {`table_name_7`} AS
SELECT
            alternative.*,
            ceil(st_length(alternative.the_geom::geography)/1000) As length,
            original.cost AS cost
          FROM
            {`table_name_6`} AS alternative
          LEFT JOIN
           porto_alegre_net_largest  AS original
          ON
          alternative.edge = original.id
          WHERE
            edge!= -1", .con=eisenberg_connection)
  result_7 <- dbGetQuery(conn=eisenberg_connection,table_end_point_1 )
  
  
  calculations <- glue_sql("
  INSERT INTO table_end_v2 (start_vid, end_vid, path, length, cost, the_geom)
        SELECT 
          start_vid,
          end_vid,
          path,
          sum(length) AS length,
          sum(cost) AS cost,
          st_union(the_geom) as the_geom
        FROM 
            {`table_name_7`} 
        GROUP BY
        start_vid,
        end_vid,
        path
        ORDER BY path ASC", .con=eisenberg_connection)
  
  dbExecute(conn=eisenberg_connection, calculations)
  toc() 
}
}

