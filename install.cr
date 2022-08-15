{% if flag?(:win32) %}
  system("cmd /k rake build_shard")
{% else %}
  system("rake build_shard")
{% end %}
