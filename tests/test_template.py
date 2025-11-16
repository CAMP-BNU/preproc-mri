import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from preproc.utils import render_template
import os


def test_render_simple():
    t = 'echo ${PROJECT_ROOT} ${INPUT_DIR}'
    mapping = {'PROJECT_ROOT': '/tmp/prj', 'INPUT_DIR': '/tmp/input'}
    assert render_template(t, mapping) == 'echo /tmp/prj /tmp/input'


def test_render_with_default():
    t = 'echo ${PROJECT_ROOT:-/tmp/fallback} ${SOMETHING:-abc}'
    mapping = {'PROJECT_ROOT': '/tmp/prj'}
    assert render_template(t, mapping) == 'echo /tmp/prj abc'


def test_render_missing_required_raises():
    t = 'echo ${MISSING}'
    try:
        render_template(t, {}, required=True)
        assert False, 'should have raised'
    except KeyError:
        pass


def test_render_missing_not_required_returns_blank():
    t = 'echo ${MISSING}'
    assert render_template(t, {}, required=False) == 'echo '
