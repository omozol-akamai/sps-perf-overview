# Grafana Telemetry Reporting

Starting in version 17.1.0.0, it is possible to use the third-party Grafana analytics platform (https://grafana.com/grafana) to create graphs of telemetry data produced by Nominum components.

This document contains basic instructions for setup and configuration. Note that Grafana is not a productized piece of Nominum software and Nominum cannot provide full support for its operation. However, since it is a popular visualization tool, we are providing some guidance on how to use Grafana with Nominum telemetry.

## Requirements

In addition to a running N2 Platform, the following must be installed:

* Nominum Data Loader
* Nominum Influx DB
* Grafana (not provided by Nominum)

The N2 Platform must be configured so that the components are sending telemetry to the Nominum Kafka cluster, which is accessible by the Data Loader. The Influx database must be accessible by both the Data Loader and the Grafana instance. You do not need a separate Grafana instance; if there is already an existing Grafana, it can be used for this purpose.

## Installation

If they are not already installed, Data Loader, InfluxDB, and their dependencies should be installed from the `nom-vertica-17.1.0.0` tarball. Prior to the 17.1.0.0 platform release, the most recent tarball can be retrieved from Buildinum.

Grafana can be downloaded from their website:   https://grafana.com/grafana/download

Or installed using a package management system:

    shell# yum install grafana

## Configuration

Assuming that the `nom-telemetry` topic is already receiving telemetry messages from components within the N2 Platform, the following configuration steps are necessary.

### Data-Loader

Data Loader must be configured to load telemetry data from kafka into the Influx database.

    shell# nom-tell nom-data-loader
    data-loader> influxdb.update host=<influx host>
    data-loader> influxdb-loader.add name=telemetry database=n2 kafka={brokers=<kafka hosts>}) topic=nom-telemetry

These commands, along with some useful influx-tag commands, are included in a development script named `config-tags.sh` which is currently available in the `util` directory of the dataloader github repo.

### Influx

Influx must be configured by creating the N2 Database.

    shell# influx
    > create database n2

### Grafana

Grafana must be configured to recognize the Influx database as a valid datasource and to have at least one Nominum Telemetry dashboard.

To add a new datasource, log into Grafana (default username and password: `admin` / `admin`) and then select the `+ Add data source` button. In the window that pops up, you should change the following settings:

* Name: <datasource name of your choice>
* Type: InfluxDB
* Url: http://<influx host>:8086
* Access: proxy
* Database: n2
* User: admin
* Password: admin

The `Test` button should confirm that the datasource is accessible.

Then you should `Import` a new dashboard, chosen from the set of sample dashboards provided by Nominum and accessible from the `nom-grafana-tools` github repo, in the `dashboards` directory.

When importing a dashboard, you will be given the choice to select a datasource, at which point you should choose the datasource configured in the previous step.
