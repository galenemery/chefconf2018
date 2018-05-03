default['chef_client']['interval'] = '300'
default['chef_client']['splay'] = '60'
default['chef_client']['config']['ssl_verify_mode'] = ':verify_none'
default['chef_client']['config']['verify_api_cert'] = 'false'

default['audit']['reporter'] = 'chef-server-automate'
default['audit']['fetcher'] = 'chef-server'
default['audit']['insecure'] = true
