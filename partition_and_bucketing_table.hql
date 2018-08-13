--bucket properties
set hive.enforce.bucketing=true;
set hive.optimize.bucketmapjoin=true;

--with sorted table
dfs -mkdir /user/big-data-practice/text/orders_partition_with_bucket_with_sorted;

CREATE  TABLE if not exists `orders_partition_with_bucket_with_sorted` (
  `order_id` int,
  `order_date` STRING ,
  `order_customer_id` int,
  `order_status` STRING)
partitioned by (data_dt string)
CLUSTERED BY(order_id) 
SORTED BY (order_id) INTO 5 BUCKETS
row format delimited
fields terminated by ','
LOCATION '/user/big-data-practice/text/orders_partition_with_bucket_with_sorted';

--static partition (default in hive)
insert overwrite table orders_partition_with_bucket_with_sorted partition(data_dt="2018-08-12")
select * from orders;

dfs -mkdir /user/big-data-practice/text/order_items_partition_with_bucket_with_sorted;

CREATE TABLE if not exists `order_items_partition_with_bucket_with_sorted` (
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
LOCATION '/user/big-data-practice/text/order_items_partition_with_bucket_with_sorted';

insert overwrite table order_items_partition_with_bucket_with_sorted partition(data_dt="2018-08-12")
select * from order_items;

describe formatted orders_partition_with_bucket_with_sorted;

# col_name            	data_type           	comment             
	 	 
order_id            	int                 	                    
order_date          	string              	                    
order_customer_id   	int                 	                    
order_status        	string              	                    
	 	 
# Partition Information	 	 
# col_name            	data_type           	comment             
	 	 
data_dt             	string              	                    
	 	 
# Detailed Table Information	 	 
Database:           	retail_db           	 
Owner:              	cloudera            	 
CreateTime:         	Mon Aug 13 11:30:26 PDT 2018	 
LastAccessTime:     	UNKNOWN             	 
Protect Mode:       	None                	 
Retention:          	0                   	 
Location:           	hdfs://quickstart.cloudera:8020/user/big-data-practice/text/orders_partition_with_bucket_without_sorted	 
Table Type:         	MANAGED_TABLE       	 
Table Parameters:	 	 
	transient_lastDdlTime	1534185026          
	 	 
# Storage Information	 	 
SerDe Library:      	org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe	 
InputFormat:        	org.apache.hadoop.mapred.TextInputFormat	 
OutputFormat:       	org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat	 
Compressed:         	No                  	 
Num Buckets:        	5                   	 
Bucket Columns:     	[order_id]          	 
Sort Columns:       	[]                  	 
Storage Desc Params:	 	 
	field.delim         	,                   
	serialization.format	,                   
Time taken: 0.115 seconds, Fetched: 35 row(s)

describe formatted order_items_partition_with_bucket_with_sorted;
OK
# col_name            	data_type           	comment             
	 	 
order_item_id       	int                 	                    
order_item_order_id 	int                 	                    
order_item_product_id	int                 	                    
order_item_quantity 	int                 	                    
order_item_subtotal 	float               	                    
order_item_product_price	float               	                    
	 	 
# Partition Information	 	 
# col_name            	data_type           	comment             
	 	 
data_dt             	string              	                    
	 	 
# Detailed Table Information	 	 
Database:           	retail_db           	 
Owner:              	cloudera            	 
CreateTime:         	Mon Aug 13 11:27:18 PDT 2018	 
LastAccessTime:     	UNKNOWN             	 
Protect Mode:       	None                	 
Retention:          	0                   	 
Location:           	hdfs://quickstart.cloudera:8020/user/big-data-practice/text/order_items_partition_with_bucket_with_sorted	 
Table Type:         	MANAGED_TABLE       	 
Table Parameters:	 	 
	SORTBUCKETCOLSPREFIX	TRUE                
	transient_lastDdlTime	1534184838          
	 	 
# Storage Information	 	 
SerDe Library:      	org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe	 
InputFormat:        	org.apache.hadoop.mapred.TextInputFormat	 
OutputFormat:       	org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat	 
Compressed:         	No                  	 
Num Buckets:        	9                   	 
Bucket Columns:     	[order_item_order_id]	 
Sort Columns:       	[Order(col:order_item_order_id, order:1)]	 
Storage Desc Params:	 	 
	field.delim         	,                   
	serialization.format	,                   
Time taken: 0.115 seconds, Fetched: 38 row(s)


select * from orders_partition_with_bucket_with_sorted TABLESAMPLE(BUCKET 1 OUT OF 5 ON order_id);
select * from order_items_partition_with_bucket_with_sorted TABLESAMPLE(BUCKET 1 OUT OF 9 ON order_item_order_id);

select /*+ MAPJOIN(oi) */ o.* 
from orders_partition_with_bucket_with_sorted o ,order_items_partition_with_bucket_with_sorted oi 
where (o.data_dt = "2018-08-12" and oi.data_dt="2018-08-12") and o.order_id=oi.order_item_order_id; --40.451 seconds

hive> explain select /*+ MAPJOIN(oi) */ o.* 
    > from orders_partition_with_bucket_with_sorted o ,order_items_partition_with_bucket_with_sorted oi 
    > where (o.data_dt = "2018-08-12" and oi.data_dt="2018-08-12") and o.order_id=oi.order_item_order_id;
OK
STAGE DEPENDENCIES:
  Stage-4 is a root stage
  Stage-3 depends on stages: Stage-4
  Stage-0 is a root stage

STAGE PLANS:
  Stage: Stage-4
    Map Reduce Local Work
      Alias -> Map Local Tables:
        o 
          Fetch Operator
            limit: -1
      Alias -> Map Local Operator Tree:
        o 
          TableScan
            alias: o
            Statistics: Num rows: 68883 Data size: 2931061 Basic stats: COMPLETE Column stats: NONE
            HashTable Sink Operator
              condition expressions:
                0 {order_id} {order_date} {order_customer_id} {order_status} {data_dt}
                1 {order_item_order_id} {data_dt}
              keys:
                0 order_id (type: int)
                1 order_item_order_id (type: int)

  Stage: Stage-3
    Map Reduce
      Map Operator Tree:
          TableScan
            alias: oi
            Statistics: Num rows: 172198 Data size: 5236682 Basic stats: COMPLETE Column stats: NONE
            Map Join Operator
              condition map:
                   Inner Join 0 to 1
              condition expressions:
                0 {order_id} {order_date} {order_customer_id} {order_status} {data_dt}
                1 {order_item_order_id} {data_dt}
              keys:
                0 order_id (type: int)
                1 order_item_order_id (type: int)
              outputColumnNames: _col0, _col1, _col2, _col3, _col4, _col8, _col13
              Statistics: Num rows: 189417 Data size: 5760350 Basic stats: COMPLETE Column stats: NONE
              Filter Operator
                predicate: (((_col4 = '2018-08-12') and (_col13 = '2018-08-12')) and (_col0 = _col8)) (type: boolean)
                Statistics: Num rows: 23677 Data size: 720039 Basic stats: COMPLETE Column stats: NONE
                Select Operator
                  expressions: _col0 (type: int), _col1 (type: string), _col2 (type: int), _col3 (type: string), _col4 (type: string)
                  outputColumnNames: _col0, _col1, _col2, _col3, _col4
                  Statistics: Num rows: 23677 Data size: 720039 Basic stats: COMPLETE Column stats: NONE
                  File Output Operator
                    compressed: false
                    Statistics: Num rows: 23677 Data size: 720039 Basic stats: COMPLETE Column stats: NONE
                    table:
                        input format: org.apache.hadoop.mapred.TextInputFormat
                        output format: org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat
                        serde: org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe
      Local Work:
        Map Reduce Local Work

  Stage: Stage-0
    Fetch Operator
      limit: -1

Time taken: 0.245 seconds, Fetched: 63 row(s)


--without sorted table

set hive.enforce.bucketing=true;
set hive.optimize.bucketmapjoin=true;

dfs -mkdir /user/big-data-practice/text/orders_partition_with_bucket_without_sorted;

CREATE TABLE if not exists `orders_partition_with_bucket_without_sorted` (
  `order_id` int,
  `order_date` STRING ,
  `order_customer_id` int,
  `order_status` STRING)
partitioned by (data_dt string)
CLUSTERED BY(order_id) INTO 5 BUCKETS
row format delimited
fields terminated by ','
LOCATION '/user/big-data-practice/text/orders_partition_with_bucket_without_sorted';

--static partition (default in hive)
insert overwrite table orders_partition_with_bucket_without_sorted partition(data_dt="2018-08-12")
select * from orders;

dfs -mkdir /user/big-data-practice/text/order_items_partition_with_bucket_without_sorted;

CREATE TABLE if not exists `order_items_partition_with_bucket_without_sorted` (
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
LOCATION '/user/big-data-practice/text/order_items_partition_with_bucket_without_sorted';

insert overwrite table order_items_partition_with_bucket_without_sorted partition(data_dt="2018-08-12")
select * from order_items;

hive> describe formatted orders_partition_with_bucket_without_sorted;
OK
# col_name            	data_type           	comment             
	 	 
order_id            	int                 	                    
order_date          	string              	                    
order_customer_id   	int                 	                    
order_status        	string              	                    
	 	 
# Partition Information	 	 
# col_name            	data_type           	comment             
	 	 
data_dt             	string              	                    
	 	 
# Detailed Table Information	 	 
Database:           	retail_db           	 
Owner:              	cloudera            	 
CreateTime:         	Mon Aug 13 11:30:26 PDT 2018	 
LastAccessTime:     	UNKNOWN             	 
Protect Mode:       	None                	 
Retention:          	0                   	 
Location:           	hdfs://quickstart.cloudera:8020/user/big-data-practice/text/orders_partition_with_bucket_without_sorted	 
Table Type:         	MANAGED_TABLE       	 
Table Parameters:	 	 
	transient_lastDdlTime	1534185026          
	 	 
# Storage Information	 	 
SerDe Library:      	org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe	 
InputFormat:        	org.apache.hadoop.mapred.TextInputFormat	 
OutputFormat:       	org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat	 
Compressed:         	No                  	 
Num Buckets:        	5                   	 
Bucket Columns:     	[order_id]          	 
Sort Columns:       	[]                  	 
Storage Desc Params:	 	 
	field.delim         	,                   
	serialization.format	,                   
Time taken: 0.107 seconds, Fetched: 35 row(s)


select * from orders_partition_with_bucket_without_sorted TABLESAMPLE(BUCKET 1 OUT OF 5 ON order_id);
select * from order_items_partition_with_bucket_without_sorted TABLESAMPLE(BUCKET 1 OUT OF 9 ON order_item_order_id);

select /*+ MAPJOIN(oi) */ o.* 
from orders_partition_with_bucket_without_sorted  o ,order_items_partition_with_bucket_without_sorted oi 
where (o.data_dt = "2018-08-12" and oi.data_dt="2018-08-12") and o.order_id=oi.order_item_order_id; --Time taken: 40.761 seconds,

hive> explain select /*+ MAPJOIN(oi) */ o.* 
    > from orders_partition_with_bucket_without_sorted  o ,order_items_partition_with_bucket_without_sorted oi 
    > where (o.data_dt = "2018-08-12" and oi.data_dt="2018-08-12") and o.order_id=oi.order_item_order_id;
OK
STAGE DEPENDENCIES:
  Stage-4 is a root stage
  Stage-3 depends on stages: Stage-4
  Stage-0 is a root stage

STAGE PLANS:
  Stage: Stage-4
    Map Reduce Local Work
      Alias -> Map Local Tables:
        o 
          Fetch Operator
            limit: -1
      Alias -> Map Local Operator Tree:
        o 
          TableScan
            alias: o
            Statistics: Num rows: 68883 Data size: 2931061 Basic stats: COMPLETE Column stats: NONE
            HashTable Sink Operator
              condition expressions:
                0 {order_id} {order_date} {order_customer_id} {order_status} {data_dt}
                1 {order_item_order_id} {data_dt}
              keys:
                0 order_id (type: int)
                1 order_item_order_id (type: int)

  Stage: Stage-3
    Map Reduce
      Map Operator Tree:
          TableScan
            alias: oi
            Statistics: Num rows: 172198 Data size: 5236682 Basic stats: COMPLETE Column stats: NONE
            Map Join Operator
              condition map:
                   Inner Join 0 to 1
              condition expressions:
                0 {order_id} {order_date} {order_customer_id} {order_status} {data_dt}
                1 {order_item_order_id} {data_dt}
              keys:
                0 order_id (type: int)
                1 order_item_order_id (type: int)
              outputColumnNames: _col0, _col1, _col2, _col3, _col4, _col8, _col13
              Statistics: Num rows: 189417 Data size: 5760350 Basic stats: COMPLETE Column stats: NONE
              Filter Operator
                predicate: (((_col4 = '2018-08-12') and (_col13 = '2018-08-12')) and (_col0 = _col8)) (type: boolean)
                Statistics: Num rows: 23677 Data size: 720039 Basic stats: COMPLETE Column stats: NONE
                Select Operator
                  expressions: _col0 (type: int), _col1 (type: string), _col2 (type: int), _col3 (type: string), _col4 (type: string)
                  outputColumnNames: _col0, _col1, _col2, _col3, _col4
                  Statistics: Num rows: 23677 Data size: 720039 Basic stats: COMPLETE Column stats: NONE
                  File Output Operator
                    compressed: false
                    Statistics: Num rows: 23677 Data size: 720039 Basic stats: COMPLETE Column stats: NONE
                    table:
                        input format: org.apache.hadoop.mapred.TextInputFormat
                        output format: org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat
                        serde: org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe
      Local Work:
        Map Reduce Local Work

  Stage: Stage-0
    Fetch Operator
      limit: -1

Time taken: 0.211 seconds, Fetched: 63 row(s)
