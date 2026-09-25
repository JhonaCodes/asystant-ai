"""Opt-in paid smoke test using an existing OPENROUTER_API_KEY.
Requires a dedicated ASYSTANT_TEST_DATABASE_URL. Never prints secret values.
"""
import base64
import hashlib
import hmac
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import time
import uuid

root = Path(__file__).resolve().parents[1]
if not os.environ.get('OPENROUTER_API_KEY') or not os.environ.get('ASYSTANT_TEST_DATABASE_URL'):
    raise SystemExit('Requires OPENROUTER_API_KEY and dedicated ASYSTANT_TEST_DATABASE_URL')
secret = secrets.token_urlsafe(48)
issuer = 'smoke-' + str(uuid.uuid4())
with socket.socket() as listener:
    listener.bind(('127.0.0.1', 0))
    port = listener.getsockname()[1]
environment = os.environ.copy()
environment.update({
    'DATABASE_URL': environment['ASYSTANT_TEST_DATABASE_URL'],
    'ASYSTANT_BIND': f'127.0.0.1:{port}',
    'ASYSTANT_PRODUCTS': json.dumps([{'issuer':issuer,'secret':secret,'daily_tenant_micros':100000,'daily_user_micros':100000,'models':['openai/gpt-oss-20b']}]),
    'ASYSTANT_MODELS': json.dumps([{'id':'openai/gpt-oss-20b','provider':'openrouter','model':'openai/gpt-oss-20b','key_env':'OPENROUTER_API_KEY','input_micros_per_million':1000000,'output_micros_per_million':1000000,'max_input_tokens':32768,'max_output_tokens':2048}]),
})
subprocess.run(['cargo','build','--manifest-path','services/asystant_gateway/Cargo.toml','--bin','asystant_gateway'],cwd=root,check=True)
server = subprocess.Popen([str(root/'services/asystant_gateway/target/debug/asystant_gateway')],cwd=root,env=environment,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
try:
    for attempt in range(60):
        if server.poll() is not None: raise RuntimeError('Gateway startup failed')
        try:
            with socket.create_connection(('127.0.0.1',port),timeout=.2): break
        except OSError: time.sleep(.2)
    else: raise RuntimeError('Gateway startup timeout')
    now=int(time.time())
    claims={'iss':issuer,'aud':'asystant-gateway','sub':'smoke-user','tenant':'smoke-tenant','sid':'smoke-session','jti':str(uuid.uuid4()),'iat':now,'exp':now+120,'session_exp':now+600}
    def b64(data): return base64.urlsafe_b64encode(data).rstrip(b'=')
    payload=b64(json.dumps({'alg':'HS256','typ':'JWT'}).encode())+b'.'+b64(json.dumps(claims).encode())
    token=(payload+b'.'+b64(hmac.new(secret.encode(),payload,hashlib.sha256).digest())).decode()
    client_env=os.environ.copy()
    client_env.update({'ASYSTANT_LIVE_GATEWAY':f'http://127.0.0.1:{port}','ASYSTANT_LIVE_TICKET':token})
    result=subprocess.run(['flutter','test','packages/asystant_ai/test/live_gateway_test.dart'],cwd=root,env=client_env)
    raise SystemExit(result.returncode)
finally:
    server.terminate()
    try: server.wait(timeout=10)
    except subprocess.TimeoutExpired: server.kill(); server.wait()
