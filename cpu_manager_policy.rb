# Controling CPU Management Policies on the Node needs delete the cpu_manager_state file.
# Ref:
# https://kubernetes.io/docs/tasks/administer-cluster/cpu-management-policies/
# You could use some grep to determine the policy name like this:
#   only_if "grep '\"policyName\":\"none\"' #{cpu_state_file}"
# but using json is much more reliable and elegant way

require 'json'

# Set the path to the cpu_manager_state file.
cpu_state_file='/var/lib/kubelet/cpu_manager_state'

# Read the contents of the cpu_manager_state file into a string.
file_contents = File.read(cpu_state_file)

# Parse the JSON data in the file_contents string into a Ruby hash.
json_data = JSON.parse(file_contents)

# Extract the value of the 'policyName' key from the JSON data.
policy_name = json_data['policyName']

# run a shell command that removes the
# cpu_manager_state file only if the 'policyName' value is 'none'.
execute 'remove default cpu state file' do
  # command "rm -f /var/lib/kubelet/cpu_manager_state"
  # Set the command to remove the stale cpu_manager_state file.
  command "rm -f #{cpu_state_file}"
  # Only run the command if the policyName value is 'none'.
  # Next run should not remove it as it's set to static policy.
  # only_if "grep '\"policyName\":\"none\"' #{cpu_state_file}" # <---
  only_if { policy_name == 'none' } # <---
end
