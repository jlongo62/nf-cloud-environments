locals {
  pools = {
    head   = var.head_pool
    worker = var.worker_pool
  }
}

# Head pool runs the Nextflow driver; worker pool runs the pipeline tasks.
resource "azurerm_batch_pool" "this" {
  for_each = local.pools

  name                           = "${var.name_prefix}-${each.key}"
  resource_group_name            = var.resource_group_name
  account_name                   = azurerm_batch_account.this.name
  vm_size                        = each.value.vm_size
  node_agent_sku_id              = "batch.node.ubuntu 22.04"
  max_tasks_per_node             = each.value.task_slots_per_node
  target_node_communication_mode = "Simplified"

  storage_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "ubuntu-hpc"
    sku       = "2204"
    version   = "latest"
  }

  container_configuration {
    type = "DockerCompatible"
  }

  auto_scale {
    evaluation_interval = "PT5M"
    formula             = <<-EOT
      $tasks = max($PendingTasks.GetSample(1), ${each.value.min_nodes});
      $TargetDedicatedNodes = min($tasks, ${each.value.max_nodes});
      $NodeDeallocationOption = taskcompletion;
    EOT
  }
}

variable "head_pool" {
  description = "Batch pool that runs the Nextflow head (driver) job."
  type = object({
    vm_size             = optional(string, "Standard_D2s_v3")
    min_nodes           = optional(number, 0)
    max_nodes           = optional(number, 1)
    task_slots_per_node = optional(number, 2)
  })
  default = {}
}

variable "worker_pool" {
  description = "Batch pool that runs Nextflow process tasks. task_slots_per_node must equal the VM core count."
  type = object({
    vm_size             = optional(string, "Standard_D2s_v3")
    min_nodes           = optional(number, 0)
    max_nodes           = optional(number, 3)
    task_slots_per_node = optional(number, 2)
  })
  default = {}
}

output "head_pool_name" {
  description = "Name of the Batch pool for the Nextflow head job."
  value       = azurerm_batch_pool.this["head"].name
}

output "worker_pool_name" {
  description = "Name of the Batch pool for Nextflow process tasks."
  value       = azurerm_batch_pool.this["worker"].name
}
