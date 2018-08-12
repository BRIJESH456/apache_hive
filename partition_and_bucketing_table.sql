--bucket properties
set hive.enforce.bucketing=true;
set hive.optimize.bucketmapjoin=true;

--with sorted table
CREATE  TABLE if not exists `orders_partition_with_bucket` (
  `order_id` int,
  `order_date` STRING ,
  `order_customer_id` int,
  `order_status` STRING)
partitioned by (data_dt string)
CLUSTERED BY(order_id) 
SORTED BY (order_id) INTO 5 BUCKETS
row format delimited
fields terminated by ','
LOCATION '/user/big-data-practice/text/orders_partition_with_bucket';

--static partition (default in hive)
insert overwrite table orders_partition_with_bucket(data_dt="2018-08-12")
select * from orders;

select * from orders_partition_with_bucket TABLESAMPLE(BUCKET 1 OUT OF 5 ON data_dt);

CREATE TABLE if not exists `order_items_partition_with_bucket` (
  `order_item_id` int,
  `order_item_order_id` int,
  `order_item_product_id` int,
  `order_item_quantity` int,
  `order_item_subtotal` float ,
  `order_item_product_price` float)
  partitioned by (data_dt string)
CLUSTERED BY(order_item_order_id) 
SORTED BY (order_item_order_id) INTO 9 BUCKETS
row format delimited
fields terminated by ','
LOCATION '/user/big-data-practice/text/order_items_partition_with_bucket';

insert overwrite table order_items_partition_with_bucket(data_dt="2018-08-12")
select * from order_items;

select * from order_items_partition_with_bucket TABLESAMPLE(BUCKET 1 OUT OF 9 ON data_dt);

select /*+ MAPJOIN(order_items_partition_with_bucket) */ orders_partition_with_bucket.* 
from orders_partition_with_bucket o ,order_items_partition_with_bucket oi 
where (o.data_dt = "2018-08-12" and oi.data_dt="2018-08-12") and o.order_id=oi.order_item_order_id;

--or

select /*+ MAPJOIN(order_items_partition_with_bucket) */ orders_partition_with_bucket.* 
from orders_partition_with_bucket o ,order_items_partition_with_bucket oi on(o.order_id=oi.order_item_order_id)
where o.data_dt = "2018-08-12" and oi.data_dt="2018-08-12";


--without sorted table

set hive.enforce.bucketing=true;
set hive.optimize.bucketmapjoin=true;

CREATE TABLE if not exists `orders_partition_with_bucket` (
  `order_id` int,
  `order_date` STRING ,
  `order_customer_id` int,
  `order_status` STRING)
partitioned by (data_dt string)
CLUSTERED BY(order_id) INTO 5 BUCKETS
row format delimited
fields terminated by ','
LOCATION '/user/big-data-practice/text/orders_partition_with_bucket';

--static partition (default in hive)
insert overwrite table orders_partition_with_bucket(data_dt="2018-08-12")
select * from orders;

select * from orders_partition_with_bucket TABLESAMPLE(BUCKET 1 OUT OF 5 ON data_dt);

CREATE TABLE if not exists `order_items_partition_with_bucket` (
  `order_item_id` int,
  `order_item_order_id` int,
  `order_item_product_id` int,
  `order_item_quantity` int,
  `order_item_subtotal` float ,
  `order_item_product_price` float)
  partitioned by (data_dt string)
CLUSTERED BY(order_item_order_id)  INTO 9 BUCKETS
row format delimited
fields terminated by ','
LOCATION '/user/big-data-practice/text/order_items_partition_with_bucket';

insert overwrite table order_items_partition_with_bucket(data_dt="2018-08-12")
select * from order_items;

select * from order_items_partition_with_bucket TABLESAMPLE(BUCKET 1 OUT OF 9 ON data_dt);

select /*+ MAPJOIN(order_items_partition_with_bucket) */ orders_partition_with_bucket.* 
from orders_partition_with_bucket o ,order_items_partition_with_bucket oi 
where (o.data_dt = "2018-08-12" and oi.data_dt="2018-08-12") and o.order_id=oi.order_item_order_id;

--or

select /*+ MAPJOIN(order_items_partition_with_bucket) */ orders_partition_with_bucket.* 
from orders_partition_with_bucket o ,order_items_partition_with_bucket oi on(o.order_id=oi.order_item_order_id)
where o.data_dt = "2018-08-12" and oi.data_dt="2018-08-12";

--now check the time taken to execute query for with or without sorted table.




