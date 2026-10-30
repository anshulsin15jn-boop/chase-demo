"""Offline relay tests: fake provider only, no SMS/network calls."""
import concurrent.futures
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from demo_sms_server import Relay, canonical

TOKEN = 'test-only-placeholder-not-a-secret-123456'


def payload():
    data = dict(paymentID='12345678-1234-4234-8234-123456789012', to='+12025550146',
                sender="ÉLODIE ANNE O'NEIL", recipientName='JORDAN ELLIS', cents=12345)
    data['body'] = canonical(data)[2]
    return data


class RelayTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.calls = []
        self.db = Path(self.tmp.name) / 'state.sqlite3'
        self.relay = Relay(TOKEN, {'+12025550146'}, self.db, self.provider)
        guard = patch('urllib.request.urlopen', side_effect=AssertionError('Network forbidden in tests'))
        guard.start()
        self.addCleanup(guard.stop)

    def provider(self, to, body):
        self.calls.append((to, body))
        return True

    def submit(self, data=None):
        return self.relay.submit('Bearer ' + TOKEN, payload() if data is None else data)

    def test_template(self):
        self.assertEqual(self.submit(), 202)
        body = self.calls[0][1]
        self.assertIn("ÉLODIE ANNE O'NEIL", body)
        self.assertIn('$123.45', body)
        self.assertIn('No real money was transferred.', body)
        self.assertNotIn('http', body)

    def test_auth_required(self):
        self.assertEqual(self.relay.submit('', payload()), 401)
        self.assertEqual(self.relay.submit('Bearer wrong', payload()), 401)
        self.assertFalse(self.calls)

    def test_allowlist(self):
        data = payload(); data['to'] = '+12025550147'
        self.assertEqual(self.submit(data), 403)
        self.assertFalse(self.calls)

    def test_arbitrary_message_rejected(self):
        data = payload(); data['body'] = 'LOCAL SIMULATION: You received a real payment.'
        self.assertEqual(self.submit(data), 400)
        self.assertFalse(self.calls)

    def test_invalid_amounts(self):
        for amount in [0, -1, True, 1.5, '100', 1000001]:
            data = payload(); data['cents'] = amount
            self.assertEqual(self.submit(data), 400)
        self.assertFalse(self.calls)

    def test_invalid_identity_and_number(self):
        for key, value in [('sender', 'A\nB'), ('recipientName', 'https://example.com'), ('to', '+1202555014'), ('to', '+1１２３４５６７８９０')]:
            data = payload(); data[key] = value
            self.assertEqual(self.submit(data), 400)
        self.assertFalse(self.calls)

    def test_number_only_and_name_only(self):
        data = payload(); data['recipientName'] = '(202) 555-0146'; data.pop('body')
        self.assertEqual(self.submit(data), 202)
        data = payload(); data['to'] = None
        self.assertEqual(self.submit(data), 400)

    def test_duplicate_across_restart(self):
        self.assertEqual(self.submit(), 202)
        self.relay = Relay(TOKEN, {'+12025550146'}, self.db, self.provider)
        self.assertEqual(self.submit(), 202)
        self.assertEqual(len(self.calls), 1)
        contents = self.db.read_bytes()
        self.assertNotIn(b'JORDAN', contents)
        self.assertNotIn(b'2025550146', contents)

    def test_concurrent_duplicate(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            statuses = list(pool.map(lambda _: self.submit(), range(8)))
        self.assertTrue(all(status in (202, 409) for status in statuses))
        self.assertEqual(len(self.calls), 1)

    def test_mutated_snapshot_rejected(self):
        self.assertEqual(self.submit(), 202)
        data = payload(); data['cents'] = 999; data.pop('body')
        self.assertEqual(self.submit(data), 409)
        self.assertEqual(len(self.calls), 1)

    def test_uncertain_failure_never_retried(self):
        def fail(to, body):
            self.calls.append((to, body)); raise TimeoutError()
        self.relay.provider = fail
        self.assertEqual(self.submit(), 502)
        self.relay = Relay(TOKEN, {'+12025550146'}, self.db, self.provider)
        self.assertEqual(self.submit(), 502)
        self.assertEqual(len(self.calls), 1)

    def test_unconfigured_relay_rejected(self):
        for token, allowed in [('', {'+12025550146'}), (TOKEN, set()), (TOKEN, {'123'})]:
            with self.assertRaises(ValueError):
                Relay(token, allowed, self.db, self.provider)

    def test_zero_padding_and_thousands(self):
        data = payload(); data.pop('body'); data['cents'] = 100005
        self.assertIn('$1,000.05', canonical(data)[2])


if __name__ == '__main__':
    unittest.main()
