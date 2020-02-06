# Service Director integration with Prometheus/Grafana 

To ensure how SD Provisioning is performing in your system this examples shows how to integrate it with Prometheus. This tool does not try to solve problems outside of the metrics space, leaving those to other tools.

This example is a simplification of the [Kubernetes' one](/kubernetes/examples/prometheus/) as it does not provide the Kubernete's specific metrics. Please, check it for a more detailed explanation regarding Prometheus & Grafana.

## Model

The model to be deployed in this example will consist of:

1. Database
2. Service Provisioner
3. Data exporters
4. Prometheus
5. Grafana


### Database

As Service Provisioner requires an external database, for the purpose of this example we are using `containers.enterprisedb.com/edb/edb-as-lite:v11` which you can pull from EnterpriseDB container repository ([request access here](https://www.enterprisedb.com/repository-access-request?destination=node/1255704&resource=1255704&ma_formid=2098)).

**NOTE** For production environments you should either use an external, non-containerized database or create an image of your own, maybe based on official Oracle's [docker-images](https://github.com/oracle/docker-images).


### Service Provisioner

Service Provisioner deployment is configured to include **Self Monitor** module, that will provide the data used for the metrics. This module provides information in two ways:

- Log files.- Alarms are written to a log file in an XML format. This include, for example, that the running workflows have surpassed certain threshold.
- DB table.- Historical data, like *user sessions* or *worker threads* are stored in the database.

### Data exporters

Data exporters are the ones reading the information provide by the Service Director  **Self Monitor** module, and serving it to Prometheus properly. Two exported are used here: **Grok Exporter** and **SQL Exporter**.

#### Grok Exporter

[Grok Exporter](https://github.com/fstab/grok_exporter) is a tool to parse unstructured log data into structured metrics.

This exporter will read the alerts from Service Director **Self Monitor** tool written in a log file. This exporter reads the log file and exports the metrics in a format suitable for Prometheus.

#### SQL Exporter

[SQL Exporter](https://github.com/free/sql_exporter) is a configuration driven exporter that exposes metrics gathered from DBMSs, for use by the Prometheus monitoring system. Out of the box, it provides support for EnterpriseDB but any DBMS, for which a Go driver is available, may be monitored after rebuilding the binary with the DBMS driver included.

This exporter connects to the table and exports the database metrics in a format suitable for Prometheus.

### Prometheus

[Prometheus](https://prometheus.io) is an open-source systems monitoring and alerting toolkit. It will process the data provided by the exporters.

### Grafana

[Grafana](https://grafana.com) is an open source project for visualizing time-series data. It will show Prometheus data in a graphical format.


## Deployment

In order to deploy the model, this command has to be executed under the example's root directory:

```
docker-compose up -d
```

## Configuration

There still some manual steps left in order to properly configure Grafana.

First of all, access Grafana's interface using the exposed service URL:

```
http://localhost:33000/
```

Default user and password are `admin`/`admin`.

Prometheus url (`http://prometheus:9090`) has to be added as a source for the metrics in the *Configuration->Data Sources->Add Data Source* window.

Click on "Save&Test" and wait until the "Data source is working" message appears.


Last step is to import a Grafana dashboard. For this example it can be found [here](Self_Monitoring_metrics.json). To import a dashboard open *Dashboard>Manage*, hit the *Import* button, paste the content of the json, and click on *Load*.



## Undeployment

In order to undeploy the model, this command has to be executed under the example's root directory:

```
docker-compose down
```
