#!/usr/bin/python

import json
import time
import urllib2, base64
from prometheus_client import start_http_server
from prometheus_client.core import GaugeMetricFamily, REGISTRY
import argparse
import yaml
from objectpath import Tree
import logging
import cookielib

DEFAULT_PORT=9158
DEFAULT_LOG_LEVEL='info'

class JsonPathCollector(object):
  def __init__(self, config):
    self._config = config
    self._initHttpClient = True

  def collect(self):
    config = self._config
    global request
    global cookie_jar

    if self._initHttpClient:
        logging.info("Init http client")
        cookie_jar = cookielib.CookieJar()
        opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cookie_jar))
        urllib2.install_opener(opener)
        request = urllib2.Request(config['json_data_url'])
        base64string = base64.b64encode('%s:%s' % (config['username'], config['password']))
        request.add_header("Authorization", "Basic %s" % base64string)
        self._initHttpClient = False

    try:
        response = urllib2.urlopen(request);
        result = json.loads(response.read())
        result_tree = Tree(result)
        # Fetching all the clusters
        hostname_array = list(result_tree.execute('$..hostName'))
        # for hostname in hostname_array:
        for metric_config in config['metrics']:
            # metric_name = '%s_%s{hostname="%s"}' % (config['metric_name_prefix'], metric_config['name'], hostname)
            metric_name = '%s_%s' % (config['metric_name_prefix'], metric_config['name'])
            metric_description = metric_config.get('description', '')
            metric_path = metric_config['path']
            value = list(result_tree.execute(metric_path))
            logging.debug("metric_name: {}, value for '{}' : {}".format(metric_name, metric_path, value))
            metric = GaugeMetricFamily(metric_name, metric_description, labels=['hostname'])
            for ind in range(len(value)):
                metric.add_metric([hostname_array[ind]], value[ind])
            yield metric
    except urllib2.URLError as e:
        logging.error(e.reason)
        self._initHttpClient = True
    except urllib2.HTTPError as e:
        logging.error(e.code)
        self._initHttpClient = True


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Expose metrics bu jsonpath for configured url')
  parser.add_argument('config_file_path', help='Path of the config file')
  args = parser.parse_args()

  with open(args.config_file_path) as config_file:
    config = yaml.load(config_file)
    log_level = config.get('log_level', DEFAULT_LOG_LEVEL)
    logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.getLevelName(log_level.upper()))
    exporter_port = config.get('exporter_port', DEFAULT_PORT)
    logging.debug("Config %s", config)
    logging.info('Starting server on port %s', exporter_port)
    start_http_server(exporter_port)
    REGISTRY.register(JsonPathCollector(config))
  while True: time.sleep(1)
