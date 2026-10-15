"""Run the installer with isolated homes and mock CLI executables."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(os.environ.get('AI_INIT_SCRIPT', Path(__file__).resolve().parents[1] / 'install.sh'))


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.source = self.root / 'source'
        self.source.mkdir()
        shutil.copy2(SCRIPT, self.source / 'install.sh')
        self.home = self.root / 'home'
        self.home.mkdir()
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        # Exclude real AI CLIs so tests cannot depend on this machine's tools.
        for tool in ('mkdir', 'cp', 'mv', 'ln', 'readlink', 'rm', 'basename', 'dirname', 'date'):
            (self.bin / tool).symlink_to(shutil.which(tool))
        for name in ('ct-alpha', 'ct-beta'):
            folder = self.source / 'skills' / name
            folder.mkdir(parents=True)
            (folder / 'SKILL.md').write_text(name)
        for name, instructions in (('claude', 'CLAUDE.md'), ('codex', 'AGENTS.md'),
                                   ('agy', 'GEMINI.md'), ('grok', 'AGENTS.md'), ('pi', 'AGENTS.md')):
            folder = self.source / name
            folder.mkdir()
            (folder / instructions).write_text(name)
        (self.source / 'grok' / 'statusline.js').write_text('// fixture')
        self.env = dict(os.environ, HOME=str(self.home), PATH=str(self.bin))
        for name in ('AGENTS', 'CLAUDE', 'CODEX', 'GROK', 'GEMINI', 'PI'):
            self.env[name + '_HOME'] = str(self.home / ('.' + name.lower()))

    def cli(self, name, native=False):
        executable = (self.home / '.local/bin' if native else self.bin) / name
        executable.parent.mkdir(parents=True, exist_ok=True)
        executable.write_text('#!/bin/sh\nexit 0\n')
        executable.chmod(0o755)

    def run_install(self, *args):
        result = subprocess.run(['/bin/bash', str(self.source / 'install.sh'), *args],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def test_native_claude_is_detected_without_path_entry(self):
        self.cli('claude', native=True)
        output = self.run_install()
        self.assertIn('완료: Claude Code', output)
        target = self.home / '.claude' / 'CLAUDE.md'
        self.assertTrue(target.is_symlink())
        self.assertEqual(target.resolve(), self.home / '.agents/claude/CLAUDE.md')
        for skill in ('ct-alpha', 'ct-beta'):
            link = self.home / '.claude/skills' / skill
            self.assertEqual(link.resolve(), self.home / '.agents/skills' / skill)

    def test_codex_labels_and_links_remain_stable_on_repeated_runs(self):
        self.cli('codex')
        self.run_install()
        output = self.run_install()
        self.assertEqual(output.count('완료: Codex'), 1)
        self.assertNotIn('linked:', output)
        self.assertNotIn('ct-alpha', output)
        self.assertNotIn('ct-beta', output)
        for skill in ('ct-alpha', 'ct-beta'):
            link = self.home / '.codex/skills' / skill
            self.assertTrue(link.is_symlink())
            self.assertEqual(link.resolve(), self.home / '.agents/skills' / skill)

    def test_missing_clis_are_skipped(self):
        output = self.run_install()
        self.assertIn('skipped: Claude Code (CLI not found in PATH)', output)
        self.assertIn('skipped: Codex (CLI not found in PATH)', output)
        self.assertFalse((self.home / '.claude').exists())
        self.assertFalse((self.home / '.codex').exists())

    def test_all_runtime_labels_and_instruction_targets(self):
        for name in ('claude', 'codex', 'gemini', 'grok', 'pi'):
            self.cli(name)
        output = self.run_install()
        for label, directory, source_name, instructions in (
            ('Claude Code', '.claude', 'claude', 'CLAUDE.md'),
            ('Codex', '.codex', 'codex', 'AGENTS.md'),
            ('Antigravity / Gemini', '.gemini/config', 'agy', 'GEMINI.md'),
            ('Grok', '.grok', 'grok', 'AGENTS.md'),
            ('Pi', '.pi', 'pi', 'AGENTS.md'),
        ):
            self.assertEqual(output.count(f'완료: {label}'), 1)
            self.assertNotIn('linked:', output)
            for skill in ('ct-alpha', 'ct-beta'):
                link = self.home / directory / 'skills' / skill
                self.assertTrue(link.is_symlink())
                self.assertEqual(link.resolve(), self.home / '.agents/skills' / skill)
            target = self.home / directory / instructions
            self.assertEqual(target.resolve(), self.home / '.agents' / source_name / instructions)

    def test_existing_personal_instructions_are_preserved(self):
        self.cli('codex')
        folder = self.home / '.codex'
        folder.mkdir()
        target = folder / 'AGENTS.md'
        target.write_text('personal instructions')
        output = self.run_install()
        self.assertEqual(target.read_text(), 'personal instructions')
        self.assertFalse(target.is_symlink())
        self.assertIn('완료: Codex', output)
        self.assertNotIn('ct-beta', output)


if __name__ == '__main__':
    unittest.main()
