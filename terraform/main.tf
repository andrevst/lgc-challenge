module "network" {
  source               = "./modules/network"
  project              = var.project
  cidr_block           = var.cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "host" {
  source         = "./modules/host"
  depends_on     = [module.network]
  project        = var.project
  cluster_name   = var.cluster_name
  cidr_block     = var.cidr_block
  retention_days = var.retention_days
  desired_size   = var.desired_size
  max_size       = var.max_size
  min_size       = var.min_size
  instance_type  = var.instance_type
  capacity_type  = var.capacity_type
  vpc_id         = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnet_ids
}