CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA storefront;

CREATE TABLE storefront.actor(LIKE public.actor INCLUDING ALL);
INSERT INTO storefront.actor SELECT * FROM public.actor;

CREATE TABLE storefront.category(LIKE public.category INCLUDING ALL);
INSERT INTO storefront.category SELECT * FROM public.category;

CREATE TABLE storefront.language(LIKE public.language INCLUDING ALL);
INSERT INTO storefront.language SELECT * FROM public.language;

CREATE TABLE storefront.film(LIKE public.film INCLUDING ALL);
ALTER TABLE storefront.film ADD CONSTRAINT film_language_id FOREIGN KEY (language_id) REFERENCES storefront.language(language_id);
INSERT INTO storefront.film SELECT * FROM public.film;

CREATE TABLE storefront.film_category(LIKE public.film_category INCLUDING ALL);
ALTER TABLE storefront.film_category ADD CONSTRAINT film_category_film_id FOREIGN KEY (film_id) REFERENCES storefront.film(film_id);
ALTER TABLE storefront.film_category ADD CONSTRAINT film_category_category_id FOREIGN KEY (category_id) REFERENCES storefront.category(category_id);
INSERT INTO storefront.film_category SELECT * FROM public.film_category;

CREATE TABLE storefront.film_actor(LIKE public.film_actor INCLUDING ALL);
ALTER TABLE storefront.film_actor ADD CONSTRAINT film_actor_film_id FOREIGN KEY (film_id) REFERENCES storefront.film(film_id);
ALTER TABLE storefront.film_actor ADD CONSTRAINT film_actor_actor_id FOREIGN KEY (actor_id) REFERENCES storefront.actor(actor_id);
INSERT INTO storefront.film_actor SELECT * FROM public.film_actor;

CREATE SCHEMA directory;

CREATE TABLE directory.country(LIKE public.country INCLUDING ALL);
INSERT INTO directory.country SELECT * FROM public.country;

CREATE TABLE directory.city(LIKE public.city INCLUDING ALL);
ALTER TABLE directory.city ADD CONSTRAINT city_country_id FOREIGN KEY (country_id) REFERENCES directory.country(country_id);
INSERT INTO directory.city SELECT * FROM public.city;

CREATE TABLE directory.address(LIKE public.address INCLUDING ALL);
ALTER TABLE directory.address ADD CONSTRAINT address_city_id FOREIGN KEY (city_id) REFERENCES directory.city(city_id);
INSERT INTO directory.address SELECT * FROM public.address;

CREATE TABLE directory.person(
  person_id uuid PRIMARY KEY NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text,
  address_id int NOT NULL,
  active boolean NOT NULL,
  create_date date NOT NULL,
  last_update date NOT NULL,
  picture bytea,
  FOREIGN KEY (address_id) REFERENCES directory.address(address_id)
);

CREATE TABLE directory.customer_migration(
  customer_id int NOT NULL,
  generated_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  PRIMARY KEY (customer_id, generated_id)
);

INSERT INTO directory.customer_migration(customer_id)
SELECT customer_id FROM public.customer;

INSERT INTO directory.person(
	person_id,
	first_name,
	last_name,
	email,
	address_id,
	active,
	create_date,
	last_update
)
SELECT
	cm.generated_id AS person_id,
	cust.first_name,
	cust.last_name,
	cust.email,
	cust.address_id,
	cust.activebool AS active,
	cust.create_date,
	cust.last_update
FROM
	directory.customer_migration cm
INNER JOIN public.customer cust
ON
	cust.customer_id = cm.customer_id;

CREATE TABLE directory.staff_migration(
  staff_id int NOT NULL,
  generated_id uuid NOT NULL DEFAULT uuid_generate_v4(),
  PRIMARY KEY (staff_id, generated_id)
);

INSERT INTO directory.staff_migration(staff_id)
SELECT staff_id FROM public.staff;

INSERT INTO directory.person(
	person_id,
	first_name,
	last_name,
	email,
	address_id,
	active,
	create_date,
	last_update,
  picture
)
SELECT
	sm.generated_id AS person_id,
	staff.first_name,
	staff.last_name,
	staff.email,
	staff.address_id,
	staff.active,
	NOW() AS create_date,
	staff.last_update,
  staff.picture
FROM
	directory.staff_migration sm
INNER JOIN public.staff staff
ON
	staff.staff_id = sm.staff_id;

CREATE TABLE directory.person_role(
  person_id uuid NOT NULL,
  role_name text NOT NULL,
  PRIMARY KEY (person_id, role_name),
  FOREIGN KEY (person_id) REFERENCES directory.person(person_id)
);

INSERT INTO directory.person_role(person_id, role_name)
SELECT
  person_id,
  'customer' AS role_name
FROM
  directory.customer_migration;

INSERT INTO directory.person_role(person_id, role_name)
SELECT
  person_id,
  'staff' AS role_name
FROM 
  directory.staff_migration;

DROP TABLE customer_migration; 
DROP TABLE staff_migration;
