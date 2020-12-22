# Chef Notes

## Notes

### Run Chef scripts locally

```
chef-client -z whatever.rb
chef-apply hello.rb
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


