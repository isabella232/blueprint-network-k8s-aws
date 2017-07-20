resource "aws_internet_gateway" "public" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name              = "${var.name}-IG"
    KubernetesCluster = "${var.kubernetes_cluster}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public.id}"
  }

  # Ignore routing table changes because we will add Kubernetes PodCIDR routing outside of Terraform
  lifecycle {
    ignore_changes = ["route"]
  }

  tags {
    Name              = "${var.name}-rt"
    KubernetesCluster = "${var.kubernetes_cluster}"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${var.public_subnets[count.index]}"
  availability_zone = "${var.azs[count.index]}"
  count             = "${length(var.azs)}"

  tags {
    Name              = "${var.name}-${var.azs[count.index]}"
    KubernetesCluster = "${var.kubernetes_cluster}"
  }

  lifecycle {
    create_before_destroy = true
  }

  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "public" {
  count          = "${length(var.azs)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}
