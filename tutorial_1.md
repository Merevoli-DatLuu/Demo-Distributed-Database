### chạy compose 
```
make up
```

### khởi tạo thư mục chứa replication data
```
make init
```

### Khởi tạo Database Sale cho server 1
```
docker exec -it database-1 /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P Testing1234          
USE [master];                                                                                    
GO                                                                                                
CREATE DATABASE [Sales];                                                                         
GO 
```   

### Khởi tạo Database Sale cho server 2
```
docker exec -it database-2 /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P Testing1234          
USE [master];                                                                                    
GO                                                                                                
CREATE DATABASE [Sales];                                                                         
GO 
```   

### Chạy file server_1_sale.session
### Chạy file server_2_sale.session 