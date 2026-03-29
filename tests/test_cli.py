import os
import sys
from click.testing import CliRunner
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from preproc.cli import cli


def test_cli_fmriprep_dry_run(tmp_path):
    # Create a minimal project structure and a rawdata/.heudiconv directory so the CLI can find one subject
    project = tmp_path / 'proj'
    project.mkdir()
    raw = project / 'rawdata'
    raw.mkdir()
    raw_heudiconv = raw / '.heudiconv'
    raw_heudiconv.mkdir()
    subj = raw_heudiconv / 'TJNU001'
    subj.mkdir()
    (subj / 'ses-1').mkdir()
    os.environ['PROJECT_ROOT'] = str(project)
    runner = CliRunner()
    result = runner.invoke(cli, ['fmriprep', '--dry-run', '--site', 'TJNU', '--sid', '001'])
    assert result.exit_code in (0, 1)
    msg = result.output or str(result.exception)
    assert ('There are' in msg) or ('No suitable data' in msg) or ('All jobs are done' in msg)



def test_cli_batch_invokes_pipeline_plan(tmp_path, monkeypatch):
    config = tmp_path / 'pipeline.yml'
    config.write_text('''pipeline:
  stages: [fmriprep]
''')

    called = {}

    def fake_run_pipeline_plan(config_path, only=None, extra_args=None):
        called['config_path'] = config_path
        called['only'] = only
        called['extra_args'] = extra_args

    monkeypatch.setattr('preproc.cli.run_pipeline_plan', fake_run_pipeline_plan)

    runner = CliRunner()
    result = runner.invoke(cli, ['batch', '--config', str(config), '--only', 'fmriprep', '--extra-args', '--dry-run'])
    assert result.exit_code == 0
    assert called['config_path'] == str(config)
    assert called['only'] == ['fmriprep']
    assert called['extra_args'] == '--dry-run'
