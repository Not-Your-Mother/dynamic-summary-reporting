-- Project: Dynamic Summary Reporting System
-- Database: Neon Tech's DVD Rental (PostgreSQL)
-- Description: Creates a summary reporting table and supporting logic
-- Author: Kimberly D.
-- Date: 2025-05-29


-- Function to convert store_id to readable store names
CREATE OR REPLACE FUNCTION store_transformation(store_id smallint)
RETURNS varchar AS
$$
BEGIN
	RETURN CASE store_id
		WHEN 1 THEN 'Store 1'
		ELSE 'Store 2'
	END;
END;
$$
LANGUAGE PLPGSQL;

-- Table to store detailed rental records for transformation
CREATE TABLE detailed_table (
	rental_id int,
	customer_id smallint,
	inventory_id int,
	film_id smallint,
	title varchar(100),
	store_id smallint,
	category_id smallint,
	category_name varchar(100),
	store varchar(100),
	PRIMARY KEY(rental_id)
);

-- Table to store summary rankings by category and store
CREATE TABLE summary_table (
	store varchar(100),
	category_name varchar(100),
	title varchar(100),
	rank smallint,
	PRIMARY KEY (store, category_name, title)
);

-- Populate the detailed table from the original rental and film tables
INSERT INTO detailed_table(rental_id, customer_id, inventory_id, film_id, title, store_id, category_id, 
	category_name, store)
SELECT rental_id, customer_id, rental.inventory_id, inventory.film_id, film.title, store_id, 
	film_category.category_id, category.name, store_transformation(store_id) AS store 
FROM rental
JOIN inventory ON rental.inventory_id = inventory.inventory_id
JOIN film_category ON inventory.film_id = film_category.film_id
JOIN film ON inventory.film_id = film.film_id
JOIN category ON film_category.category_id = category.category_id;

-- Trigger function: Refreshes the summary table after changes to detailed_table
CREATE OR REPLACE FUNCTION summary_table_update() 
RETURNS trigger
LANGUAGE PLPGSQL
AS $$
BEGIN
	-- Clear existing summary data
	DELETE FROM summary_table;

	INSERT INTO summary_table (store, category_name, title, rank)

	-- Step 1: Identify which customers watched which categories
	WITH 
	customers_by_category AS(
		SELECT customer_id, category_id FROM detailed_table
	),

	-- Step 2: Find films co-watched by same customers in other categories
	films_per_category AS(
		SELECT film_id, store, detailed_table.category_id AS cowatched_category, 
		customers_by_category.category_id AS target_category 
		FROM detailed_table
		JOIN customers_by_category ON customers_by_category.customer_id = detailed_table.customer_id
		WHERE NOT detailed_table.category_id = customers_by_category.category_id
		
	),

	-- Step 3: Count number of rentals per film per target category
	rentals_per_film_per_category AS(
		SELECT COUNT(*) AS film_count, target_category, store, film_id
		FROM films_per_category
		GROUP BY target_category, film_id, store
	),

	-- Step 4: Rank the films by popularity (co-watch frequency)
	ranked_films_per_category_by_store AS(
		SELECT * , ROW_NUMBER() OVER (PARTITION BY target_category, store ORDER BY film_count DESC) 
		AS rank_number
		FROM rentals_per_film_per_category	
	),

	-- Step 5: Map category IDs to names
	category_id_name_map AS(
		SELECT DISTINCT detailed_table.category_id, detailed_table.category_name
		FROM detailed_table
		JOIN ranked_films_per_category_by_store ON ranked_films_per_category_by_store.target_category =
			detailed_table.category_id
	),

	-- Step 6: Map film IDs to titles
	film_id_title_map AS(
		SELECT DISTINCT detailed_table.film_id, detailed_table.title
		FROM detailed_table
		JOIN ranked_films_per_category_by_store ON ranked_films_per_category_by_store.film_id =
			detailed_table.film_id
	),

	-- Step 7: Generate the final readable ranked summary
	readable_ranked AS(
	SELECT ranked_films_per_category_by_store.store, category_id_name_map.category_name, 
		film_id_title_map.title, rank_number
	FROM ranked_films_per_category_by_store
	JOIN category_id_name_map ON category_id_name_map.category_id = ranked_films_per_category_by_store.target_category
	JOIN film_id_title_map ON film_id_title_map.film_id = ranked_films_per_category_by_store.film_id
	)

	-- Step 8: Insert top 5 ranked films per category/store into the summary table
	SELECT * FROM readable_ranked
	WHERE rank_number <= 5
	ORDER BY store, category_name, rank_number;	

	RETURN NULL;
END; $$;

-- Trigger: Refresh summary table after new inserts to detailed_table
CREATE OR REPLACE TRIGGER refresh_summary_on_insert
AFTER INSERT ON detailed_table
FOR EACH STATEMENT
EXECUTE FUNCTION summary_table_update();

-- Optional procedure to reload data for testing or refreshing all records
CREATE OR REPLACE PROCEDURE clear_reload_tables ()
LANGUAGE PLPGSQL
AS $$
BEGIN
	-- Clear both tables
	DELETE FROM detailed_table;
	DELETE FROM summary_table;

	-- Reinsert data into detailed_table
	INSERT INTO detailed_table(rental_id, customer_id, inventory_id, film_id, title, store_id, category_id, category_name, store)
	SELECT rental_id, customer_id, rental.inventory_id, inventory.film_id, film.title, store_id, 
		film_category.category_id, category.name, store_transformation(store_id) AS store 
	FROM rental
	JOIN inventory ON rental.inventory_id = inventory.inventory_id
	JOIN film_category ON inventory.film_id = film_category.film_id
	JOIN film ON inventory.film_id = film.film_id
	JOIN category ON film_category.category_id = category.category_id;

END;
$$;
	