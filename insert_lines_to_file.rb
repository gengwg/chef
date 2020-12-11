# insert lines to a file

file '/tmp/myfile' do
  content "hello world\n"
end

ruby_block 'insert line' do
  block do
    file = Chef::Util::FileEdit.new('/tmp/myfile')
    file.insert_line_if_no_match('/alice/', 'hello alice')
    file.insert_line_if_no_match('/bob/', 'hello bob')
    file.write_file
  end
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

