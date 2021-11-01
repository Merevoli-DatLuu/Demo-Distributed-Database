FROM mcr.microsoft.com/mssql/server:2019-latest
 
RUN /opt/mssql/bin/mssql-conf set sqlagent.enabled true 
 
CMD /opt/mssql/bin/sqlservr