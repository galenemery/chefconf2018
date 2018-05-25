# Overview

Every Chef installation needs a Chef Repository. This is the place where cookbooks, roles, config files and other artifacts for managing systems with Chef will live. We strongly recommend storing this repository in a version control system such as Git and treat it like source code.

While we prefer Git, and make this repository available via GitHub, you are welcome to download a tar or zip archive and use your favorite version control system to manage the code.

# Repository Directories

This repository contains several directories, and each directory contains a README file that describes what it is for in greater detail, and how to use it for managing your systems with Chef.

- `cookbooks/` - Cookbooks you download or create.
- `data_bags/` - Store data bags and items in .json in the repository.
- `roles/` - Store roles in .rb or .json in the repository.
- `environments/` - Store environments in .rb or .json in the repository.

# Configuration

The config file, `.chef/knife.rb` is a repository specific configuration file for knife. If you're using the Chef Platform, you can download one for your organization from the management console. If you're using the Open Source Chef Server, you can generate a new one with `knife configure`. For more information about configuring Knife, see the Knife documentation.

<https://docs.chef.io/knife.html>

# Next Steps

Read the README file in each of the subdirectories for more information about what goes in those directories.


TODO:

1) Build Webhook listener
--Use AWS API to quarantine 'failed' system
2) Harden systems
3) Setup inspec to run via audit
4) Install/run National parks
5) Create auto-scaling group w/ ELB
5) Test

Demo track:
1) Login to system
2) Make a change to a config that's monitored via inspec `sudo apt-get install telnetd`
3) Inspec runs via audit cookbook `sudo chef-client`
4) Report goes into A2, system goes to 'failed'
5) Notifications triggered from A2 to Slack/Webhook
6) Webhook fires into AWS, null-routing the system
7) Once the system is null-routed, ELB notices the pool is short, builds a new system
8) New system comes up clean, shows up in A2, is added to ELB
9) Fin.

Talk Track:
1) Trust
--Least Privilege
--How do we decide we trust a system?
--What does it mean if that trust is broken?
2) Automation
--Humans act on code, not on machines
--Resilient.  Systems react and repair to changes automatically
3) Demo
4) For Realsies
--Re-launch everything the bad system could touch.
--Move to a new VPC entirely, leaving the 'dirty' system alone in its current location
--Disconnect Data, reconnect w/ fake data
--Chaos Monkey or the like to ensure that when systems are taken away, the system is resilient
