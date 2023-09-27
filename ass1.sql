-- COMP3311 22T3 Assignment 1
--
-- Fill in the gaps ("...") below with your code
-- You can add any auxiliary views/function that you like
-- The code in this file *MUST* load into an empty database in one pass
-- It will be tested as follows:
-- createdb test; psql test -f ass1.dump; psql test -f ass1.sql
-- Make sure it can load without error under these conditions


-- Q1: new breweries in Sydney in 2020

create or replace view Q1(brewery,suburb)
as
select b.name as brewery, l.town as suburb
from Breweries b 
	join Locations l on (l.id = b.located_in) 
Where b.founded = 2020 and l.metro = 'Sydney'
;

-- Q2: beers whose name is same as their style

create or replace view Q2(beer,brewery)
as
select b.name as beer, br.name as brewery
from Beers b 
	join Styles s on (s.id = b.style)
	join Brewed_by bb on (b.id = bb.beer)
	join Breweries br on (br.id = bb.brewery)
Where s.name = b.name
;

-- Q3: original Californian craft brewery

create or replace view h3(brewery,founded)
as
select b.name as brewery, b.founded as founded
from Breweries b 
	join Locations l on (b.located_in = l.id)
Where l.region = 'California'
;

create or replace view Q3(brewery,founded)
as
select brewery, founded
from h3 
Where founded = (select min(founded) from h3)
;

-- Q4: all IPA variations, and how many times each occurs

create or replace view Q4(style,count)
as
select s.name as style, count(*)
from Styles s left outer join Beers b on (b.style = s.id)
group by s.name
having s.name like '%IPA%'
;

-- Q5: all Californian breweries, showing precise location

create or replace view h5(brewery,location_id)
as
select b.name as brewery, b.located_in as location_id
from Breweries b 
	join Locations l on (b.located_in = l.id)
Where l.region = 'California'
;

create or replace view met_tow(brewery, metro, town)
as
select h.brewery as brewery, l.metro as metro, l.town as town 
from Locations l 
	join h5 h on (l.id = h.location_id)
;

create or replace view Q5(brewery,location)
as
select brewery, metro
from met_tow
Where town is null
union
select brewery, town
from met_tow
Where town is not null
;

-- Q6: strongest barrel-aged beer

create or replace view beer_and_brew(beer, brewery, s, s_id)
as
select b.name as beer, br.name as brewery, s.name, s.id
from Beers b
	join Brewed_by bb on (b.id = bb.beer)
	join Breweries br on (br.id = bb.brewery)
	join Styles s on (b.style = s.id)
;

create or replace view h6(beer,brewery,abv)
as
select b.name as beer, bb.brewery as brewery, b.abv as abv
from beer_and_brew bb
	join Beers b on (b.name = bb.beer) 
Where b.notes like '%barrel%aged%'
or b.notes like '%aged%barrels%'
or b.notes like '%aged%barrel%'
;

create or replace view Q6(beer,brewery,abv)
as
select h.beer, h.brewery, h.abv
from h6 h 
where h.abv = (select max(abv) from h6)
;

-- Q7: most popular hop

create or replace view h7(ing,num)
as
select i.name as ing, count(c.ingredient) as num
from Contains c
	join Ingredients i on (i.id = c.ingredient) where i.itype = 'hop'
group by i.name
;

create or replace view Q7(hop)
as
select ing as hop
from h7 
where num = (select max(num) from h7)
;

-- Q8: breweries that don't make IPA or Lager or Stout (any variation thereof)

create or replace view Q8(brewery)
as
select distinct br.name
from Breweries br
except 
select distinct bb.brewery
from beer_and_brew bb
Where bb.s like '%IPA%'
or bb.s like '%Lager%'
or bb.s like '%Stout%'
;

-- Q9: most commonly used grain in Hazy IPAs

create or replace view HIB(beer,num)
as
select b.id as beer, count(b.id) as num
from Beers b 
	join Styles s on (s.id = b.style) 
where s.name = 'Hazy IPA'
group by b.id, s.name
;

create or replace view h9(grain, num)
as
select i.name as grain, count(c.ingredient)
from HIB h
	join Contains c on (c.beer = h.beer)
	join Ingredients i on (i.id = c.ingredient) 
where i.itype = 'grain'
group by i.name
;
create or replace view Q9(grain)
as
select grain
from h9 
where num = (select max(num) from h9)
;

-- Q10: ingredients not used in any beer

create or replace view ing_unused(ing_id)
as
select i.id as ing_id 
from Ingredients i 
except 
select c.ingredient as ing_id 
from Contains c
;

create or replace view Q10(unused)
as
select i.name as unused 
from Ingredients i 
	join ing_unused iu on (iu.ing_id = i.id)
;

-- Q11: min/max abv for a given country

drop type if exists ABVrange cascade;
create type ABVrange as (minABV float, maxABV float);

create or replace function
	Q11(_country text) returns ABVrange
as $$
declare
	mini float;
	maxi float;
	b record;
begin
	select * into b from Locations l where l.country=_country;
	if (not found) then
		return (0,0)::ABVrange;
	end if;

	select max(be.abv)
	into maxi
	from Locations l
		join Breweries br on (br.located_in = l.id)
		join Brewed_by bb on (br.id = bb.brewery)
		join Beers be on (be.id = bb.beer)
		where l.country=_country;
	
	select min(be.abv)
	into mini
	from Locations l
		join Breweries br on (br.located_in = l.id)
		join Brewed_by bb on (br.id = bb.brewery)
		join Beers be on (be.id = bb.beer)
		where l.country=_country;

	return (mini::numeric(4,1), maxi::numeric(4,1))::ABVrange;
end;
$$
language plpgsql;

-- Q12: details of beers

drop type if exists BeerData cascade;
create type BeerData as (beer text, brewer text, info text);

create or replace function
	Q12(partial_name text) returns setof BeerData
as $$
...
$$
language plpgsql;
