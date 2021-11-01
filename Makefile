build:
	docker build -t distributed_db .

init:
	docker exec -it database-1 mkdir /var/opt/mssql/ReplData/
	docker exec -it database-1 mkdir /var/opt/mssql/Data/

up:
	docker-compose -p distributed_database up