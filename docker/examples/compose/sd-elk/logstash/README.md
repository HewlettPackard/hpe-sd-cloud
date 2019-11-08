# Logstash docker container additional files

To ensure the smooth running of the Logstash container some extra files are needed. Inside this folder you will find the following files:

### logstash.conf:
 
 It contains the configuration file that is used to receive data from Filebeat (port 5044) , format the logs and send them to Elasticsearch.
 
 There are four SD logs types that are received form Filebeat :
 
        wildfly  (JBoss log)
      
        sa_mwfm    (Service Activator log)
        
        sa_resmgr (Service Activator log)
        
        uoc      (Unified OSS Console log) 
        
         
These logs are transformed in the pipeline section and sent to Elasticsearch in the following format:
 
        wildfly-YYYY.MM.dd    (JBoss log)
      
        sa_mwfm-YYYY.MM.dd    (Service Activator log)
        
        sa_resmgr-YYYY.MM.dd  (Service Activator log)
        
        uoc-YYYY.MM.dd        (Unified OSS Console log)  
         





  