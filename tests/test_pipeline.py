import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from preproc import pipeline


def test_to_cli_args_handles_scalars_lists_and_bool():
    args = pipeline._to_cli_args({
        'site': 'TJNU',
        'sid': ['001', '002'],
        'dry_run': True,
        'none_value': None,
    })
    assert '--site' in args and 'TJNU' in args
    assert '--sid' in args and '001' in args and '002' in args
    assert '--dry-run' in args
    assert '--none-value' not in args


def test_run_pipeline_plan_calls_all_selected_stages(tmp_path, monkeypatch):
    config = tmp_path / 'pipeline.yml'
    config.write_text(
        '''pipeline:
  stages: [heudiconv, fmriprep]
args:
  site: TJNU
  rerun: unprocessed
stage_args:
  heudiconv:
    sid: ["001"]
'''
    )

    calls = []

    def fake_run_context(context, args_list=None):
        calls.append((context, args_list or []))

    monkeypatch.setattr(pipeline, '_run_context', fake_run_context)

    pipeline.run_pipeline_plan(config)

    assert [c[0] for c in calls] == ['heudiconv', 'fmriprep']
    assert any('--site' in c[1] for c in calls)


def test_select_stages_only_filters():
    plan = {'pipeline': {'stages': ['heudiconv', 'mriqc', 'fmriprep']}}
    stages = pipeline._select_stages(plan, only=['mriqc'])
    assert stages == ['mriqc']
