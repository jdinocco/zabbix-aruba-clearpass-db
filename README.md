# zabbix-aruba-clearpass-db
Get Radius and Tacacs+ authentications from DB

# Problem
Aruba Clearpass have a weird way to show metrics from authentication status, this scrap from the Database and import to Zabbix.

# Req
External access to the DB must be enabled in Clearpass, in this case it is postgresql.

https://community.arubanetworks.com/browse/articles/blogviewer?blogkey=b0b90e37-f071-4fa2-b68d-4d1c85b2da7e

To connect, install the "postgresql-client" package and execute the following command:
```bash
PGPASSWORD=VerYSECretPass=) psql -h 10.20.30.40 -d tipsLogDb -U appexternal
````
Note: There are several ways to pass the connection password as an argument, the one used is to export the PGPASSWORD variable with the password or modify the ".bashrc" file.

To get the metrics, the tables "tips_radius_session_log" are used for Radius and "tips_tacacs_session_log" for Tacacs +.

To obtain the metrics of successful or failed sessions, the value of the column "error_code" of both tables is taken as a reference, that is, if the value of the table is equal to "0" the connection was successful, if it is not equal to the value "0" and has another value the interaction was unsuccessful.

Reference: https://www.arubanetworks.com/techdocs/ClearPass/6.9/PolicyManager/Content/CPPM_UserGuide/SNMP_MIB_Events_Errors/Error_Codes.htm

```sql
tipsLogDb=> select count(id),error_code from tips_radius_session_log group by error_code order by count DESC;
  count  | error_code
---------+------------
 1130215 |          0
   66961 |       9002
   23209 |        216
    4685 |        215
    4056 |        206
     878 |       9015
     481 |        201
     317 |        106
       7 |        204
       6 |       9001
(10 filas)
```
Note: In the Tacacs + (tips_tacacs_session_log) table, in addition to the error_code column, the request_type column is equal to “TACACS_AUTHENTICATION” so as not to have duplicate metrics with the interactions of “TACACS_AUTHORIZATION”

Having the Querys of the data that we want to obtain, we put together a bash script to obtain the following metrics:

* Radius:
    * Fallidas (count)
    * Exitosas (count)
    * Fallidas (percent)
    * Exitosas (percent)
    * Total (count)

* Tacacs+:
    * Fallidas (count)
    * Exitosas (count)
    * Fallidas (percent)
    * Exitosas (percent)
    * Total (count)

* Wide (all metrics)
    * Fallidas (count)
    * Exitosas (count)
    * Fallidas (percent)
    * Exitosas (percent)
    * Total (count)

## Items
There is a single item that "triggers" the execution of the collector script "Get Data from DB" (interval 3m).

Note: the interval of the item “Get Data from DB” and the macro “{$ INTERVAL}” must be aligned in the same values so as not to have a discrepancy in the data.

## Control triggers
Two triggers are defined to control the obtaining of the data.

* "Data Sender Fail on {HOST.NAME}": detects if the string "failed: 1" is detected in the item's text

* "No Data from Script on {HOST.NAME}": detects if there is no data in the item after 10 minutes.

## Service triggers
TBD