KEES - The Coloclue Network Automation Toolchain
================================================

This code in this repository is used for the following tasks:

- use the database at https://github.com/coloclue/peering to generate all IXP
  peering (but in this demo it comes from `vars/peers.yaml`)
- generate IRR filters for each peer
- generate static routes for BIRD configuration
- generate 'confed' BGP config for BIRD
- generate remaining BIRD configuration
- push the BIRD configs to all boxes

KEES IS AUTHORITIVE:
--------------------

The 'kees' repository is the authoritve source for BIRD configurations in the
coloclue network. Any changes to the BIRD configuration on the routers will be
overwritten by the scripts in this repository.

Part of the BIRD configurations are generated by python scripts, other parts of
the BIRD configuration are manually composed and stored in the 'blobs'
directory.  The 'blobs' directory contains a directory for reach BIRD router,
later on the peering & rpki files are copied over the a copy of the 'blobs' to
augment it with the 'dynamic' (read IRR or RPKI) portions of the configuration.

The concept:
------------

The YAML data in the `vars/` directory is transposed by the `gentool` script
through Jinja2 templates, to generate the final configuration.  The YAML data
could of course also come from a real SQL database. The final `/etc/bird`
directory for each router ends up in in `staged-configs/$router_name`, which
can easily be rsynced.

Repository layout:
------------------

	Vurt:coloclue-kees job$ tree
	.
	├── LICENSE
	├── README
	├── blobs
	│   ├── dcg-1.router.nl.coloclue.net
	│   │   ├── bird.conf
	│   │   ├── bird6.conf
	│   │   ├── peerings
	│   │   └── rpki
	│   ├── dcg-2.router.nl.coloclue.net
	│   │   ├── bird.conf
	│   │   ├── bird6.conf
	│   │   └── rpki
	│   └── eunetworks-2.router.nl.coloclue.net
	│       ├── bird.conf
	│       ├── bird6.conf
	│       ├── blackholes
	│       ├── level3.ipv4.conf
	│       ├── level3.ipv6.conf
	│       ├── peerings
	│       └── rpki
	├── filter-cache
	├── gen_peering_filters
	├── gentool
	├── staged-configs
	├── templates
	│   ├── afi_specific_filters.j2
	│   ├── bird-rpki.j2
	│   ├── envvars.j2
	│   ├── filter.j2
	│   ├── generic_filters.j2
	│   ├── header.j2
	│   ├── interfaces.j2
	│   ├── members_bgp.j2
	│   ├── peer.j2
	│   └── static_routes.j2
	├── update-routers.sh
	└── vars
		├── dcg-1.router.nl.coloclue.net.yml
		├── dcg-2.router.nl.coloclue.net.yml
		├── eunetworks-2.router.nl.coloclue.net.yml
		├── generic.yml
		├── members_bgp.yml
		├── peers.yml
		├── statics-dcg.yml
		└── statics-eunetworks.yml

Usage:
------

    ./update-routers.sh

Dependencies:
-------------

    rtrsub - https://github.com/job/rtrsub
    jinja2 - http://jinja.pocoo.org/
    hiyapyco - https://pypi.python.org/pypi/HiYaPyCo
    bgpq3  - https://github.com/snar/bgpq3

Author:
-------

Copyright (c) 2014-2017, Job Snijders <job@instituut.net>
