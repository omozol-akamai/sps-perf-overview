#
# Copyright (C) 2017 Nominum, Inc.
#
# All rights reserved.
#

from setuptools import setup

setup(
    name = "nomgrafanatools",
    version = file('VERSION').readline().strip(),
    description = "Nominum Grafana Tools",
    packages = [
        'nomgrafanatools',
    ]
)
