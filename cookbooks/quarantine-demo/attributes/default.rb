default['audit']['fetcher'] = "chef-server"
default['audit']['reporter'] = "chef-server-automate"
default['audit']['profiles'] = [
    :name => "demo-baseline",
    :compliance => "admin@example.com/demo-baseline"
]