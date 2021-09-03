Fluentd is, like Logstash, a data collector used to process logs and then ship them to Elasticsearch for indexing and storage. Both Fluentd and Logstash are supported in the SD Helm Chart, but Fluentd is the **default** option. Logstash can still be used instead of Fluentd by setting the parameter `elk.fluentd.enabled` to `false`.

## Fluentd Configuration File

Similar to Logstash, Fluentd supports `Event Routing`, this is, capturing logs and sending them to multiple outputs.

Input sources are defined by `<source>` directive and output plugins use `<match>`.

Configuration example:

```
<source>
  @type tail
  path /alarms-log/alarms_active.xml
  pos_file /tmp/alarms_active.xml.pos
  tag alarms_active
  <parse>
  @type regexp
  expression ^Current work list length: (?<thelength>[0-9]+) has exceeded the set threshold :(?<threshold>[0-9]+)$
  types threshold:integer
  types thelength:integer
  </parse>
</source>
```
Taking a closer look to some components of this config:

* `@type tail`: one of the most common Fluentd input plug-in and the type of input we want. In this case it is similar to the `tail -f` command.
* `path /alarms-log/alarms_active.xml`: this means that it will tail the `/alarms-log/alarms_active.xml` file.
* `tag alarms_active`:
* `<parse>`: here we can choose how we want to parse the logs, in this case, we will use a regular expression.


```
<match alarms_active>
  @type copy
  <store>
  @type prometheus
  <metric>
        name workflows_threshold
        type counter
        desc Total length of the current work list.
        <labels>
        data_length thelength
        data_threshold threshold
        </labels>
  </metric>
  </store>
</match>
```
* `<match alarms_active>`: the Match section uses a rule. Matches each incoming event to the rule and routes it through an output plug-in. In this case Fluentd will try to match the source logs tagged as `alarms_active`.
* `@type copy`: uses a plugin to copy events to the output. For more info, check [this](https://docs.fluentd.org/output/copy).
* `<store>` Specifies the storage destination.
* `@type prometheus`. Executes the `prometheus` [plugin](https://docs.fluentd.org/monitoring-fluentd/monitoring-prometheus).

More information about Fluentd's configuration structure can be found [here](https://docs.fluentd.org/configuration/config-file).

