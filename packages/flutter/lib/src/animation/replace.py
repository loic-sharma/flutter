import os
import re

path = "/Users/loicsharma/code/tmp/flutter/dot_shorthands_migration/packages/flutter/lib/src/animation"

types = [
    'AnimationStatus',
    'AnimationBehavior',
    'Axis',
    '_AnimationDirection',
    '_TrainHoppingMode',
]

def replace_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original = content
    for t in types:
        # We want to replace `Type.value` with `.value` when it's obvious, but how do we know it's obvious?
        # Actually, in Dart, you can just use `.value` whenever the context type expects it.
        # But Flutter's style guide says: "Prefer using dot shorthands to omit obvious types for named argument values",
        # "Don't use dot shorthands for positional argument values."
        pass
