# insert lines to a file

# file '/tmp/myfile' do
#   content "hello world\n"
# end

ruby_block 'insert line' do
  block do
    # note for this to work, file must exist first. otherwise got error
    file = Chef::Util::FileEdit.new('/tmp/myfile')
    # note it only checks if line exists, order may not be correct
    file.insert_line_if_no_match('/alice/', 'hello alice')
    file.insert_line_if_no_match('bob', 'hello bob')
    file.write_file
    # check if file content changed; if so notifies execute command
    if file.file_edited?
      puts "\n!!file edited!!\n"
      notifies :run, 'execute[hello]'
    end
  end
end

execute 'hello' do
  command 'echo hello'
  action :nothing
end

# $ chef-apply insert_line_to_file.rb
# [2020-12-11T10:18:20-08:00] ERROR: shard_seed: Failed to get dmi property serial_number: is dmidecode installed?
# Recipe: (chef-apply cookbook)::(chef-apply recipe)
#   * file[/tmp/myfile] action create (up to date)
#   * ruby_block[insert line] action run
#     - execute the ruby block insert line
# $ cat /tmp/myfile
# hello world
# hello alice
# hello bob

