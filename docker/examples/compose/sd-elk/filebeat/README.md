# Filebeat docker container additional files

To ensure the smooth running of the Elasticsearch container some extra files are needed. Inside this folder you will find the following files:

### Dockerfile:
 
   - It contains the  link to the official filebeat docker image.
   - The configuration file filebeat.yml is copied inside the Filebeat image in the folder /usr/share/filebeat/.
   - A folder for logs is created and permission are assigned to it.  



### filebeat.yml:

 Five SD log files/folders are defined in the filebeat.inputs section as the sources where Filebeat must read:  
 
  - /jboss-log/server.log*   .....................  (JBoss log)
  - /sa-log/*/mwfm_active.log.xml  .........   (Service Activator log)
  - /sa-log/*/resmgr_active.log.xml    ....... (Service Activator log)
  - /snmp-log/SNMPGenericAdapter_1.log  ..... (SNMP Adapter log)
  - /uoc-log/server.log   .......................... (Unified OSS Console log) 
  
  

Then those five logs are read and sent to Logstash as the following type:
 
        wildfly     (JBoss log)
      
        sa_mwfm     (Service Activator log)
        
        sa_resmgr   (Service Activator log)
        
        snmp    	(SNMP Adapter log)
        
        uoc         (Unified OSS Console log) 