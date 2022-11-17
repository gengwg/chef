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

## Errors

```
Chef::Exceptions::ImmutableAttributeModification: Node attributes are read-only when you do not specify which precedence level to set. To set an attribute use code like   `node.default["key"] = "value"'
```

===>

```
node['cookbook_name']['attribute_name'] = 'abc'
# change to:
node.default['cookbook_name']['attribute_name'] = 'abc'
```

## Misc

attributes are defined by

    * the state of the node itself
    * cookbooks in attribute files and recipes
    * roles
    * environments

run lists specify what recipes the node should run, along with the order in which they should run.


