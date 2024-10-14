---- Create spatial index
----- Porto Alegre settlement network to use dijkstra
CREATE INDEX idx_porto_alegre_net_pre_the_geom ON porto_alegre_net_pre USING gist(the_geom);
CREATE INDEX idx_porto_alegre_net_pre_target ON porto_alegre_net_pre USING btree(target);
CREATE INDEX idx_porto_alegre_net_pre_source ON porto_alegre_net_pre USING btree(source);
CREATE INDEX idx_porto_alegre_net_pre_cost ON porto_alegre_net_pre USING btree(cost);
CREATE INDEX idx_porto_alegre_net_pre_bidirectid ON porto_alegre_net_pre USING btree(bidirectid);
CREATE INDEX idx_porto_alegre_net_pre_id ON porto_alegre_net_pre USING btree(id);
----- Porto Alegre settlement network to use astar
CREATE INDEX idx_porto_alegre_net_astar_the_geom ON porto_alegre_net_largest_astar USING gist(the_geom);
CREATE INDEX idx_porto_alegre_net_astar_target ON porto_alegre_net_largest_astar USING btree(target);
CREATE INDEX idx_porto_alegre_net_astar_source ON porto_alegre_net_largest_astar USING btree(source);
CREATE INDEX idx_porto_alegre_net_astar_cost ON porto_alegre_net_largest_astar USING btree(cost);
CREATE INDEX idx_porto_alegre_net_astar_bidirectid ON porto_alegre_net_largest_astar USING btree(bidirectid);
CREATE INDEX idx_porto_alegre_net_astar_id_x1 ON porto_alegre_net_largest_astar USING btree(x1);
CREATE INDEX idx_porto_alegre_net_astar_id_y1 ON porto_alegre_net_largest_astar USING btree(y1);
CREATE INDEX idx_porto_alegre_net_astar_id_x2 ON porto_alegre_net_largest_astar USING btree(x2);
CREATE INDEX idx_porto_alegre_net_astar_id_y2 ON porto_alegre_net_largest_astar USING btree(y2);
---- Different methods using pgr_dijkstra

----- naive (100)
SELECT   b.id,
 b.the_geom,
 count(the_geom) as centrality 
 FROM  pgr_dijkstra('SELECT  id,
                             source,
                            target,
                            cost
                      FROM porto_alegre_net_pre',
                      ARRAY(SELECT net_id AS start_id FROM weight_sampling_100_origin  ), 
                      ARRAY(SELECT net_id AS end_id FROM weight_sampling_100_destination ),
                      directed := TRUE) j
                      LEFT JOIN porto_alegre_net_pre AS b ---- This join is used to add the geometry column from the network to the pgr_dijkstra results.
                      ON j.edge = b.id
                      GROUP BY  b.id, b.the_geom
                      ORDER BY centrality DESC;  
----- naive (200)
SELECT   b.id,
 b.the_geom,
 count(the_geom) as centrality 
 FROM  pgr_dijkstra('SELECT  id,
                             source,
                            target,
                            cost
                      FROM porto_alegre_net_pre',
                      ARRAY(SELECT net_id AS start_id FROM weight_sampling_200_origin  ), 
                      ARRAY(SELECT net_id AS end_id FROM weight_sampling_200_destination ),
                      directed := TRUE) j
                      LEFT JOIN porto_alegre_net_pre AS b 
                      ON j.edge = b.id
                      GROUP BY  b.id, b.the_geom
                      ORDER BY centrality DESC;
----- naive (300)
SELECT   b.id,
 b.the_geom,
 count(the_geom) as centrality 
 FROM  pgr_dijkstra('SELECT  id,
                             source,
                            target,
                            cost
                      FROM porto_alegre_net_pre',
                      ARRAY(SELECT net_id AS start_id FROM weight_sampling_300_origin  ), 
                      ARRAY(SELECT net_id AS end_id FROM weight_sampling_300_destination ),
                      directed := TRUE) j
                      LEFT JOIN porto_alegre_net_pre AS b 
                      ON j.edge = b.id
                      GROUP BY  b.id, b.the_geom
                      ORDER BY centrality DESC;       
----- naive (500)
SELECT   b.id,
 b.the_geom,
 count(the_geom) as centrality 
 FROM  pgr_dijkstra('SELECT  id,
                             source,
                            target,
                            cost
                      FROM porto_alegre_net_pre',
                      ARRAY(SELECT net_id AS start_id FROM weight_sampling_500_origin  ), 
                      ARRAY(SELECT net_id AS end_id FROM weight_sampling_500_destination ),
                      directed := TRUE) j
                      LEFT JOIN porto_alegre_net_pre AS b 
                      ON j.edge = b.id
                      GROUP BY  b.id, b.the_geom
                      ORDER BY centrality DESC;        
----- array_agg()
------- Create an array with origin and destination - other number of OD are in the appendix
--- 100          
CREATE TEMP TABLE array_100 AS  
	WITH all_pairs AS (
	  SELECT o.net_id AS o_id, o.geom AS ogeom,
	         d.net_id AS d_id, d.geom AS dgeom
	    FROM weight_sampling_100_origin AS o,
	         weight_sampling_100_destination AS d)
SELECT * FROM all_pairs;
------ Create indexes on this array
CREATE INDEX idx_array_100_ogem ON array_100 USING gist(ogeom);
CREATE INDEX idx_array_100_dgem ON array_100 USING gist(dgeom);
CREATE INDEX idx_array_100_o_id ON array_100 USING btree(o_id);
CREATE INDEX idx_array_100_d_id ON array_100 USING btree(d_id);
----- 200
CREATE TEMP TABLE array_200 AS  
WITH all_pairs AS (
  SELECT o.net_id AS o_id,
  		 o.geom AS ogeom,
         d.net_id AS d_id,
         d.geom AS dgeom
    FROM weight_sampling_200_origin AS o,
         weight_sampling_200_destination AS d)
SELECT * FROM all_pairs;

CREATE INDEX idx_array_200_ogem ON array_200 USING gist(ogeom);
CREATE INDEX idx_array_200_dgem ON array_200 USING gist(dgeom);
CREATE INDEX idx_array_200_o_id ON array_200 USING btree(o_id);
CREATE INDEX idx_array_200_d_id ON array_200 USING btree(d_id);
----- 300
CREATE TEMP TABLE array_300 AS  
WITH all_pairs AS (
  SELECT o.net_id AS o_id, o.geom AS ogeom,
         d.net_id AS d_id, d.geom AS dgeom
    FROM weight_sampling_300_origin AS o,
         weight_sampling_300_destination AS d)
SELECT * FROM all_pairs;

CREATE INDEX idx_array_300_ogem ON array_300 USING gist(ogeom);
CREATE INDEX idx_array_300_dgem ON array_300 USING gist(dgeom);
CREATE INDEX idx_array_300_o_id ON array_300 USING btree(o_id);
CREATE INDEX idx_array_300_d_id ON array_300 USING btree(d_id);

----- 500
CREATE TEMP TABLE array_500 AS  
WITH all_pairs AS (
  SELECT o.net_id AS o_id, o.geom AS ogeom,
         d.net_id AS d_id, d.geom AS dgeom
    FROM weight_sampling_500_origin AS o,
         weight_sampling_500_destination AS d)
SELECT * FROM all_pairs;

CREATE INDEX idx_array_500_dgem ON array_500 USING gist(dgeom);
CREATE INDEX idx_array_500_o_id ON array_500 USING btree(o_id);
CREATE INDEX idx_array_500_d_id ON array_500 USING btree(d_id);    

------ pgr_dijkstra using the array_agg() method
----100
WITH pgr_result AS (
	SELECT pgr_dijkstra('
				SELECT 
				id,
				source,
				target,
				cost FROM porto_alegre_net_pre',
			array_agg(o_id),
			array_agg(d_id),
		directed := true)
	FROM array_100)
	SELECT   
		b.id,
		b.the_geom,
		count(the_geom) as centrality 
	FROM 
		pgr_result
	LEFT JOIN porto_alegre_net_pre AS b ON (pgr_dijkstra).edge = b.id
	GROUP BY      
		the_geom,
		b.id 
	ORDER BY centrality DESC;  

--- 200
WITH pgr_result AS (
	SELECT pgr_dijkstra('
				SELECT 
				id,
				source,
				target,
				cost FROM porto_alegre_net_pre',
			array_agg(o_id),
			array_agg(d_id),
		directed := true)
	FROM array_200)
	SELECT   
		b.id,
		b.the_geom,
		count(the_geom) as centrality 
	FROM 
		pgr_result
	LEFT JOIN porto_alegre_net_pre AS b ON (pgr_dijkstra).edge = b.id
	GROUP BY      
		the_geom,
		b.id 
	ORDER BY centrality DESC;  
--- 300
WITH pgr_result AS (
	SELECT pgr_dijkstra('
				SELECT 
				id,
				source,
				target,
				cost FROM porto_alegre_net_pre',
			array_agg(o_id),
			array_agg(d_id),
		directed := true)
	FROM array_300)
	SELECT   
		b.id,
		b.the_geom,
		count(the_geom) as centrality 
	FROM 
		pgr_result
	LEFT JOIN porto_alegre_net_pre AS b ON (pgr_dijkstra).edge = b.id
	GROUP BY      
		the_geom,
		b.id 
	ORDER BY centrality DESC;  
--- 500
WITH pgr_result AS (
	SELECT pgr_dijkstra('
				SELECT 
				id,
				source,
				target,
				cost FROM porto_alegre_net_pre',
			array_agg(o_id),
			array_agg(d_id),GER
		directed := true)
	FROM array_500)
	SELECT   
		b.id,
		b.the_geom,
		count(the_geom) as centrality 
	FROM 
		pgr_result
	LEFT JOIN porto_alegre_net_pre AS b ON (pgr_dijkstra).edge = b.id
	GROUP BY      
		the_geom,
		b.id 
	ORDER BY centrality DESC;  
----- bounding box
--- 100
SELECT 
	b.id,
	b.the_geom,
	COUNT(b.the_geom) AS centrality
FROM (SELECT *
	  FROM 
	  	pgr_dijkstra('SELECT 
							id,
							source,
							target,
							cost
						FROM 
							porto_alegre_net_pre
						WHERE 
							the_geom && (SELECT box FROM bbox)', 
							ARRAY(SELECT net_id AS start_id  FROM weight_sampling_100_origin),
							ARRAY(SELECT net_id AS end_id FROM weight_sampling_100_destination),
						directed := TRUE)) AS j
						LEFT JOIN porto_alegre_net_pre AS b
						ON
							j.edge = b.id
						GROUP BY 
							b.id,
							b.the_geom 
						ORDER BY 
							centrality DESC;	
--- 200
SELECT 
	b.id,
	b.the_geom,
	COUNT(b.the_geom) AS centrality
FROM (SELECT *
	  FROM 
	  	pgr_dijkstra('SELECT 
							id,
							source,
							target,
							cost
						FROM 
							porto_alegre_net_pre
						WHERE 
							the_geom && (SELECT box FROM bbox)', 
							ARRAY(SELECT net_id AS start_id  FROM weight_sampling_200_origin),
							ARRAY(SELECT net_id AS end_id FROM weight_sampling_200_destination),
						directed := TRUE)) AS j
						LEFT JOIN porto_alegre_net_pre AS b
						ON
							j.edge = b.id
						GROUP BY 
							b.id,
							b.the_geom 
						ORDER BY 
							centrality DESC;						
--- 300
SELECT 
	b.id,
	b.the_geom,
	COUNT(b.the_geom) AS centrality
FROM (SELECT *
	  FROM 
	  	pgr_dijkstra('SELECT 
							id,
							source,
							target,
							cost
						FROM 
							porto_alegre_net_pre
						WHERE 
							the_geom && (SELECT box FROM bbox)', 
							ARRAY(SELECT net_id AS start_id  FROM weight_sampling_300_origin),
							ARRAY(SELECT net_id AS end_id FROM weight_sampling_300_destination),
						directed := TRUE)) AS j
						LEFT JOIN porto_alegre_net_pre AS b
						ON
							j.edge = b.id
						GROUP BY 
							b.id,
							b.the_geom 
						ORDER BY 
							centrality DESC;						
--- 500
SELECT 
	b.id,
	b.the_geom,
	COUNT(b.the_geom) AS centrality
FROM (SELECT *
	  FROM 
	  	pgr_dijkstra('SELECT 
							id,
							source,
							target,
							cost
						FROM 
							porto_alegre_net_pre
						WHERE 
							the_geom && (SELECT box FROM bbox)', 
							ARRAY(SELECT net_id AS start_id  FROM weight_sampling_500_origin),
							ARRAY(SELECT net_id AS end_id FROM weight_sampling_500_destination),
						directed := TRUE)) AS j
						LEFT JOIN porto_alegre_net_pre AS b
						ON
							j.edge = b.id
						GROUP BY 
							b.id,
							b.the_geom 
						ORDER BY 
							centrality DESC;						
---- Different algorithms using naive approach
----- Dijkstra (same as naive from previous section)
SELECT   b.id,
 b.the_geom,
 count(the_geom) as centrality 
 FROM  pgr_dijkstra('SELECT  id,
                             source,
                            target,
                            cost
                      FROM porto_alegre_net_pre',
                      ARRAY(SELECT net_id AS start_id FROM weight_sampling_100_origin  ),
                      ARRAY(SELECT net_id AS end_id FROM weight_sampling_100_destination ),
                      directed := TRUE) j
                      LEFT JOIN porto_alegre_net_pre AS b 
                      ON j.edge = b.id
                      GROUP BY  b.id, b.the_geom
                      ORDER BY centrality DESC;  						
----- Bdijkstra
---- 100
SELECT   
	b.id,
	b.the_geom,
	count(the_geom) AS centrality
FROM  
	pgr_bdDijkstra(
			'SELECT  id,
					 source,
					 target, 
					 cost
			FROM 
					porto_alegre_net_pre',
				ARRAY(SELECT net_id AS start_id FROM weight_sampling_100_origin),
				ARRAY(SELECT net_id AS end_id FROM weight_sampling_100_destination), 
				directed := TRUE) j
				LEFT JOIN porto_alegre_net_pre AS b
				ON j.edge = b.id
				GROUP BY  b.id, b.the_geom
				ORDER BY centrality DESC;  		      
---- 200
SELECT   
	b.id,
	b.the_geom,
	count(the_geom) AS centrality
FROM  
	pgr_bdDijkstra(
			'SELECT  id,
					 source,
					 target, 
					 cost
			FROM 
					porto_alegre_net_pre',
				ARRAY(SELECT net_id AS start_id FROM weight_sampling_200_origin),
				ARRAY(SELECT net_id AS end_id FROM weight_sampling_200_destination), 
				directed := TRUE) j
				LEFT JOIN porto_alegre_net_pre AS b
				ON j.edge = b.id
				GROUP BY  b.id, b.the_geom
				ORDER BY centrality DESC;  			
---- 300
SELECT   
	b.id,
	b.the_geom,
	count(the_geom) AS centrality
FROM  
	pgr_bdDijkstra(
			'SELECT  id,
					 source,
					 target, 
					 cost
			FROM 
					porto_alegre_net_pre',
				ARRAY(SELECT net_id AS start_id FROM weight_sampling_300_origin),
				ARRAY(SELECT net_id AS end_id FROM weight_sampling_300_destination), 
				directed := TRUE) j
				LEFT JOIN porto_alegre_net_pre AS b
				ON j.edge = b.id
				GROUP BY  b.id, b.the_geom
				ORDER BY centrality DESC;  			
---- 500	
SELECT   
	b.id,
	b.the_geom,
	count(the_geom) AS centrality
FROM  
	pgr_bdDijkstra(
			'SELECT  id,
					 source,
					 target, 
					 cost
			FROM 
					porto_alegre_net_pre',
				ARRAY(SELECT net_id AS start_id FROM weight_sampling_500_origin),
				ARRAY(SELECT net_id AS end_id FROM weight_sampling_500_destination), 
				directed := TRUE) j
				LEFT JOIN porto_alegre_net_pre AS b
				ON j.edge = b.id
				GROUP BY  b.id, b.the_geom
				ORDER BY centrality DESC;  		
----- Astar
---- 100			
SELECT
	b.id,
	b.the_geom,
	count(the_geom) AS centrality 
FROM 
	pgr_astar(  
		'SELECT id,
	  	 	 source,
			 target,
		    	cost,
		    	x1,
		    	y1,
		    	x2,
		    	y2  
		FROM porto_alegre_net_largest_astar',
	ARRAY(SELECT net_id FROM  weight_sampling_100_origin),
	ARRAY(SELECT net_id FROM  weight_sampling_100_destination),
		directed:=TRUE,
		heuristic:=2) j
	LEFT JOIN 
		porto_alegre_net_largest_astar AS b
	ON j.edge = b.id
	GROUP BY  
		b.id,
		b.the_geom                       
	ORDER BY centrality DESC;   	
--- 200
SELECT
	b.id,
	b.the_geom,
	count(the_geom) AS centrality 
FROM 
	pgr_astar(  
		'SELECT id,
	  	 	 source,
			 target,
		    	cost,
		    	x1,
		    	y1,
		    	x2,
		    	y2  
		FROM porto_alegre_net_largest_astar',
	ARRAY(SELECT net_id FROM  weight_sampling_200_origin),
	ARRAY(SELECT net_id FROM  weight_sampling_200_destination),
		directed:=TRUE,
		heuristic:=2) j
	LEFT JOIN 
		porto_alegre_net_largest_astar AS b
	ON j.edge = b.id
	GROUP BY  
		b.id,
		b.the_geom                       
	ORDER BY centrality DESC;  
--- 300
SELECT
	b.id,
	b.the_geom,
	count(the_geom) AS centrality 
FROM 
	pgr_astar(  
		'SELECT id,
	  	 	 source,
			 target,
		    	cost,
		    	x1,
		    	y1,
		    	x2,
		    	y2  
		FROM porto_alegre_net_largest_astar',
	ARRAY(SELECT net_id FROM  weight_sampling_300_origin),
	ARRAY(SELECT net_id FROM  weight_sampling_300_destination),
		directed:=TRUE,
		heuristic:=2) j
	LEFT JOIN 
		porto_alegre_net_largest_astar AS b
	ON j.edge = b.id
	GROUP BY  
		b.id,
		b.the_geom                       
	ORDER BY centrality DESC;  
--- 500
SELECT
	b.id,
	b.the_geom,
	count(the_geom) AS centrality 
FROM 
	pgr_astar(  
		'SELECT id,
	  	 	 source,
			 target,
		    	cost,
		    	x1,
		    	y1,
		    	x2,
		    	y2  
		FROM porto_alegre_net_largest_astar',
	ARRAY(SELECT net_id FROM  weight_sampling_500_origin),
	ARRAY(SELECT net_id FROM  weight_sampling_500_destination),
		directed:=TRUE,
		heuristic:=2) j
	LEFT JOIN 
		porto_alegre_net_largest_astar AS b
	ON j.edge = b.id
	GROUP BY  
		b.id,
		b.the_geom                       
	ORDER BY centrality DESC;  
----- BAstar
---- 100
SELECT    
	b.id,
	b.the_geom,
	count(the_geom) AS centrality
FROM 
	pgr_bdAstar(
		'SELECT id,
	    source,
	    target,
	    cost,
	    x1,
	    y1,
	    x2,
	    y2  
FROM 	porto_alegre_net_largest_astar',
	ARRAY(SELECT net_id FROM  weight_sampling_100_origin),
	ARRAY(SELECT net_id FROM  weight_sampling_100_destination),
	directed:=TRUE,
	heuristic:=2) j
	LEFT JOIN 
		porto_alegre_net_largest_astar AS b                      
		ON j.edge = b.id                       
		GROUP BY  b.id,
		b.the_geom
		ORDER BY centrality DESC;
---- 200
SELECT    
	b.id,
	b.the_geom,
	count(the_geom) AS centrality
FROM 
	pgr_bdAstar(
		'SELECT id,
	    source,
	    target,
	    cost,
	    x1,
	    y1,
	    x2,
	    y2  
FROM 	porto_alegre_net_largest_astar',
	ARRAY(SELECT net_id FROM  weight_sampling_200_origin),
	ARRAY(SELECT net_id FROM  weight_sampling_200_destination),
	directed:=TRUE,
	heuristic:=2) j
	LEFT JOIN 
		porto_alegre_net_largest_astar AS b                      
		ON j.edge = b.id                       
		GROUP BY  b.id,
		b.the_geom
		ORDER BY centrality DESC;

--- 300
SELECT    
	b.id,
	b.the_geom,
	count(the_geom) AS centrality
FROM 
	pgr_bdAstar(
		'SELECT id,
	    source,
	    target,
	    cost,
	    x1,
	    y1,
	    x2,
	    y2  
FROM 	porto_alegre_net_largest_astar',
	ARRAY(SELECT net_id FROM  weight_sampling_300_origin),
	ARRAY(SELECT net_id FROM  weight_sampling_300_destination),
	directed:=TRUE,
	heuristic:=2) j
	LEFT JOIN 
		porto_alegre_net_largest_astar AS b                      
		ON j.edge = b.id                       
		GROUP BY  b.id,
		b.the_geom
		ORDER BY centrality DESC;	
--- 500
SELECT    
	b.id,
	b.the_geom,
	count(the_geom) AS centrality
FROM 
	pgr_bdAstar(
		'SELECT id,
	    source,
	    target,
	    cost,
	    x1,
	    y1,
	    x2,
	    y2  
FROM 	porto_alegre_net_largest_astar',
	ARRAY(SELECT net_id FROM  weight_sampling_500_origin),
	ARRAY(SELECT net_id FROM  weight_sampling_500_destination),
	directed:=TRUE,
	heuristic:=2) j
	LEFT JOIN 
		porto_alegre_net_largest_astar AS b                      
		ON j.edge = b.id                       
		GROUP BY  b.id,
		b.the_geom
		ORDER BY centrality DESC;	


