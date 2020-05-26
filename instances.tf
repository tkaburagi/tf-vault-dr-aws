resource "aws_instance" "vault_ec2" {
  ami = var.ami
  count = var.num_of_site
  instance_type = var.vault_instance_type
  vpc_security_group_ids = [aws_security_group.vault_security_group.id]
  tags = merge(var.tags, map("Name", "${var.vault_instance_name}-${count.index}"))
  subnet_id = aws_subnet.public.*.id[count.index]
  key_name = aws_key_pair.deployer.id
  associate_public_ip_address = true
  private_ip = var.private_ips[count.index]
}