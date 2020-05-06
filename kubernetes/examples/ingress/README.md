Ingress deployment for supporting Service Director in a Kubernetes environment
==========================

An Ingress is a Kubernetes object that allows access to your Kubernetes services from outside the cluster. You configure Service Director access outside the cluster by defining a collection of rules that decide which inbound connections reach which SD services.

This ingress lets you keep your routing rules into a single resource, for example, you might want to redirect SD UI requests to example.com/ui/  and Service Activator UI requests to example.com/SAUI/ . With an Ingress, you can set this up without creating several LoadBalancers or exposing each service on the Node.

As an example we choose the Nginx ingres, and we will explain how to install it and configure it for SD.

How to Use Nginx Ingress Controller
-----

Start by creating the mandatory resources for Nginx Ingress in your cluster.

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml

If you are using Minikube you have to enable it this way:

    minikube addons enable ingress

If you are using a bare metal cluster then you have to enable it this way:
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/baremetal/service-nodeport.yaml


SD UI services needs to achieve session affinity using cookies when you are accessing them via an ingress. This cookie is created by the NGINX ingress and some extra lines should be added to your ingress definition. The following example will include those extra lines included in the "annotations" part.


Ingress Controller example
-----

We will explain how to create two services to demonstrate how the Ingress routes the SD requests. Prior to that you have to setup a DNS entry in your network called "example.com" that will point to the Kubernetes cluster's IP. Then we will configure a rule to send SD UI service and the SD CL service to two different urls.

This is the ingress.yaml example, it can be deployed with the "kubectl create -f ingress.yaml" command:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: servicedirector
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/affinity: cookie
    nginx.ingress.kubernetes.io/session-cookie-path: "*"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/session-cookie-name: "INGRESSCOOKIE"
spec:
  rules:
    - host: example.com
      http:
        paths:
          - path: /sd
            backend:
              serviceName: sd-cl
              servicePort: 8080
          - path: /sd-ui
            backend:
              serviceName: sd-ui
              servicePort: 3000

```

Once the ingress is deployed you can access the Service Director UI using the URL 

    http://example.com:xxxxx/sd-ui/login

You can also access the Service Activator native UI using the URL 

    http://example.com:xxxxx/sd/activator 

Where xxxxx is the external port in the ingress-nginx service. You can use the following command to obtain it:

    kubectl get services -n=ingress-nginx

    NAME            TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx   NodePort   10.109.145.140   <none>        80:30861/TCP,443:32291/TCP   24s

In this case the port is 30861
 