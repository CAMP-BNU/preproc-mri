import click
from . import utils, workflows
from .pipeline import run_pipeline_plan


@click.group()
def cli():
    """preproc command-line toolkit"""
    pass


def run_context(context, args_list=None):
    argv = utils.parse_arguments(context, args_list)
    utils.validate_argv(context, argv)
    jobs = workflows.prepare_jobs(context, argv)
    todo = workflows.extract_todo(context, jobs, argv)
    workflows.execute_jobs(context, todo, argv)


@cli.command(name='fmriprep', context_settings={"ignore_unknown_options": True, "allow_extra_args": True})
@click.pass_context
def fmriprep_cmd(ctx):
    """Run fmriprep job preparation and submission"""
    # pass through remaining args to argparse
    run_context('fmriprep', ctx.args)


@cli.command(name='mriqc', context_settings={"ignore_unknown_options": True, "allow_extra_args": True})
@click.pass_context
def mriqc_cmd(ctx):
    """Run mriqc job preparation and submission"""
    run_context('mriqc', ctx.args)


@cli.command(name='heudiconv', context_settings={"ignore_unknown_options": True, "allow_extra_args": True})
@click.pass_context
def heudiconv_cmd(ctx):
    """Run heudiconv job preparation and submission"""
    run_context('heudiconv', ctx.args)


@cli.command(name='xcpd', context_settings={"ignore_unknown_options": True, "allow_extra_args": True})
@click.pass_context
def xcpd_cmd(ctx):
    """Run xcp_d job preparation and submission"""
    run_context('xcpd', ctx.args)




@cli.command(name='batch')
@click.option('--config', 'config_path', required=True, type=click.Path(exists=True, dir_okay=False), help='Path to pipeline YAML config.')
@click.option('--only', multiple=True, help='Only run specific stages (can repeat).')
@click.option('--extra-args', default='', help='Extra args forwarded to every stage, e.g. "--dry-run".')
def batch_cmd(config_path, only, extra_args):
    """Run a multi-stage preprocessing pipeline from a YAML plan."""
    run_pipeline_plan(config_path=config_path, only=list(only) or None, extra_args=extra_args)


if __name__ == '__main__':
    cli()
