{% if flag?(:win32) %}
  system("cmd /k rake build_shard && exit")
{% else %}
  system("rake build_shard")
{% end %}
