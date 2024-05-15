module "network" {
  source       = "./modules/network"
  project      = var.project
  subnet_count = var.subnet_count
  cidr_block   = var.cidr_block
}

module "host" {
  source         = "./modules/host"
  depends_on     = [module.network]
  project        = var.project
  cluster_name   = var.cluster_name
  retention_days = var.retention_days
  desired_size   = var.desired_size
  max_size       = var.max_size
  min_size       = var.min_size
  instance_type  = var.instance_type
  capacity_type  = var.capacity_type
  vpc_id         = module.network.vpc_id
  subnet_ids     = module.network.subnet_ids
}