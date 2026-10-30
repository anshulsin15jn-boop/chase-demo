"""Authenticated, allowlisted demo-only SMS relay. Never logs message data."""
from __future__ import annotations
import base64
import hashlib
import hmac
import json
import os
import re
import sqlite3
import unicodedata
import urllib.parse
import urllib.request
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from contextlib import closing

HERE = Path(__file__).resolve().parent


def load_env(path):
    if path.is_file():
        for line in path.read_text(encoding='utf-8-sig').splitlines():
            if line.strip() and not line.lstrip().startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ.setdefault(key.strip(), value.strip())


def identity(value):
    if not isinstance(value, str) or not 1 <= len(value) <= 150:
        raise ValueError('Invalid demo identity')
    if not all(unicodedata.category(c)[0] in 'LMN' or c in " '-\u2019()." for c in value):
        raise ValueError('Invalid demo identity')
    if not value.strip() or 'http' in value.lower() or 'www.' in value.lower():
        raise ValueError('Invalid demo identity')
    return value


def canonical(data):
    if not isinstance(data, dict):
        raise ValueError('Expected an object')
    payment_id = str(uuid.UUID(data['paymentID']))
    to = data['to']
    if not isinstance(to, str) or not re.fullmatch(r'\+1[0-9]{10}', to):
        raise ValueError('Expected a ten-digit US test number')
    cents = data['cents']
    if type(cents) is not int or not 1 <= cents <= 1_000_000:
        raise ValueError('Invalid demo amount')
    sender, recipient = identity(data['sender']), identity(data['recipientName'])
    amount = f'${cents // 100:,}.{cents % 100:02}'
    body = (f'CHASE DEMO - LOCAL SIMULATION: {sender} recorded a simulated payment of '
            f'{amount} to {recipient}. No real money was transferred. '
            'Independent demo, not a bank payment alert.')
    if data.get('body', body) != body:
        raise ValueError('Only the approved simulation template is supported')
    return payment_id, to, body


class Relay:
    def __init__(self, token, allowed, database, provider):
        if len(token) < 32 or not token.isascii() or any(ord(c) < 33 or ord(c) > 126 for c in token):
            raise ValueError('Configure a private relay token of at least 32 characters')
        if not allowed or any(not re.fullmatch(r'\+1[0-9]{10}', n) for n in allowed):
            raise ValueError('Configure opted-in test numbers in DEMO_SMS_ALLOWED_TO')
        self.token, self.allowed, self.database, self.provider = token, set(allowed), database, provider
        with closing(sqlite3.connect(database)) as db, db:
            db.execute('CREATE TABLE IF NOT EXISTS requests (id TEXT PRIMARY KEY, digest TEXT, status INTEGER)')

    def submit(self, authorization, data):
        if not hmac.compare_digest(authorization.encode('utf-8'), ('Bearer ' + self.token).encode('utf-8')):
            return 401
        try:
            payment_id, to, body = canonical(data)
        except (ValueError, KeyError, TypeError, AttributeError):
            return 400
        if to not in self.allowed:
            return 403
        digest = hashlib.sha256(json.dumps([to, body], ensure_ascii=False).encode()).hexdigest()
        with closing(sqlite3.connect(self.database, timeout=10)) as db, db:
            db.execute('BEGIN IMMEDIATE')
            prior = db.execute('SELECT digest, status FROM requests WHERE id=?', (payment_id,)).fetchone()
            if prior:
                return prior[1] if prior[0] == digest else 409
            # Commit the claim BEFORE contacting the provider. Uncertain failures never retry.
            db.execute('INSERT INTO requests VALUES (?, ?, ?)', (payment_id, digest, 409))
        try:
            status = 202 if self.provider(to, body) else 502
        except Exception:
            status = 502
        with closing(sqlite3.connect(self.database)) as db, db:
            db.execute('UPDATE requests SET status=? WHERE id=?', (status, payment_id))
        return status


def twilio_provider(sid, token, origin):
    def send(to, body):
        payload = urllib.parse.urlencode({'From': origin, 'To': to, 'Body': body}).encode()
        request = urllib.request.Request(
            f'https://api.twilio.com/2010-04-01/Accounts/{sid}/Messages.json', data=payload,
            headers={'Authorization': 'Basic ' + base64.b64encode(f'{sid}:{token}'.encode()).decode(),
                     'Content-Type': 'application/x-www-form-urlencoded'})
        with urllib.request.urlopen(request, timeout=20) as response:
            return 200 <= response.status < 300
    return send


def handler_for(relay):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def do_POST(self):
            if self.path != '/send':
                return self.reply(404)
            authorization = self.headers.get('Authorization', '')
            if not hmac.compare_digest(authorization.encode('utf-8'), ('Bearer ' + relay.token).encode('utf-8')):
                return self.reply(401)
            try:
                length = int(self.headers.get('Content-Length', '0'))
                if not 0 < length <= 8192 or self.headers.get('Transfer-Encoding'):
                    return self.reply(413)
                self.connection.settimeout(10)
                data = json.loads(self.rfile.read(length))
            except (ValueError, UnicodeDecodeError, TimeoutError):
                return self.reply(400)
            self.reply(relay.submit(authorization, data))

        def reply(self, code):
            raw = json.dumps({'status': 'provider accepted' if code == 202 else 'request not accepted'}).encode()
            self.send_response(code)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Content-Length', str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)
    return Handler


def main():
    load_env(HERE / 'demo_sms.env')
    required = ['TWILIO_ACCOUNT_SID', 'TWILIO_AUTH_TOKEN', 'TWILIO_FROM', 'DEMO_SMS_RELAY_TOKEN', 'DEMO_SMS_ALLOWED_TO']
    if any(not os.environ.get(key, '').strip() for key in required):
        raise SystemExit('Configure required private values in scripts/demo_sms.env; no listener started.')
    sid, token, origin, relay_token, numbers = [os.environ[key].strip() for key in required]
    if not re.fullmatch(r'AC[0-9a-fA-F]{32}', sid) or not re.fullmatch(r'\+[1-9][0-9]{7,14}', origin):
        raise SystemExit('Invalid provider configuration; no listener started.')
    try:
        relay = Relay(relay_token, {n.strip() for n in numbers.split(',')},
                      HERE / 'demo_sms_state.sqlite3', twilio_provider(sid, token, origin))
    except ValueError as error:
        raise SystemExit(str(error)) from None
    server = ThreadingHTTPServer(('127.0.0.1', int(os.environ.get('DEMO_SMS_PORT', '8787'))), handler_for(relay))
    print('Demo relay ready on loopback. Use an HTTPS reverse proxy for iPhone access. No message sent.')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == '__main__':
    main()
