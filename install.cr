{% if flag?(:win32) %}
  # TODO: Is there a better solution?
  system("start /B rake build_shard && exit")
{% else %}
  system("rake build_shard")
{% end %}
