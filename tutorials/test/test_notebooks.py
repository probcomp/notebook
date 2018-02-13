import glob
import os
import subprocess

from contextlib import contextmanager

import pytest

NOTEBOOKS_DIRECTORY = '.'

IGNORED_NOTEBOOKS = [
    'goal-inference-part1.ipynb',
    'goal-inference-part2.ipynb',
    'goal-inference-part3.ipynb',
]

@contextmanager
def working_directory(path):
    old_path = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(old_path)

def find_notebooks(directory, ignore=None):
    ignored_notebooks = [] if ignore is None else ignore
    with working_directory(directory):
        top = glob.glob('*.ipynb')
        internal = glob.glob('resources/*.ipynb')
        return [
            notebook
            for notebook in top + internal
            if not notebook.endswith('.nbconvert.ipynb')
                and notebook not in ignored_notebooks
        ]

notebooks = find_notebooks(NOTEBOOKS_DIRECTORY, IGNORED_NOTEBOOKS)

@pytest.mark.parametrize('notebook', notebooks)
def test_population_assembly(notebook):
    with working_directory('.'):
        subprocess.check_call([
            'jupyter',
            'nbconvert',
            '--to', 'notebook',
            '--execute',
            '--ExecutePreprocessor.timeout=600',
            notebook
        ])
