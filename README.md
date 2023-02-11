# Chef Notes

## Notes

### Run Chef scripts locally

```
chef-client -z whatever.rb
chef-apply hello.rb
```

### Run Chef shell

```
chef-shell -z
```

### Create an empty file using chef shell

```
# switch to recipes mode:
chef:attributes (17.9.52)> recipe_mode
 => :attributes
chef:recipe (17.9.52)>

# chef-shell creates the rousrce and put it in the run-list, but not yet created the file
chef:recipe (17.9.52)> file '/tmp/aa'
 => <file[/tmp/aa] @name: "/tmp/aa" @before: nil @params: {} @provider: nil @allowed_actions: [:nothing, :create, :delete, :touch, :create_if_missing] @action: [:create] @updated: false @updated_by_last_action: false @source_line: "(irb#1):3:in `<main>'" @guard_interpreter: nil @default_guard_interpreter: :default @elapsed_time: 0 @declared_type: :file @cookbook_name: nil @recipe_name: nil>
 
# initiate a chef infra client run
chef:recipe (17.9.52)> run_chef
.....
[2023-01-22T10:58:03-08:00] INFO: Processing file[/tmp/aa] action create ((irb#1) line 3)
[2023-01-22T10:58:03-08:00] INFO: file[/tmp/aa] created file /tmp/aa
chef:recipe (17.9.52)> ls('/tmp').grep('aa')
 => ["aa"]
$ ls /tmp/aa
/tmp/aa
```


### Chef rollbacks are not safe

Chef model is a roll-forward one. As such, rollbacks are not necessarily safe. You need treat rollbacks to be standard diff that are tested.

- Understand the intent of the original diff (so you can be sure you're properly undoing it).
- Find the commit ID.
- Rever the Chef change
- Test the diff

### Must configure dependency in metadata when including another cookbook

If you want to include a recipe from another cookbook:

```
include_recipe 'my_cookbook::my_recipe'
```

You must have this line in metadata.rb in current cookbook:

```
depends 'my_cookbook'
```

If removed from metadata.rb, it causes error:

```
[2023-01-13T17:00:21-08:00] FATAL: Chef::Exceptions::CookbookNotFound: Cookbook my_cookbook not found. If you're loading my_cookbook from another cookbook, make sure you configure the dependency in your metadata
```

## Syntax

To print message to standard output inside a `ruby_block`, one can use `puts('aaaaaa')` or `STDOUT.puts('aaaaaaa')`; outside a `ruby_block`, one can use `log('aaaaaa')`:

```
log "**********gwg: #{node['network']['interfaces']}"
```

Format numbers:

```
log 'IPADDR=169.254.1.2%02d' % [ip]
log(format('IPADDR=169.254.1.2%02d', 7))
#Output: * log[IPADDR=169.254.1.207] action write
```

Loop over each network interface:

```
  node['network']['interfaces'].each do |nic, _|
    if nic.include? 'ib'
      ruby_block 'insert_lines' do
        block do
          something
        end
      end
    end
  end
```

Apply to only a few hosts:

```
if ['host1', 'host2', 'host3'].include? node['hostname']
  # do something to the host
end
```

Ignore Chef failure and continue rest of recipe:

```
execute 'mycommand' do
  ...
  ignore_failure true
end
```

To restrict recipe to Run only on centos hosts, put this at the top of the recipe:

```
return unless node.centos?
```


Get ipv6 address for some interface

```

addresses = node['network']['interfaces']['ethx']['addresses']
addresses.each_key do |address|
  if addresses[address]['family'].downcase == 'inet6' &&
       addresses[address]['scope'].downcase == 'global'
    node.default['cookbook']['myaddr'] = address
  end
end
```

Add '%' to each item in the list, then join with comma

```
node.default['sudo']['entry'] += [
  node.default['sudo']['groups'].map { |group| '%' + group }.join(',') +
  ' ALL=(ALL) NOPASSWD: ' + cmd,
]
```

Only template if variable is not empty:

```
# templates/default/myfile.yaml.erb
<% unless node['my_cookbook']['some_attribute'].to_s.strip.empty? %>
<%= @some_var %>
<% end%>

# recipes/server.rb
template '/etc/config/myfile.yaml' do
  owner 'root'
  group 'root'
  mode '0640'
  source 'myfile.erb'
  variables(
    :some_var => node['my_cookbook']['some_attribute'],
    )
end
```

Append a long string (yaml config) to an existing file.
NOTE: this only works if `/etc/config/my-config.yaml` is not managed by template.
Otherwise, Chef will revert all changes to what the template says it is.

```
# method 1
long_string = '- schedulerName: foo-scheduler
  pluginConfig:
  - args:
      scoringStrategy:
        resources:
        - name: cpu
          weight: 1
        - name: memory
          weight: 1
        - name: nvidia.com/gpu
          weight: 3
        #requestedToCapacityRatioParam:
        requestedToCapacityRatio:
          shape:
          - utilization: 0
            score: 0
          - utilization: 100
            score: 10
        type: RequestedToCapacityRatio
    name: NodeResourcesFit'

ruby_block 'insert_lines' do
  block do
    file = Chef::Util::FileEdit.new('/etc/config/my-config.yaml')
    file.insert_line_if_no_match('foo', long_string)
    file.insert_line_if_no_match('bar', 'hello')
    file.write_file
  end
end

# method 2
cookbook_file '/tmp/my-config.yaml' do
  source 'my-config.yaml'
end

bash 'append_to_config' do
  user 'root'
  code <<-EOF
      cat /tmp/my-config.yaml >> /etc/config/my-config.yaml
   EOF
  rm /tmp/my-config.yaml
  not_if "grep -q foo /etc/kubernetes/config/kube-scheduler.yaml"
end

# method 3
execute 'xrig' do
  command 'cat /tmp/my-config.yaml >> /etc/config/my-config.yaml'
  only_if chk_cmd
end
```

Convert a sequence into array:

```
$ chef-shell
chef (16.6.14)> ('05'..'08').to_a
 => ["05", "06", "07", "08"]
```

Add prefix/suffix to each element of array:

```
chef (16.6.14)> ('05'..'08').to_a.map { |x| 'my-node-00' + x + '.example.com' }
 => ["my-node-0005.example.com", "my-node-0006.example.com", "my-node-0007.example.com", "my-node-0008.example.com
```

### Check chef method location and if it exists

If the method exists, it show the location of it:

```
chef (17.9.52)> node.method(:my_method?)
 => #<Method: Chef::Node#my_method /var/chef/cache/cookbooks/my_cookbook/libraries/node_functions.rb:18>
```

If the method does not exist, it show 'undefined method' error:

```
chef (17.9.52)> node.method(:my_method?)
(irb):1:in `method': undefined method `my_method?' for class `#<Class:#<Chef::Node:0x00000000037737a8>>' (NameError)
```

### To delete an item from array 

E.g. exclude certain package from controller nodes:

```
if node['fqdn'].include?('ctrlplane')
  node.default['mycookbook']['packages'].delete('git-lfs')
end
```

One can verify the element is removed using chef-shell, make sure the item is not in the list any more.

```
chef (xx.x.xx)> node.default['mycookbook']['packages']
 =>
["ack",
 "bind-utils",
...
 "zsh"]
```

### Add a drop-in config for systemd unit

For systemd unit, it is recommended using a drop-in file instead of modifying the xyz.service file directly. Here is how to do it in Chef using a systemd drop-in config:

First create a drop-in file (ex. `templates/default/10-restart_on_failure.conf.erb`):

```
[Service]
Restart=on-failure
RestartSec=5
```

Then in your slurm cookbook, place that drop-in config into the systemd directory, like this:

```
if node.centos8?
  slurmd_systemd_dir = "/etc/systemd/system/#{slurmd_srv_name}.service.d/"
  directory slurmd_systemd_dir do
    owner  'root'
    group  'root'
    mode   '0755'
  end
  template "#{slurmd_systemd_dir}/10-restart_on_failure.conf" do
    source '10-restart_on_failure.conf.erb'
    owner  'root'
    group  'root'
    mode   '0644'
    action :create
    notifies :run, 'execute[daemon-reload]', :immediately
    notifies :restart, "service[#{slurmd_srv_name}]", :immediately
  end
end
```

We restrict it to centos 8 because issue currently only observed in centos 8. c7 seems fine.


## Errors

### Node attributes are read-only 

```
Chef::Exceptions::ImmutableAttributeModification: Node attributes are read-only when you do not specify which precedence level to set. To set an attribute use code like   `node.default["key"] = "value"'
```

===>

Node attributes are read-only when you do not specify which precedence level to set. To set an attribute use code like   `node.default["key"] = "value"`:

```
node['cookbook_name']['attribute_name'] = 'abc'
# change to:
node.default['cookbook_name']['attribute_name'] = 'abc'
```

Similarly for previous example:

`node['mycookbook']['packages'].delete('git-lfs')` would fail same error. One should use:

```
node.default['mycookbook']['packages'].delete('git-lfs')
```

## Misc

attributes are defined by

    * the state of the node itself
    * cookbooks in attribute files and recipes
    * roles
    * environments

run lists specify what recipes the node should run, along with the order in which they should run.


