name 'quarantine-demo'
maintainer 'Galen Emery'
maintainer_email 'galen@galenemery.com'
license 'Apache 2.0'
description 'Installs/Configures quarantine-demo'
long_description 'Installs/Configures quarantine-demo'
version '0.1.3'
chef_version '>= 12.1' if respond_to?(:chef_version)

depends 'os-hardening'
depends 'audit'

# The `issues_url` points to the location where issues for this cookbook are
# tracked.  A `View Issues` link will be displayed on this cookbook's page when
# uploaded to a Supermarket.
#
# issues_url 'https://github.com/<insert_org_here>/quarantine-demo/issues'

# The `source_url` points to the development repository for this cookbook.  A
# `View Source` link will be displayed on this cookbook's page when uploaded to
# a Supermarket.
#
# source_url 'https://github.com/<insert_org_here>/quarantine-demo'
