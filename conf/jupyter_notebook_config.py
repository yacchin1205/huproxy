# huproxy
import os

def _run_huproxy(port):
    service_prefix = os.environ.get('JUPYTERHUB_SERVICE_PREFIX', '/')
    return [
        '/opt/huproxy/bin/huproxy', '-listen', f'127.0.0.1:{port}',
        '-url', f'{service_prefix}huproxy'.strip('/')
    ]

c.ServerProxy.servers = {
  'huproxy': {
    'command': _run_huproxy,
    'absolute_url': True,
    'timeout': 30,
  }
}
