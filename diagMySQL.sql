SELECT "

 ____  _____ ____  _   _ _____
|  _ \| ____| __ )| | | |_   _|
| | | |  _| |  _ \| | | | | |
| |_| | |___| |_) | |_| | | |
|____/|_____|____/ \___/  |_|



" as "DEBUT";

SELECT '# I N F O R M A T I O N S     G E N E R A L E S ' as '# ----------------------------------------------------------------------------------------------------------------------' ;
SELECT version();
SELECT 'SHOW DATABASES                                                                                                                           ' ;
SHOW DATABASES;
SELECT 'USERS                                                                                                                           ' ;
SELECT user,host,password_lifetime,account_locked,max_connections,max_user_connections,Repl_slave_priv,Super_priv from mysql.user    ;
SELECT 'CONFIG PARAMS                                                                                                                           ' ;
SHOW GLOBAL VARIABLES;
SELECT 'ENGINE INNODB STATUS                                                                                                                           ' ;
SHOW ENGINE INNODB STATUS ;
SELECT 'ENGINES                                                                                                                           ' ;
SHOW ENGINES ;
SELECT 'ENGINE REPARTITION                                                                                                                           ' ;
select table_schema, engine, count(1) from information_schema.tables group by table_schema, engine order by count(1) desc ;
SELECT 'MASTER STATUS                                                                                                                           ' ;
SHOW MASTER STATUS\G
SELECT '                                                                                                                           ' ;


SELECT '# D A T A B A S E S                   ' as '# ----------------------------------------------------------------------------------------------------------------------' ;
SELECT TABLE_SCHEMA AS `Database`,
TABLE_NAME AS `Table`, ENGINE,
ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024) AS `Size (MB)`
FROM information_schema.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
AND TABLE_SCHEMA NOT IN ('sys','performance_schema','information_schema')
AND ENGINE NOT IN ('MEMORY', 'PERFORMANCE_SCHEMA')
AND ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024) > 0
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;


SELECT
        TS.database_name
        ,TS.table_name
        ,IDS.last_update
        ,TS.n_rows
        ,TS.clustered_index_size
        ,TS.sum_of_other_index_sizes
FROM  mysql.innodb_table_stats TS
JOIN mysql.innodb_index_stats IDS
        ON IDS.database_name = TS.database_name
        AND IDS.table_name = TS.table_name
WHERE IDS.index_name = 'PRIMARY'
AND IDS.stat_name= 'size'
ORDER BY TS.n_rows DESC ;

SELECT '                                                                                                                           ' ;

SELECT '# I N N O D B   S T A T S                   ' as '# ----------------------------------------------------------------------------------------------------------------' ;
SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       format_bytes(SUM(IF(ibp.compressed_size = 0, 16384, compressed_size))) AS allocated,
       format_bytes(SUM(ibp.data_size)) AS data,
       COUNT(ibp.page_number) AS pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, 0)) AS pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, 0)) AS pages_old,
       ROUND(SUM(ibp.number_records)/COUNT(DISTINCT ibp.index_name)) AS rows_cached
  FROM information_schema.innodb_buffer_page ibp
 WHERE table_name IS NOT NULL
 GROUP BY object_schema
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC ;

SELECT IF(LOCATE('.', ibp.table_name) = 0, 'InnoDB System', REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', 1), '`', '')) AS object_schema,
       REPLACE(SUBSTRING_INDEX(ibp.table_name, '.', -1), '`', '') AS object_name,
       format_bytes(SUM(IF(ibp.compressed_size = 0, 16384, compressed_size))) AS allocated,
       format_bytes(SUM(ibp.data_size)) AS data,
       COUNT(ibp.page_number) AS pages,
       COUNT(IF(ibp.is_hashed = 'YES', 1, 0)) AS pages_hashed,
       COUNT(IF(ibp.is_old = 'YES', 1, 0)) AS pages_old,
       ROUND(SUM(ibp.number_records)/COUNT(DISTINCT ibp.index_name)) AS rows_cached
  FROM information_schema.innodb_buffer_page ibp
 WHERE table_name IS NOT NULL
 GROUP BY object_schema, object_name
 ORDER BY SUM(IF(ibp.compressed_size = 0, 16384, compressed_size)) DESC ;


SELECT '                                                                                                                           ' ;

SELECT '# P E R F O R M A N C E _ S C H E M A ' as '# ----------------------------------------------------------------------------------------------------------------------' ;
SELECT '- T O P   10   D I G E S T S ' ;
SELECT
  DIGEST
 , SQL_TEXT
 , CURRENT_SCHEMA
 , OBJECT_NAME
 , OBJECT_TYPE
 , ROUND(timer_wait*10E-10, 3) as 'Elapsed (ms)'
 , ROUND(LOCK_TIME*10E-10, 3) as 'Locked (ms)'
 , ROWS_EXAMINED, ROWS_SENT, ROWS_AFFECTED
 , CREATED_TMP_DISK_TABLES, CREATED_TMP_TABLES
 , SELECT_FULL_JOIN, SELECT_RANGE_CHECK, SELECT_SCAN
 , SORT_MERGE_PASSES, SORT_ROWS, SORT_SCAN
 , NO_INDEX_USED, NO_GOOD_INDEX_USED
 , EVENT_NAME, SOURCE
FROM performance_schema.events_statements_current
ORDER BY TIMER_WAIT DESC LIMIT 10\G

SELECT '                                                                                                                           ' ;

SELECT '- T O P   10   E V T S U M   B Y   D I G E S T S ';
SELECT
ESSBD.DIGEST AS 'QUERY_ID'
,ESSBD.FIRST_SEEN AS 'FIRST_SEEN'
,ESSBD.LAST_SEEN AS 'LAST_SEEN'
,ESSBD.DIGEST_TEXT AS 'NORMALIZED_SQLTEXT'
,ESSBD.COUNT_STAR AS 'EXECUTES'
,ROUND(ESSBD.SUM_TIMER_WAIT*1E-9, 0) AS 'TOTAL_ELAPSED_MS'
,ROUND(ESSBD.AVG_TIMER_WAIT*1E-9, 0) AS 'AVERAGE_ELAPSED_MS'
,ROUND(ESSBD.MIN_TIMER_WAIT*1E-9, 0) AS 'MIN_ELAPSED_MS'
,ROUND(ESSBD.MAX_TIMER_WAIT*1E-9, 0) AS 'MAX_ELAPSED_MS'
,ROUND(ESSBD.SUM_LOCK_TIME*1E-9, 0) AS 'TOTAL_LOCK_TIME_MS'
,ROUND((ESSBD.SUM_LOCK_TIME*1E-9)/ESSBD.COUNT_STAR, 0) AS 'AVERAGE_LOCK_TIME_MS'
,IFNULL((SELECT ESHL.SQL_TEXT FROM performance_schema.events_statements_history_long ESHL
    WHERE ESHL.DIGEST=ESSBD.DIGEST LIMIT 1
),'N/A') AS 'SQL_SAMPLE'
,ESSBD.SUM_ROWS_AFFECTED AS 'ROWS_AFFECTED'
,ESSBD.SUM_ROWS_SENT AS 'ROWS_SENT'
,ESSBD.SUM_ROWS_EXAMINED AS 'ROWS_EXAMINED'
,ESSBD.SUM_CREATED_TMP_DISK_TABLES AS 'CREATED_TMP_DISK_TABLES'
,ESSBD.SUM_CREATED_TMP_TABLES AS 'CREATED_TMP_TABLES'
,ESSBD.SUM_SELECT_FULL_JOIN AS 'SELECT_FULL_JOIN'
,ESSBD.SUM_SELECT_FULL_RANGE_JOIN AS 'SELECT_FULL_RANGE_JOIN'
,ESSBD.SUM_SELECT_RANGE AS 'SELECT_RANGE'
,ESSBD.SUM_SELECT_RANGE_CHECK AS 'SELECT_RANGE_CHECK'
,ESSBD.SUM_SELECT_SCAN AS 'SELECT_SCAN'
,ESSBD.SUM_SORT_MERGE_PASSES AS 'SORT_MERGE_PASSES'
,ESSBD.SUM_SORT_RANGE AS 'SORT_RANGE'
,ESSBD.SUM_SORT_ROWS AS 'SORT_ROWS'
,ESSBD.SUM_SORT_SCAN AS 'SORT_SCAN'
,ESSBD.SUM_NO_INDEX_USED AS 'NO_INDEX_USED'
,ESSBD.SUM_NO_GOOD_INDEX_USED AS 'NO_GOOD_INDEX_USED'
FROM performance_schema.events_statements_summary_by_digest ESSBD
WHERE LAST_SEEN >= DATE_FORMAT(NOW(), '%Y-%m-%d %H:00:00')
AND DIGEST IS NOT NULL
ORDER BY ESSBD.AVG_TIMER_WAIT DESC
LIMIT 10 \G

SELECT '                                                                                                                           ' ;

SELECT '- T O P   10   F I L E    A C T I V I T Y ';
SELECT format_path(file_name) AS file,
       count_read,
       format_bytes(sum_number_of_bytes_read) AS total_read,
       format_bytes(IFNULL(sum_number_of_bytes_read / count_read, 0)) AS avg_read,
       count_write,
       format_bytes(sum_number_of_bytes_write) AS total_written,
       format_bytes(IFNULL(sum_number_of_bytes_write / count_write, 0.00)) AS avg_write,
       format_bytes(sum_number_of_bytes_read + sum_number_of_bytes_write) AS total,
       IFNULL(ROUND(100-((sum_number_of_bytes_read/(sum_number_of_bytes_read+sum_number_of_bytes_write))*100), 2), 0.00) AS write_pct
  FROM performance_schema.file_summary_by_instance
  WHERE count_read > 0
 ORDER BY sum_number_of_bytes_read + sum_number_of_bytes_write DESC;

SELECT '                                                                                                                           ' ;

SELECT '- I O   G L O B A L   B Y   W A I T       ';
SELECT SUBSTRING_INDEX(event_name, '/', -2) event_name,
       count_star,
       format_time(sum_timer_wait) total_latency,
       format_time(avg_timer_wait) avg_latency,
       format_time(max_timer_wait) max_latency,
       format_time(sum_timer_read) read_latency,
       format_time(sum_timer_write) write_latency,
       format_time(sum_timer_misc) misc_latency,
       count_read,
       format_bytes(sum_number_of_bytes_read) total_read,
       format_bytes(IFNULL(sum_number_of_bytes_read / count_read, 0)) avg_read,
       count_write,
       format_bytes(sum_number_of_bytes_write) total_written,
       format_bytes(IFNULL(sum_number_of_bytes_write / count_write, 0)) avg_written
  FROM performance_schema.file_summary_by_event_name
 WHERE event_name LIKE 'wait/io/file/%'
   AND count_star > 0
 ORDER BY sum_timer_wait DESC;

SELECT '                                                                                                                           ' ;

SELECT '- M E M O R Y   B Y   U S E R       ';
SELECT `user`,
       SUM(current_count_used) AS current_count_used,
       SUM(current_number_of_bytes_used) AS current_allocated,
       SUM(current_number_of_bytes_used) / SUM(current_count_used) AS current_avg_alloc,
       MAX(current_number_of_bytes_used) AS current_max_alloc,
       SUM(sum_number_of_bytes_alloc) AS total_allocated
  FROM performance_schema.memory_summary_by_user_by_event_name
 GROUP BY `user`
 ORDER BY SUM(current_number_of_bytes_used) DESC;

SELECT '                                                                                                                           ' ;

SELECT '- M E M O R Y   A L L O C A T E D       ';
SELECT SUM(CURRENT_NUMBER_OF_BYTES_USED) total_allocated
  FROM performance_schema.memory_summary_global_by_event_name;

SELECT '                                                                                                                           ' ;

SELECT '- G L O B A L   W A I T S               ';

SELECT event_name AS event,
       count_star AS total_events,
       sys.format_time(sum_timer_wait) AS total_latency,
       sys.format_time(avg_timer_wait) AS avg_latency,
       sys.format_time(max_timer_wait) AS max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE event_name != 'idle'
   AND sum_timer_wait > 0
 ORDER BY sum_timer_wait DESC;

SELECT '                                                                                                                           ' ;

SELECT '- B L O C K E D   S E S S I O N S ';
 SELECT IF(pps.name = 'thread/sql/one_connection',
CONCAT(ips.user, '@', ips.host),
REPLACE(name, 'thread/', '')) user,
db,
command,
state,
time,
event_name AS last_wait,
IF(timer_wait IS NULL,
'Still Waiting',
timer_wait/1000000) last_wait_usec,
source
FROM performance_schema.events_waits_current
JOIN performance_schema.threads pps USING (thread_id)
LEFT JOIN information_schema.processlist ips ON pps.processlist_id = ips.id;


SELECT '                                                                                                                           ' ;

SELECT '- U N U S E D   I N D E X E S  ';

SELECT object_schema,
       object_name,
       index_name
  FROM performance_schema.table_io_waits_summary_by_index_usage
 WHERE index_name IS NOT NULL
   AND count_star = 0
   AND object_schema != 'mysql'
 ORDER BY object_schema, object_name;

SELECT '                                                                                                                           ' ;

SELECT '- T O P   1 0   Q U E R I E S   W I T H   F U L L   T A B L E   S C A N S  ';

SELECT DIGEST_TEXT AS QUERY,
       SCHEMA_NAME AS db,
       COUNT_STAR AS exec_count,
       SUM_NO_INDEX_USED AS no_index_used_count,
       SUM_NO_GOOD_INDEX_USED AS no_good_index_used_count,
       ROUND((SUM_NO_INDEX_USED / COUNT_STAR) * 100) AS no_index_used_pct,
       SUM_ROWS_SENT AS rows_sent,
       SUM_ROWS_EXAMINED AS rows_examined,
       ROUND(SUM_ROWS_SENT/COUNT_STAR) AS rows_sent_avg,
       ROUND(SUM_ROWS_EXAMINED/COUNT_STAR) AS rows_examined_avg,
       FIRST_SEEN AS first_seen,
       LAST_SEEN AS last_seen,
       DIGEST AS digest
  FROM performance_schema.events_statements_summary_by_digest
 WHERE SUM_NO_INDEX_USED > 0
    OR SUM_NO_GOOD_INDEX_USED > 0
ORDER BY no_index_used_pct DESC, exec_count DESC LIMIT 10 \G


SELECT "

 _____ ___ _   _
|  ___|_ _| \ | |
| |_   | ||  \| |
|  _|  | || |\  |
|_|   |___|_| \_|



" as "FIN" ;

exit

