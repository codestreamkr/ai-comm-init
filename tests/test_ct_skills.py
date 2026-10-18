"""임시 저장소와 HTTP 서버에서 CT 스킬의 승인 범위와 토큰 계산을 검증한다."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import time
import unittest
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
                        TEMP=str(self.root))
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


if __name__ == '__main__':
    unittest.main()
