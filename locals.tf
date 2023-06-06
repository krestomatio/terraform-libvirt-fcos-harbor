locals {
  data_volume_path = "/var/mnt/data"
  harbor_dir_path  = "/var/opt/harbor"
  etc_hosts = var.etc_hosts != null ? var.etc_hosts : [
    {
      ip       = "127.0.0.1"
      hostname = split(".", var.fqdn)[0],
      fqdn     = var.fqdn
    }
  ]
  etc_hosts_extra = var.etc_hosts_extra != null ? var.etc_hosts_extra : "${var.cidr_ip_address} ${var.external_fqdn}"
  post_hook = {
    path    = "/usr/local/bin/harbor-certbot-renew-hook"
    content = <<-TEMPLATE
      #!/bin/bash

      # vars
      harbor_config_path="/var/opt/harbor"
      harbor_data_path="/var/mnt/data"
      harbor_cert_folder_path="${local.data_volume_path}/secret/cert"
      harbor_cert_path="$$${harbor_cert_folder_path}/server.crt"
      harbor_key_path="$$${harbor_cert_folder_path}/server.key"
      harbor_proxy_uid="10000"
      harbor_proxy_gid="10000"
      source_cert_folder_path="/etc/letsencrypt/live/${var.external_fqdn}"
      source_cert_path="$$${source_cert_folder_path}/fullchain.pem"
      source_key_path="$$${source_cert_folder_path}/privkey.pem"

      # harbor dir
      cd $harbor_config_path

      # handle cert correct placement
      # dir
      mkdir -p $$${harbor_cert_folder_path}
      # cert
      cp -f "$$${source_cert_path}" "$$${harbor_cert_path}"
      # key
      cp -f "$$${source_key_path}" "$$${harbor_key_path}"
      # owner
      chown $$${harbor_proxy_uid}:$$${harbor_proxy_gid} "$$${harbor_cert_folder_path}" "$$${harbor_cert_path}" "$$${harbor_key_path}"
      # permissions
      chmod 0600 "$$${harbor_cert_path}" "$$${harbor_key_path}"

      # reload or start nginx container

      if docker-compose ps proxy &> /dev/null
      then
        docker-compose exec proxy nginx -s reload
      else
        echo "Nginx in proxy service not running"
      fi
    TEMPLATE
  }
}
