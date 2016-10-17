#!/bin/bash

if [[ $DISABLE_DATADOG_AGENT ]]; then
  echo "DISABLE_DATADOG_AGENT environment variable is set, not starting the agent."
  exit 0
fi

if [[ $DATADOG_API_KEY ]]; then
  sed -i -e "s/^.*api_key:.*$/api_key: ${DATADOG_API_KEY}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
else
  echo "DATADOG_API_KEY environment variable not set. Run: heroku config:add DATADOG_API_KEY=<your API key>"
  exit 1
fi

if [[ $HOST_NAME ]]; then
  sed -i -e "s/^.*hostname:.*$/hostname: ${HOST_NAME}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
fi

mkdir -p /app/.apt/opt/datadog-agent/agent/conf.d

cat <<VAR > /app/.apt/opt/datadog-agent/agent/conf.d/mcache.yaml
init_config:

instances:
  - url: production-cv.mgrhj0.cfg.usw2.cache.amazonaws.com
  - url: production-rails.mgrhj0.cfg.usw2.cache.amazonaws.com
    port: 11212
VAR

cat <<VAR > /app/.apt/opt/datadog-agent/agent/conf.d/redisdb.yaml
init_config:

instances:
  - host: production-push-001.mgrhj0.0001.usw2.cache.amazonaws.com
    port: 6379
VAR

cat <<VAR > /app/.apt/opt/datadog-agent/agent/conf.d/system_core.yaml
init_config:

instances:
  # No configuration is needed for this check.
  # A single instance needs to be defined with any value.
  - foo: bar
VAR

(
  # Unset other PYTHONPATH/PYTHONHOME variables before we start
  unset PYTHONHOME PYTHONPATH
  # Load our library path first when starting up
  export LD_LIBRARY_PATH=/app/.apt/opt/datadog-agent/embedded/lib:$LD_LIBRARY_PATH
  mkdir -p /tmp/logs/datadog
  /app/.apt/opt/datadog-agent/embedded/bin/python /app/.apt/opt/datadog-agent/agent/agent.py start &
  /app/.apt/opt/datadog-agent/embedded/bin/python /app/.apt/opt/datadog-agent/agent/ddagent.py &
  exec /app/.apt/opt/datadog-agent/embedded/bin/python /app/.apt/opt/datadog-agent/agent/dogstatsd.py start
)
