# Grafana dashboards additional Information

This folder contains the Grafana dashboards included in the example and th k8s deployment files.


## Kubernertes SD-SP images metrics dashboard

The following graphs shows metrics of the "Kubernertes SP metrics" dashboard during the following scenario:

- A DB instance is created for the SD-SP cluster.
- A SD-SP image instance is created after the DB instance is up 
- A SD-UI image instance is created after the SD-SP image instance is up
- Some minutes after the first SD-SP image instance is up, a second SD-SP image instance is created  



Main metrics after the deployment of two instances of SD-SP image 
-	Nearly 2 Gibs are used in the Kubernetes cluster
-	Nearly two cores are used for a standby SD-SP cluster
-	2 available SD-SP image instances are available in the cluster


  ![Import window](./images/image1.png)
  
Combined CPU usage of all pods in the deployment (SD+UOC+DB)
-	A first CPU burst is generated due to first SD-SP node deployment
-	A second CPU burst is generated due to second SD-SP node deployment
-	A sustained CPU usage remains after second SD-SP node deployment (standby SD cluster)


  ![Import window](./images/image2.png)
  
CPU usage of two instances of SD-SP image 
-	A first CPU burst is generated due to first SD node deployment
-	A second CPU burst is generated due to second SD node deployment
-	Sustained CPU usage remains after each node deployment (standby SD cluster)


  ![Import window](./images/image3.png)    

Individual CPU usage of all pods in the deployment (SD+UOC+DB) 
-	the yellow line is first CPU burst is generated due to first SD node deployment
-	the blue line is second CPU burst is generated due to first SD node deployment
-	the red line is CPU burst is generated due to UOC node deployment 


  ![Import window](./images/image4.png)
  
Total memory usage during the deployment of two instances of SD-SP image 
-	the green  line is is memory usage of 2 SDs + UOC + DB
-	Sustained CPU usage remains after each node deployment (standby SD cluster)


  ![Import window](./images/image5.png)  


Individual memory usage of every container during the deployment of two instances of SD-SP image 
-	the yellow line is memory usage of SD-SP first image instance 
-	the blue line is memory usage of SD-SP second image instance
-	the orange line is memory usage of SD-UI image instance
-	the green line is memory usage of DB instance




  ![Import window](./images/image6.png)
  
Total network traffic during the deployment of two instances of SD-SP image 
-	the two green line bursts are inbound traffic on DB instance coming from SD-SP image instances during setup
-	the two yellow line burst are outbound traffic of SD-SP image instances towards DB during setup


  ![Import window](./images/image7.png)  
  
Network traffic of every container during the deployment of two instances of SD-SP image  
-	the yellow line is outbound traffic of SD-SP first instance towards DB during setup
-	the blue line is outbound traffic of SD-SP second instance towards DB during setup
-	the red lines is inbound traffic of DB instance during SD-SP setup
-	there is some outbound traffic (yellow)  of first SD-SP image instance during SD-SP image second instance setup


  ![Import window](./images/image8.png)    
  
  
## Kubernertes SD-SP images metrics dashboard

The following graphs shows metrics of the "SP Self Monitoring metrics" dashboard during the following scenario:

- A DB instance is created for the SD-SP cluster.
- A SD-SP image instance is created after the DB instance is up 
- After the first SD-SP image instance is up, several SD-SP image instances are created and some scale up/down is done   
- A very low workflow threshold was setup in the Self Monitor config to raise some alerts quickly 


Main metrics after some scaling up/down of SD-SP nodes 
-	Information of what SD-SP nodes have been down and how many times 
-	A workflow alert threshold was raised 


  ![Import window](./images/image9.png)
  
Resource usage graphs recorded by SD-SP Self Monitoring tool
-	First graph (top left) displays Heap memory usage per SD-SP node 
-	Second graph (top right) displays Non heap memory usage per SD-SP node
-	Third graph (bottom left) displays worker threads per SD-SP node
-	Fourth graph (bottom right) displays activation threads per SD-SP node


  ![Import window](./images/image10.png)  
  
Resource usage graphs recorded by SD-SP Self Monitoring
-	First graph (top left) displays activation queue size per SD-SP node 
-	Second graph (top right) displays total jobs per SD-SP node
-	Third graph (bottom left) displays user sessions per SD-SP node



  ![Import window](./images/image11.png)    