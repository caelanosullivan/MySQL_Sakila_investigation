USE sakila;

-- 1a Display first and last names from table actors
SELECT first_name, last_name
FROM actor

-- 1b Display first and last as one column called 'Actor'
SELECT CONCAT(first_name, ' ', last_name) AS 'Actor'
FROM actor

-- 2a Find (ID, first_name, last_name) for actor with first_name "Joe"
SELECT actor_id, first_name, last_name
FROM actor
WHERE first_name LIKE "Joe"

-- 2b Find all actors whose last name contains letters 'GEN'
SELECT CONCAT (first_name, ' ', last_name) AS 'Actor'
FROM actor
WHERE last_name LIKE '%GEN%'

-- 2c Find all actors whose last name contains letters 'LI'; order by last_name then first_name
SELECT first_name, last_name
FROM actor
WHERE last_name LIKE '%LI%'
ORDER BY last_name, first_name

-- 2d Use IN to display country_id and country columns of the following countries: Afghanistan, Bangladesh, and China
SELECT country_id, country
FROM country
WHERE country IN ('Afghanistan', 'Bangladesh', 'China')

-- 3a Add middle_name to 'actor' table
ALTER TABLE actor
ADD COLUMN middle_name VARCHAR(100) NOT NULL AFTER first_name

-- 3b Change data type of 3b. You realize that some of these actors have tremendously long last names. Change the data type of the middle_name column to blobs.

ALTER TABLE actor
ADD COLUMN fake_name BLOB AFTER middle_name

/*SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_name = 'actor' AND COLUMN_NAME = 'fake_name'; */

UPDATE actor
SET fake_name=last_name;

ALTER TABLE actor
DROP COLUMN fake_name

-- 3c Delete middle_name
ALTER TABLE actor
DROP COLUMN middle_name

-- 4a
SELECT last_name, count(*)
FROM actor
GROUP BY last_name

-- 4b
SELECT last_name, count(*)
FROM actor
GROUP BY last_name
HAVING count(*) >= 2

-- 4c
UPDATE actor SET first_name='HARPO' WHERE first_name='GROUCHO' AND last_name='WILLIAMS';
SELECT * FROM actor WHERE last_name='WILLIAMS';

-- 4d Change 'HARPO' WILLIAMS to 'GROUCHO', other 'WILLIAMS' to 'MUCHO GROUCHO'

UPDATE actor
SET first_name = 
	IF(first_name = 'HARPO' AND last_name = 'WILLIAMS', 
		'GROUCHO', 
			IF(last_name = 'WILLIAMS', 
				'MUCHO GROUCHO', 
					first_name
			  )
		)
WHERE first_name IS NOT NULL;

-- 5a Locate schema of address table
DESCRIBE address;
SHOW CREATE TABLE address;

-- 6a JOIN staff and address tables to display first_name, last_name, address of staff
SELECT A.first_name, A.last_name, B.address
FROM staff A
LEFT JOIN address B
ON A.address_id = B.address_ID

-- 6b JOIN to display total rung up by staff member in Aug 2005 (tables staff and payment)
SELECT sum(A.amount) as 'Sum', CONCAT(B.first_name, ' ', B.last_name) as 'Name'
FROM (
	SELECT amount, staff_id, payment_date
	FROM payment
	WHERE payment_date BETWEEN '2005-08-01' AND '2005-08-31'
	) A
LEFT JOIN staff B ON
	A.staff_id = B.staff_id
GROUP BY B.first_name, B.last_name

-- 6c List each film and the number of actors who are listed for that film. Use tables film_actor and film. Use inner join.

SELECT B.title, count(A.actor_id)
FROM film_actor A
INNER JOIN film B ON
	A.film_id = B.film_id
GROUP BY B.title

-- 6d How many copies of the film Hunchback Impossible exist in the inventory system?

SELECT count(A.film_id), B.title
FROM inventory A
INNER JOIN (SELECT film_id, title
			FROM film
			WHERE title = 'Hunchback Impossible' 
			) B
	ON A.film_id = B.film_id
GROUP BY B.title

-- 6e Using the tables payment and customer and the JOIN command, list the total paid by each customer. List the customers alphabetically by last name

SELECT sum(A.amount) as 'Total', B.first_name, B.last_name
FROM payment A
LEFT JOIN customer B ON
	A.customer_id = B.customer_id
GROUP BY B.last_name, B.first_name

-- 7a Display titles of movies starting with K or Q whose language is English
-- Optimized (filter each table then join)
SELECT A.title, A.language_id
FROM (SELECT title, language_id
	  FROM film
	  WHERE title like 'k%' OR 'q%'
	  ) A
INNER JOIN (SELECT language_id
			FROM language
			WHERE name = 'English'
			) B
ON A.language_id = B.language_id

-- Less optimized version (filter at the end):
SELECT A.title, A.language_id
FROM film A
INNER JOIN language B
ON A.language_id = B.language_id
WHERE (A.title like 'k%' OR 'q%') AND (B.name = 'English')

-- 7b Use subqueries to display all actors who appear in the film Alone Trip.

SELECT CONCAT (first_name, ' ', last_name) AS 'Name'
FROM actor 
WHERE actor_id IN (
	SELECT actor_id
	FROM film_actor
	WHERE film_id = (
		SELECT film_id
		FROM film
		WHERE title = 'ALONE TRIP'
		)
		)

-- 7c You want to run an email marketing campaign in Canada, for which you will need the names and email addresses of all Canadian customers. Use joins to retrieve this information.

SELECT A.first_name, A.last_name, A.email
FROM customer A
INNER JOIN (SELECT ID
			FROM customer_list
			WHERE country = 'Canada'
			) B
ON A.customer_ID = B.ID

-- 7d. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as famiy films.

SELECT title
FROM film
WHERE film_id IN 
(
	SELECT film_id
	FROM film_category
	WHERE category_id = 
	(
		SELECT category_id
		FROM category
		WHERE name = 'Family'
		)
)

-- 7e. Display the most frequently rented movies in descending order.

-- With joins only
SELECT title, count(*)
FROM rental A
LEFT JOIN inventory B
ON A.inventory_id = B.inventory_id
LEFT JOIN film C
ON B.film_id = C.film_id
GROUP BY title
ORDER BY count(*) DESC

-- With subqueries
SELECT B.title, count(*)
FROM (SELECT A.inventory_id, B.film_id
	 FROM rental A
	 LEFT JOIN inventory B
	 ON A.inventory_id = B.inventory_id) C
LEFT JOIN film B
ON C.film_id = B.film_id
GROUP BY B.title
ORDER BY count(*) DESC

-- 7f. Write a query to display how much business, in dollars, each store brought in.

-- With joins only
SELECT sum(amount), store_id
FROM payment A
LEFT JOIN rental B
ON A.rental_id = B.rental_id
LEFT JOIN inventory C
ON B.inventory_id = C.inventory_id
GROUP BY store_id

-- With subqueries
SELECT sum(D.amount), C.store_id
FROM
(
SELECT A.rental_id, B.store_id
FROM rental A
INNER JOIN inventory B
ON A.inventory_id = B.inventory_id
) C
INNER JOIN payment D
ON D.rental_id = C.rental_id
GROUP BY C.store_id

-- 7g. Write a query to display for each store its store ID, city, and country.

SELECT store_id, city, country
FROM address A
INNER JOIN store B
ON A.address_id = B.address_id
INNER JOIN city C
ON A.city_id = C.city_id
INNER JOIN country D
ON C.country_id = D.country_id

-- 7h. List the top five genres in gross revenue in descending order. (Hint: you may need to use the following tables: category, film_category, inventory, payment, and rental.)

SELECT name, sum(amount)
FROM payment A
INNER JOIN rental B
ON A.rental_id = B.rental_id
INNER JOIN inventory C
ON B.inventory_id = C.inventory_id
INNER JOIN film_category D
ON C.film_id = D.film_id
INNER JOIN category E
ON D.category_id = E.category_id
GROUP BY name
ORDER BY sum(amount) DESC LIMIT 5

-- 8a. In your new role as an executive, you would like to have an easy way of viewing the Top five genres by gross revenue. Use the solution from the problem above to create a view. If you haven't solved 7h, you can substitute another query to create a view.

CREATE VIEW top_five_genres AS
SELECT name, sum(amount)
FROM payment A
INNER JOIN rental B
ON A.rental_id = B.rental_id
INNER JOIN inventory C
ON B.inventory_id = C.inventory_id
INNER JOIN film_category D
ON C.film_id = D.film_id
INNER JOIN category E
ON D.category_id = E.category_id
GROUP BY name
ORDER BY sum(amount) DESC LIMIT 5

-- 8b. How would you display the view that you created in 8a?

SELECT * FROM top_five_genres;

-- 8c. You find that you no longer need the view top_five_genres. Write a query to delete it.

DROP VIEW top_five_genres;