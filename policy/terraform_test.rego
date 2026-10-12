package main
import rego.v1

world_sg(lo, hi) := {"resource": {"aws_security_group": {"s": [{"ingress": [{"from_port": lo, "to_port": hi, "cidr_blocks": ["0.0.0.0/0"]}]}]}}}

test_literal_password_denied if {
	count(deny_literal_password) == 1 with input as {"resource": {"aws_db_instance": {"db": [{"password": "hunter2"}]}}}
}
test_var_password_allowed if {
	count(deny_literal_password) == 0 with input as {"resource": {"aws_db_instance": {"db": [{"password": "${var.db_password}"}]}}}
}
test_aws_key_denied if {
	count(deny_aws_key_literal) == 1 with input as {"locals": [{"k": "AKIAIOSFODNN7EXAMPLE"}]}
}
test_non_key_allowed if {
	count(deny_aws_key_literal) == 0 with input as {"locals": [{"k": "hello"}]}
}
test_world_all_ports_hits_both_admin_ports if {
	count(deny_world_admin_port) == 2 with input as world_sg(0, 65535)
}
test_world_ssh_denied if {
	count(deny_world_admin_port) == 1 with input as world_sg(22, 22)
}
test_https_allowed if {
	count(deny_world_admin_port) == 0 with input as world_sg(443, 443)
}
