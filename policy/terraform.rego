package main
import rego.v1

# conftest's HCL2 parser turns every block into a list, so iterate with `some x in ...`.
# Custom rules that fill gaps found in the benchmark (input = conftest HCL2 parse of a .tf file)

deny_literal_password contains msg if {
	some name
	some db in input.resource.aws_db_instance[name]
	pw := db.password
	is_string(pw)
	not startswith(pw, "${")
	msg := sprintf("deny_literal_password: aws_db_instance.%s has a literal password; use a sensitive variable or manage_master_user_password", [name])
}

deny_aws_key_literal contains msg if {
	some block in input.locals
	some k, v in block
	is_string(v)
	regex.match(`^(AKIA|ASIA)[A-Z0-9]{16}$`, v)
	msg := sprintf("deny_aws_key_literal: locals.%s looks like an AWS access key id", [k])
}

admin_ports := {22, 3389}

deny_world_admin_port contains msg if {
	some name
	some sg in input.resource.aws_security_group[name]
	some ing in sg.ingress
	"0.0.0.0/0" in ing.cidr_blocks
	some p in admin_ports
	ing.from_port <= p
	p <= ing.to_port
	msg := sprintf("deny_world_admin_port: aws_security_group.%s exposes port %d to 0.0.0.0/0", [name, p])
}

# conftest treats any rule named deny_* as a deny rule, so no aggregate `deny` set is needed (it would double-count).
