#
# Cookbook:: demo-client
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

include_recipe 'chef-client::config'
include_recipe 'chef-client'
include_recipe 'audit'