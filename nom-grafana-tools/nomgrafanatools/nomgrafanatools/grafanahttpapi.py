import os
import requests
import json
import pytoml


class GrafanaHTTPAPI:
    def __init__(self, configfile='nom-grafana-tools-config.toml', dashboard_directory='dashboards/'):
        with open(configfile) as f:
            config = pytoml.load(f)
        gconf = config['Grafana Config']
        self.url = 'http://{}:{}'.format(gconf['hostname'], gconf['port'])
        self.auth = (gconf['username'], gconf['password'])
        self.dashboard_directory = dashboard_directory
        self.influx = config['Influx Config']
        self.current_organization = self.get_current_organziation()

    def _get(self, path):
        return requests.get('{}{}'.format(self.url, path), auth=self.auth)

    def _post(self, path, json_body):
        return requests.post(
            '{}{}'.format(self.url, path), auth=self.auth, json=json_body)

    def _put(self, path, json_body):
        return requests.put(
            '{}{}'.format(self.url, path), auth=self.auth, json=json_body)

    def get_datasources(self):
        response = self._get('/api/datasources')

        if response.status_code == 200:
            return json.loads(response.content)

        else:
            return response

    def add_influx_datasource(self):
        body = {
            'name': self.influx['datasource_name'], 'type': 'influxdb',
            'access': 'proxy',
            'url': 'http://{}:{}'.format(self.influx['hostname'],
                                         self.influx['port']),
            'basicAuth': False, 'database': self.influx['database'],
        }

        response = self._post('/api/datasources', body)

        if response.status_code == 200:
            return json.loads(response.content)

        else:
            return response

    def get_organizations(self):

        response = self._get('/api/orgs')

        if response.status_code == 200:
            return json.loads(response.content)

        else:
            return response

    def get_current_organziation(self):

        response = self._get('/api/org')

        if response.status_code == 200:
            return json.loads(response.content)

        else:
            return response

    def update_current_organization(self, orgname):

        json_body = {'name': orgname}

        response = self._put('/api/org', json_body)

        if response.status_code == 200:
            resp_json = json.loads(response.content)
            self.current_organization = resp_json
            return resp_json

        else:
            return response

    def add_organization(self, orgname):

        json_body = {'name': orgname}

        response = self._post('/api/orgs', json_body)

        if response.status_code == 200:
            return json.loads(response.content)

        else:
            return response

    def add_dashboard(self, dashboard_json):
        response = self._post('/api/dashboards/import', dashboard_json)

        return response

    def add_dashboard_from_file(self, filename):
        api_json = self.make_dashboard_json_wrapper(
            self.load_dashboard_json_from_file(filename)
        )

        if not api_json:
            return None

        return self.add_dashboard(api_json)

    def update_dashboard_from_file(self, filename):
        api_json = self.make_dashboard_json_wrapper(
            self.load_dashboard_json_from_file(filename)
        )

        api_json["overwrite"] = True

        return self.add_dashboard(api_json)

    @staticmethod
    def load_dashboard_json_from_file(filename):
        with open(filename, 'r') as f:
            try:
                dashboard_json = json.load(f)
            except ValueError:
                print "Could not parse json from file {}".format(filename)
                dashboard_json = None

        return dashboard_json

    @staticmethod
    def make_dashboard_json_wrapper(dashboard_json):
        try:
            loaded_inputs_json = dashboard_json['__inputs']
        except KeyError:
            print "Dashboard JSON is missing '__inputs' field."
            return None
        except TypeError:
            print "Dashboard JSON is of incorrect type."
            return None

        inputs_json = []

        for input_json in loaded_inputs_json:
            inputs_json.append({
                "name": input_json['name'],
                "value": input_json['label'],
                "type": input_json['type'],
                "pluginId": input_json['pluginId'],
            })

        wrapper_json = {
            "overwrite": False,
            "dashboard": dashboard_json,
            "inputs": inputs_json,
        }

        return wrapper_json

    def get_dashboard_filenames(self):
        f = []
        for (root, _, files) in os.walk(self.dashboard_directory):
            for name in files:
                f.append(os.path.join(root, name))
            break

        return f

    def add_all_dashboards(self):
        dashboard_filenames = self.get_dashboard_filenames()

        for f in dashboard_filenames:
            print "Adding dashboard from file '{}' ...".format(f)
            resp = self.add_dashboard_from_file(f)
            if not resp:
                print "Could not add dashboard from file '{}'.".format(f)
