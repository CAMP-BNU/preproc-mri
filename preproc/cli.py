import click
from . import utils, workflows


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


if __name__ == '__main__':
    cli()
