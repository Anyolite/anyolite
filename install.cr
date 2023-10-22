command = {% if flag?(:win32) %}
  # TODO: Is there a better solution?
  "cmd /C rake build_shard"
{% else %}
  "rake build_shard"
{% end %}

# system() inherits the parent process' IO descriptors.
# Failing here will cause the shards process to output this; if we succeed, it is silenced automatically.
raise Exception.new("Failed to install Anyolite") unless system(command)

