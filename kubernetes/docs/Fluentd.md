Fluentd is, a data collector used to process logs and then ship them to Elasticsearch for indexing and storage. Fluentd allows to unify data collection and consumption for better use and understanding of data.

## Fluentd Configuration File

Fluentd supports `Event Routing`, this is, capturing logs and sending them to multiple outputs.

Input sources are defined by `<source>` directive and output plugins use `<match>`.

Configuration example:

```
<source>
  @type tail
  path /jboss-log/server.log
  tag wildfly
  <parse>
    @type regexp
    expression /(?<timestamp>(\d{4})-(\d{2})-(\d{2}) (\d{2})\:(\d{2})\:(\d{2})\,(\d{3}))\s+(?<loglevel>\S+)\s+\[(?<logger>[^\]]+)\]\s+\((?<thread>.+?(?=\)))\)\s+(?<message>.*)/
  </parse>
  time_key timestamp
</source>
```
Taking a closer look to some components of this config:

* `@type tail`: one of the most common Fluentd input plug-in and the type of input we want. In this case it is similar to the `tail -f` command.
* `path /jboss-log/server.log`: this means that it will tail the `/jboss-log/server.log` file.
* `tag widlfly`: a tag in order to locate the source within a match section.
* `<parse>`: here we can choose how we want to parse the logs, in this case, we will use a regular expression.


```
<match wildfly>
  @type elasticsearch
  host "elasticsearch-service.monitoring.svc.cluster.local"
  port {{.Values.efk.fluentd.elasticport}}
  logstash_format true
  logstash_prefix wildfly
  reload_connections false
  reconnect_on_error true
  reload_on_failure false
  flatten_hashes true
  flatten_hashes_separator "_"
  suppress_type_name true
  @log_level "debug"
  <buffer>
    @type "file"
    path "/opt/bitnami/fluentd/logs/buffers/fluentd-wildfly.buffer"
    flush_at_shutdown true
    flush_mode interval
    flush_interval 5s
    flush_thread_count 2
    chunk_limit_size 10MB
    chunk_limit_records 10000
  </buffer>
</match>
```
* `<match wildfly>`: the Match section uses a rule. Matches each incoming event to the rule and routes it through an output plug-in. In this case Fluentd will try to match the source logs tagged as `wildfly`.
* `@type elasticsearch`: uses a plugin to send the output to elasticsearch. For more info, check [this](https://docs.fluentd.org/output/elasticsearch). There lots of output plugins, you can check them [here](https://docs.fluentd.org/output).
* `<buffer>`: This section is enabled for those output plugins that support buffered output features. For further information, please check fluentd documentation buffer [section](https://docs.fluentd.org/configuration/buffer-section).

More information about Fluentd's configuration structure can be found [here](https://docs.fluentd.org/configuration/config-file).

