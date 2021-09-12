import sys

from nomgrafanatools.nomgrafanatools.grafanahttpapi import GrafanaHTTPAPI

if __name__ == '__main__':

    grafana_api = GrafanaHTTPAPI()

    grafana_api.add_influx_datasource()
    grafana_api.add_all_dashboards()