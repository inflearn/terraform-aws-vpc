################################################################################
# Endpoint(s)
################################################################################

data "aws_vpc_endpoint_service" "this" {
  for_each = { for k, v in var.endpoints : k => v if var.create }

  service      = try(each.value.service, null)
  service_name = try(each.value.service_name, null)

  filter {
    name   = "service-type"
    values = [try(each.value.service_type, "Interface")]
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = { for k, v in var.endpoints : k => v if var.create && try(v.create, true) }

  vpc_id            = var.vpc_id
  service_name      = data.aws_vpc_endpoint_service.this[each.key].service_name
  vpc_endpoint_type = try(each.value.service_type, "Interface")
  auto_accept       = try(each.value.auto_accept, null)

  security_group_ids  = try(each.value.service_type, "Interface") == "Interface" ? distinct(concat(var.security_group_ids, try(each.value.security_group_ids, []))) : null
  subnet_ids          = try(each.value.service_type, "Interface") == "Interface" ? distinct(concat(var.subnet_ids, try(each.value.subnet_ids, []))) : null
  route_table_ids     = try(each.value.service_type, "Interface") == "Gateway" ? try(each.value.route_table_ids, null) : null
  policy              = try(each.value.policy, null)
  private_dns_enabled = try(each.value.service_type, "Interface") == "Interface" ? try(each.value.private_dns_enabled, null) : null

  tags = merge(var.tags, try(each.value.tags, {}))

  timeouts {
    create = try(var.timeouts.create, "10m")
    update = try(var.timeouts.update, "10m")
    delete = try(var.timeouts.delete, "10m")
  }
}
