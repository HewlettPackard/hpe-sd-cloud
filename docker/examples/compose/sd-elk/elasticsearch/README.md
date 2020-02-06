# Elasticsearch docker container additional files

To ensure the smooth running of the Elasticsearch container some extra files are needed. Inside this folder you will find the following files:

### Dockerfile:
 
   - It contains the  link to the official Elasticsearch docker image.
   - The configuration file elasticsearch.yml is copied inside the Elasticsearch image in the folder /usr/share/elasticsearch/config/.
   - Elasticsearch is executed with INFO loglevel, if you need more log information you can change it to DEBUG   



### elasticsearch.yml:

 It contains the minimal settings required to run it: 
 
   - cluster.name: A node can only join a cluster when it shares its cluster.name with all the other nodes in the cluster. 
                   We setup a default name, but you can change it to an appropriate name which describes the purpose of the cluster.
   - network.host: By default, we setup Elasticsearch to bind to loopback addresses only. 
                   This is sufficient to run a single node on a server.
   - discovery.zen.minimum_master_nodes: To prevent data loss, it is vital to configure this setting so that each master-eligible 
                   node knows the minimum number of master-eligible nodes that must be visible in order to form a cluster.   

**IMPORTANT**:  If you get this error running the example

     max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]

You have to increase this parameter in your K8s cluster machines using this command

      /sbin/sysctl -w vm.max_map_count=262144 
      
or add the following line to the /etc/sysctl.conf file

      vm.max_map_count = 262144
      
      
