resource "aws_instance" "vault_ec2" {
  ami = var.ami
  count = var.num_of_site
  instance_type = var.vault_instance_type
  vpc_security_group_ids = [aws_security_group.vault_security_group.id]
  tags = merge(var.tags, map("Name", "${var.vault_instance_name}-${count.index}"))
  subnet_id = aws_subnet.public.*.id[count.index]
  key_name = aws_key_pair.deployer.id
  private_ip = var.private_ips[count.index]
  
  user_data =<<-EOF
                #!/bin/sh

                cd /home/ubuntu
                mkdir vault-raft-data
                sudo apt-get install zip unzip

                wget "${var.vault_dl_url}"
                wget https://raw.githubusercontent.com/tkaburagi/vault-configs/master/vault-dr-template-aws.hcl
                wget https://certs-tkaburagi.s3-ap-northeast-1.amazonaws.com/dr-vaultvault-hashidemos.crt.pem
                wget https://certs-tkaburagi.s3-ap-northeast-1.amazonaws.com/dr-vaultvault-hashidemos.key.pem
                wget https://certs-tkaburagi.s3-ap-northeast-1.amazonaws.com/dr-vaultca-hashidemos.crt.pem

                unzip vault*.zip
                rm vault*zip

                chmod +x vault

                export AWS_SECRET_ACCESS_KEY=${var.secret_key}
                export AWS_ACCESS_KEY_ID=${var.access_key}
                export VAULT_AWSKMS_SEAL_KEY_ID=${aws_kms_key.kms_key.key_id}
                export API_ADDR_REPLACE=https://${var.vault_fqdn[count.index]}
                export CLUSTER_ADDR_REPLACE=${var.private_ips[count.index]}

                sed "s|API_ADDR_REPLACE|`echo $API_ADDR_REPLACE`|g" vault-dr-template-aws.hcl > config-0.hcl
                sed "s|CLUSTER_ADDR_REPLACE|`echo $CLUSTER_ADDR_REPLACE`|g" config-0.hcl > config-1.hcl
                sed "s|NODE_ID_REPLACE|`echo $CLUSTER_ADDR_REPLACE`|g" config-1.hcl > config.hcl

                rm config-*.hcl
                rm vault-tempate-aws.hcl

                sleep 60

                nohup ./vault server -config /home/ubuntu/config.hcl start -log-level=debug > vault.log &

              EOF
}