"""임시 저장소와 HTTP 서버에서 CT 스킬의 승인 범위와 토큰 계산을 검증한다."""
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import threading
import time
import unittest
from urllib.error import HTTPError
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parents[1]
GATE = ROOT / 'skills/ct-debrief/scripts/gate.js'
MAP = ROOT / 'skills/ct-progress/scripts/map.js'
NODE = shutil.which('node')


@unittest.skipUnless(NODE and shutil.which('git'), 'Node.js와 Git이 필요하다.')
class GateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ct-gate-test-')
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name).resolve()
        self.env = {key: value for key, value in os.environ.items()
                    if not key.startswith('GIT_')}
        self.git('init', '-q')
        self.git('config', 'user.email', 'ct-test@example.invalid')
        self.git('config', 'user.name', 'CT Test')
        self.write('A.txt', 'one\ntwo\n')
        self.write('B.txt', 'original\n')
        self.git('add', '.')
        self.git('commit', '-qm', 'initial')

    def write(self, name, content):
        (self.repo / name).write_text(content, encoding='utf-8')

    def git(self, *args, input=None):
        result = subprocess.run(['git', *args], cwd=self.repo, env=self.env,
                                input=input, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def gate(self, command, *args, succeeds=True):
        result = subprocess.run([NODE, str(GATE), command, str(self.repo), *args],
                                env=self.env, text=True, capture_output=True)
        if succeeds:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def test_only_reviewed_file_is_approved(self):
        self.write('A.txt', 'reviewed\n')
        self.write('B.txt', 'unreviewed\n')
        self.gate('mark', 'A 확인', '--', 'A.txt')
        self.git('add', 'A.txt')
        self.gate('check')
        self.git('add', 'B.txt')
        self.gate('check', succeeds=False)

    def test_already_staged_unreviewed_file_is_not_approved(self):
        self.write('A.txt', 'reviewed\n')
        self.write('B.txt', 'unreviewed\n')
        self.git('add', 'B.txt')
        before = self.git('write-tree')
        self.gate('mark', '--', 'A.txt')
        self.assertEqual(self.git('write-tree'), before)
        self.git('add', 'A.txt')
        self.gate('check', succeeds=False)

    def test_mark_requires_explicit_paths(self):
        self.write('A.txt', 'changed\n')
        self.gate('mark', '메모만 지정', succeeds=False)
        self.gate('mark', '--', succeeds=False)

    def test_legacy_whole_tree_marker_is_ignored(self):
        self.write('A.txt', 'changed\n')
        self.git('add', 'A.txt')
        tree = self.git('write-tree')
        legacy = self.repo / '.git/understand-gate' / tree
        legacy.parent.mkdir(parents=True)
        legacy.write_text('{"note":"legacy"}\n', encoding='utf-8')
        self.gate('check', succeeds=False)
        self.gate('mark', '--', 'A.txt')
        self.gate('check')

    def test_new_file_is_approved_after_staging(self):
        self.write('new.txt', 'new\n')
        self.gate('mark', '--', 'new.txt')
        self.gate('check', succeeds=False)
        self.git('add', 'new.txt')
        self.gate('check')

    def test_deleted_file_is_approved(self):
        (self.repo / 'A.txt').unlink()
        self.gate('mark', '--', 'A.txt')
        self.git('add', '-u', '--', 'A.txt')
        self.gate('check')

    def test_staged_deleted_file_is_approved(self):
        self.git('rm', 'A.txt')
        self.gate('mark', '--', 'A.txt')
        self.gate('check')

    def test_partial_stage_does_not_match_reviewed_content(self):
        self.write('A.txt', 'ONE\nTWO\n')
        self.gate('mark', '--', 'A.txt')
        blob = self.git('hash-object', '-w', '--stdin', input='ONE\ntwo\n')
        self.git('update-index', '--cacheinfo', '100644', blob, 'A.txt')
        self.gate('check', succeeds=False)
        self.git('add', 'A.txt')
        self.gate('check')

    def test_restaged_edit_requires_another_review(self):
        self.write('A.txt', 'reviewed\n')
        self.gate('mark', '--', 'A.txt')
        self.git('add', 'A.txt')
        self.gate('check')
        self.write('A.txt', 'later edit\n')
        self.git('add', 'A.txt')
        self.gate('check', succeeds=False)

    def test_filename_with_spaces_is_literal(self):
        self.write('file with spaces.txt', 'new\n')
        self.gate('mark', '--', 'file with spaces.txt')
        self.git('add', '--', 'file with spaces.txt')
        self.gate('check')

    def test_pathspec_characters_are_literal(self):
        self.write('[draft].txt', 'reviewed\n')
        self.write('d.txt', 'unreviewed\n')
        self.gate('mark', '--', '[draft].txt')
        self.git('add', '--', ':(literal)[draft].txt')
        self.gate('check')
        self.git('add', '--', 'd.txt')
        self.gate('check', succeeds=False)

    def test_directory_and_external_paths_are_rejected(self):
        (self.repo / 'folder').mkdir()
        self.write('folder/file.txt', 'new\n')
        with tempfile.TemporaryDirectory(prefix='ct-gate-outside-') as outside:
            external = Path(outside) / 'outside.txt'
            external.write_text('outside\n', encoding='utf-8')
            for candidate in ('folder', '.', '..', str(external)):
                with self.subTest(path=candidate):
                    self.gate('mark', '--', candidate, succeeds=False)

    def test_deleted_directory_cannot_approve_multiple_files(self):
        (self.repo / 'folder').mkdir()
        self.write('folder/first.txt', 'first\n')
        self.write('folder/second.txt', 'second\n')
        self.git('add', 'folder')
        self.git('commit', '-qm', 'add folder')
        shutil.rmtree(self.repo / 'folder')
        self.gate('mark', '--', 'folder', succeeds=False)
        self.gate('mark', '--', 'folder/first.txt')
        self.git('add', '-u', '--', 'folder/first.txt')
        self.gate('check')
        self.git('add', '-u', '--', 'folder/second.txt')
        self.gate('check', succeeds=False)


@unittest.skipUnless(NODE, 'Node.js가 필요하다.')
class MapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ct-map-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.env = dict(os.environ, TMPDIR=str(self.root), TMP=str(self.root),
                        TEMP=str(self.root), CT_MAP_SESSION='test:tokens')
        self.usage = self.root / 'usage.jsonl'
        self.usage.touch()
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            self.port = listener.getsockname()[1]
        self.url = f'http://127.0.0.1:{self.port}'
        self.server = subprocess.Popen(
            [NODE, str(MAP), 'serve', '--port', str(self.port)], env=self.env,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.addCleanup(self.stop_server)
        deadline = time.monotonic() + 5
        while True:
            try:
                self.get('/version')
                break
            except OSError:
                if self.server.poll() is not None or time.monotonic() >= deadline:
                    self.fail('맵 서버가 시작되지 않았다.')
                time.sleep(0.02)

    def stop_server(self):
        try:
            if self.server.poll() is None:
                self.get('/stop')
                self.server.wait(timeout=3)
        finally:
            if self.server.poll() is None:
                self.server.kill()
                self.server.wait(timeout=3)

    def get(self, endpoint):
        with urlopen(self.url + endpoint, timeout=2) as response:
            return response.read().decode('utf-8')

    def append(self, event):
        with self.usage.open('a', encoding='utf-8') as stream:
            stream.write(json.dumps(event) + '\n')

    def response(self, second, kind='custom_tool_call'):
        payload = {'type': kind}
        if kind == 'message':
            payload['role'] = 'assistant'
        self.append({'timestamp': self.timestamp(second), 'type': 'response_item',
                     'payload': payload})

    def count(self, second, input_tokens, cached_input_tokens, output_tokens):
        self.append({'timestamp': self.timestamp(second), 'type': 'event_msg',
                     'payload': {'type': 'token_count', 'info': {
                         'total_token_usage': {'input_tokens': input_tokens,
                                               'cached_input_tokens': cached_input_tokens,
                                               'output_tokens': output_tokens}}}})

    @staticmethod
    def timestamp(second):
        return f'2026-01-01T00:00:{second:06.3f}Z'

    def emit(self, event):
        result = subprocess.run([NODE, str(MAP), 'emit', str(self.repo),
                                 json.dumps(event)], env=self.env,
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def start_run(self):
        self.emit({'run': 'r', 'steps': [{'id': 's'}],
                   'usage': {'file': str(self.usage), 'kind': 'total'}})
        self.emit({'run': 'r', 'step': 's', 's': 'start',
                   't': self.timestamp(1)})
        self.emit({'run': 'r', 'step': 's', 's': 'done',
                   't': self.timestamp(4)})

    def completed_step(self):
        events = [json.loads(line) for line in self.get('/live.jsonl').splitlines()]
        return next(event for event in events if event.get('s') == 'done')

    def test_delayed_count_uses_response_time_and_excludes_next_response(self):
        self.response(0.5)
        self.count(2, 250, 40, 30)
        self.start_run()
        self.assertNotIn('tok', self.completed_step())
        self.response(3.5)
        self.count(5, 450, 40, 30)
        self.assertEqual(self.completed_step()['tok'], 200)
        self.response(6, 'message')
        self.count(7, 950, 40, 30)
        self.assertEqual(self.completed_step()['tok'], 200)

    def test_function_call_and_assistant_message_are_usage_anchors(self):
        self.response(0.5, 'function_call')
        self.count(2, 100, 20, 10)
        self.response(3.5, 'message')
        self.count(5, 250, 40, 30)
        self.start_run()
        self.assertEqual(self.completed_step()['tok'], 150)

    def test_plain_total_fixture_without_response_items_still_works(self):
        self.count(0.5, 100, 20, 10)
        self.count(3, 250, 40, 30)
        self.start_run()
        self.assertEqual(self.completed_step()['tok'], 150)


@unittest.skipUnless(NODE, 'Node.js가 필요하다.')
class MapSessionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ct-session-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.env = {key: value for key, value in os.environ.items()
                    if key not in ('CT_MAP_SESSION', 'CODEX_THREAD_ID',
                                   'CLAUDE_CODE_SESSION_ID')}
        self.env.update(TMPDIR=str(self.root), TMP=str(self.root), TEMP=str(self.root))
        self.codex = dict(self.env, CODEX_THREAD_ID='thread-one')
        self.claude = dict(self.env, CLAUDE_CODE_SESSION_ID='thread-one')

    def cli(self, command, *args, env=None, code=0):
        result = subprocess.run([NODE, str(MAP), command, *map(str, args)],
                                env=self.env if env is None else env,
                                text=True, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, code, result.stderr or result.stdout)
        return result.stdout.strip()

    def emit(self, env, event, repo=None):
        self.cli('emit', repo or self.repo, json.dumps(event), env=env)

    def run_event(self, title, model):
        return {'run': 'same-run', 'title': title, 'model': model,
                'steps': [{'id': 'same-step', 'name': title}]}

    def seed(self, env, title, model):
        self.emit(env, self.run_event(title, model))
        self.emit(env, {'run': 'same-run', 'step': 'same-step', 's': 'done'})
        self.emit(env, {'run': 'same-run', 'adr': {
            'id': 'same-adr', 'title': title + ' ADR', 's': 'cand'}})

    @staticmethod
    def get(url, endpoint):
        with urlopen(url + endpoint, timeout=2) as response:
            return response.read().decode('utf-8')

    def start_server(self, env):
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            port = listener.getsockname()[1]
        url = f'http://127.0.0.1:{port}'
        server = subprocess.Popen([NODE, str(MAP), 'serve', '--port', str(port)],
                                  env=env, stdout=subprocess.DEVNULL,
                                  stderr=subprocess.DEVNULL)

        def cleanup():
            if server.poll() is None:
                server.terminate()
                try:
                    server.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait(timeout=3)
        self.addCleanup(cleanup)
        deadline = time.monotonic() + 5
        while True:
            try:
                self.get(url, '/session')
                return port, url, server
            except OSError:
                if server.poll() is not None or time.monotonic() >= deadline:
                    self.fail('세션 맵 서버가 시작되지 않았다.')
                time.sleep(0.02)

    def test_same_repo_run_step_and_adr_are_isolated_and_clear_is_local(self):
        self.seed(self.codex, 'Codex 작업', 'gpt-model')
        self.seed(self.claude, 'Claude 작업', 'claude-model')
        codex_file = Path(self.cli('path', self.repo, env=self.codex))
        claude_file = Path(self.cli('path', self.repo, env=self.claude))
        self.assertNotEqual(codex_file, claude_file)
        self.assertEqual(len(codex_file.read_text().splitlines()), 3)
        self.assertEqual(len(claude_file.read_text().splitlines()), 3)
        self.assertIn('Codex', codex_file.read_text())
        self.assertNotIn('Claude', codex_file.read_text())
        self.assertIn('Claude', claude_file.read_text())
        self.assertNotIn('Codex', claude_file.read_text())
        self.cli('clear', self.repo, env=self.codex)
        self.assertFalse(codex_file.exists())
        self.assertTrue(claude_file.exists())

    def test_threads_in_same_app_have_distinct_paths(self):
        second = dict(self.codex, CODEX_THREAD_ID='thread-two')
        self.assertNotEqual(self.cli('path', self.repo, env=self.codex),
                            self.cli('path', self.repo, env=second))
        claude_second = dict(self.claude, CLAUDE_CODE_SESSION_ID='thread-two')
        self.assertNotEqual(self.cli('path', self.repo, env=self.claude),
                            self.cli('path', self.repo, env=claude_second))

    def test_missing_and_ambiguous_session_fail_for_every_command(self):
        ambiguous = dict(self.codex, CLAUDE_CODE_SESSION_ID='thread-one')
        for env in (self.env, ambiguous):
            for command, args in (
                    ('path', (self.repo,)), ('clear', (self.repo,)),
                    ('emit', (self.repo, json.dumps(self.run_event('x', 'm')))),
                    ('serve', ('--port', '0')), ('status', ()), ('stop', ())):
                with self.subTest(command=command, ambiguous=env is ambiguous):
                    self.cli(command, *args, env=env, code=1)

    def test_explicit_session_and_environment_override_ambient_ids(self):
        ambiguous = dict(self.codex, CLAUDE_CODE_SESSION_ID='thread-one',
                         CT_MAP_SESSION='chosen-env')
        expected_env = dict(self.env, CT_MAP_SESSION='chosen-env')
        self.assertEqual(self.cli('path', self.repo, env=ambiguous),
                         self.cli('path', self.repo, env=expected_env))
        explicit = self.cli('path', self.repo, '--session', 'chosen-flag', env=ambiguous)
        self.assertEqual(explicit, self.cli('path', self.repo, env=dict(
            self.env, CT_MAP_SESSION='chosen-flag')))
        self.assertNotEqual(explicit, self.cli('path', self.repo, env=ambiguous))

    def test_session_id_uses_hash_and_cannot_escape_data_root(self):
        session = '../../outside/한글/..'
        env = dict(self.env, CT_MAP_SESSION=session)
        self.seed(env, '격리 작업', 'model')
        file = Path(self.cli('path', self.repo, env=env))
        expected = self.root / 'ct-progress' / 'sessions' / hashlib.sha256(
            session.encode()).hexdigest()
        self.assertEqual(file.parent.parent, expected)
        self.assertEqual(file.name, 'live.jsonl')
        self.assertTrue(file.is_file())
        self.assertFalse((self.root / 'outside').exists())

    def test_two_servers_expose_only_their_session_and_recent_repo(self):
        self.seed(self.codex, 'Codex 작업', 'gpt-model')
        self.seed(self.claude, 'Claude 작업', 'claude-model')
        _, codex_url, _ = self.start_server(self.codex)
        _, claude_url, _ = self.start_server(self.claude)
        for url, session, own_title, other_title, model in (
                (codex_url, 'codex:thread-one', 'Codex', 'Claude', 'gpt-model'),
                (claude_url, 'claude:thread-one', 'Claude', 'Codex', 'claude-model')):
            with self.subTest(session=session):
                self.assertEqual(json.loads(self.get(url, '/session')), {'id': session})
                live = self.get(url, '/live.jsonl')
                events = [json.loads(line) for line in live.splitlines()]
                self.assertEqual(events[0]['model'], model)
                self.assertEqual(events[2]['adr']['title'], own_title + ' 작업 ADR')
                self.assertNotIn(other_title, live)
                for endpoint in ('/repos', '/live.jsonl'):
                    self.assertEqual(self.get(url, endpoint + '?session=' + session),
                                     self.get(url, endpoint))
                    with self.assertRaises(HTTPError) as error:
                        self.get(url, endpoint + '?session=another-session')
                    self.assertEqual(error.exception.code, 409)
        before = json.loads(self.get(codex_url, '/repos'))
        other_repo = self.root / 'other-repo'
        other_repo.mkdir()
        self.emit(self.claude, self.run_event('다른 저장소', 'claude-model'), other_repo)
        self.assertEqual(json.loads(self.get(codex_url, '/repos')), before)
        self.assertIn('Codex', self.get(codex_url, '/live.jsonl'))
        self.assertEqual(len(json.loads(self.get(claude_url, '/repos'))), 2)
        self.assertIn('다른 저장소', self.get(claude_url, '/live.jsonl'))

    def test_status_and_stop_reject_another_session_and_preserve_server(self):
        port, url, server = self.start_server(self.codex)
        self.cli('status', '--port', port, env=self.codex)
        self.cli('status', '--port', port, env=self.claude, code=2)
        self.cli('stop', '--port', port, env=self.claude, code=1)
        self.assertIsNone(server.poll())
        self.assertEqual(json.loads(self.get(url, '/session')), {'id': 'codex:thread-one'})
        self.cli('stop', '--port', port, env=self.codex)
        server.wait(timeout=3)
        self.assertEqual(server.returncode, 0)


    def test_status_distinguishes_old_version_with_same_session(self):
        class OldMapHandler(BaseHTTPRequestHandler):
            def do_GET(self):
                body = {'/repos': '[]', '/version': 'old-version',
                        '/session': '{"id":"codex:thread-one"}'}.get(self.path)
                self.send_response(200 if body is not None else 404)
                self.end_headers()
                self.wfile.write((body or '').encode())

            def log_message(self, *args):
                pass

        server = ThreadingHTTPServer(('127.0.0.1', 0), OldMapHandler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()

        def cleanup():
            server.shutdown()
            server.server_close()
            thread.join(timeout=3)
        self.addCleanup(cleanup)
        port = server.server_address[1]
        self.cli('status', '--port', port, env=self.codex, code=3)
        self.cli('status', '--port', port, env=self.claude, code=2)


if __name__ == '__main__':
    unittest.main()
