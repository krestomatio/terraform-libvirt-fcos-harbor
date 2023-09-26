data "template_file" "butane_snippet_install_harbor" {
  template = <<TEMPLATE
---
variant: fcos
version: 1.4.0
storage:
  files:
    # pkg dependencies to be installed by additional-rpms.service
    - path: /var/lib/additional-rpms.list
      overwrite: false
      append:
        - inline: |
            moby-engine
            docker-compose
            firewalld
    - path: ${local.harbor_dir_path}/harbor.yml
      mode: 0644
      overwrite: true
      contents:
        inline: |
          # Configuration file of Harbor

          # The IP address or hostname to access admin UI and registry service.
          # DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
          hostname: ${var.external_fqdn}

          # http related config
          http:
            # port for http, default is 80. If https enabled, this port will redirect to https port
            port: 80

          # https related config
          https:
            # https port for harbor, default is 443
            port: 443
            # The path of cert and key files for nginx
            certificate: /etc/letsencrypt/live/${var.external_fqdn}/fullchain.pem
            private_key: /etc/letsencrypt/live/${var.external_fqdn}/privkey.pem

          # # Uncomment following will enable tls communication between all harbor components
          # internal_tls:
          #   # set enabled to true means internal tls is enabled
          #   enabled: true
          #   # put your cert and key files on dir
          #   dir: /etc/harbor/tls/internal

          # Uncomment external_url if you want to enable external proxy
          # And when it enabled the hostname will no longer used
          external_url: https://${var.external_fqdn}

          # The initial password of Harbor admin
          # It only works in first time to install harbor
          # Remember Change the admin password from UI after launching Harbor.
          harbor_admin_password: ${var.admin_password}

          # Harbor DB configuration
          database:
            # The password for the root user of Harbor DB. Change this before any production use.
            password: ${var.database_root_password}
            # The maximum number of connections in the idle connection pool. If it <=0, no idle connections are retained.
            max_idle_conns: 100
            # The maximum number of open connections to the database. If it <= 0, then there is no limit on the number of open connections.
            # Note: the default number of connections is 1024 for postgres of harbor.
            max_open_conns: 900
            # The maximum amount of time a connection may be reused. Expired connections may be closed lazily before reuse. If it <= 0, connections are not closed due to a connection's age.
            # The value is a duration string. A duration string is a possibly signed sequence of decimal numbers, each with optional fraction and a unit suffix, such as "300ms", "-1.5h" or "2h45m". Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h".
            conn_max_lifetime: 5m
            # The maximum amount of time a connection may be idle. Expired connections may be closed lazily before reuse. If it <= 0, connections are not closed due to a connection's idle time.
            # The value is a duration string. A duration string is a possibly signed sequence of decimal numbers, each with optional fraction and a unit suffix, such as "300ms", "-1.5h" or "2h45m". Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h".
            conn_max_idle_time: 0

          # The default data volume
          data_volume: ${local.data_volume_path}


          # Harbor Storage settings by default is using /data dir on local filesystem
          # Uncomment storage_service setting If you want to using external storage
          %{~if var.storage_service == null~}
          # storage_service:
          #   # ca_bundle is the path to the custom root ca certificate, which will be injected into the truststore
          #   # of registry's containers.  This is usually needed when the user hosts a internal storage with self signed certificate.
          #   ca_bundle:
          %{~else~}
          storage_service:
            %{~if var.storage_service.ca_bundle != null~}
            ca_bundle: ${var.storage_service.ca_bundle}
            %{~endif~}
            %{~if var.storage_service.filesystem != null~}
            filesystem:
              rootdirectory: ${var.storage_service.filesystem.rootdirectory}
            %{~endif~}
            %{~if var.storage_service.s3 != null~}
            s3:
              bucket: ${var.storage_service.s3.bucket}
              region: ${var.storage_service.s3.region}
              regionendpoint: ${var.storage_service.s3.regionendpoint}
              %{~if var.storage_service.s3.accesskey != null~}
              accesskey: ${var.storage_service.s3.accesskey}
              %{~endif~}
              %{~if var.storage_service.s3.secretkey != null~}
              secretkey: ${var.storage_service.s3.secretkey}
              %{~endif~}
              %{~if var.storage_service.s3.forcepathstyle != null~}
              forcepathstyle: ${var.storage_service.s3.forcepathstyle}
              %{~endif~}
              %{~if var.storage_service.s3.accelerate != null~}
              accelerate: ${var.storage_service.s3.accelerate}
              %{~endif~}
              %{~if var.storage_service.s3.encrypt != null~}
              encrypt: ${var.storage_service.s3.encrypt}
              %{~endif~}
              %{~if var.storage_service.s3.keyid != null~}
              keyid: ${var.storage_service.s3.keyid}
              %{~endif~}
              %{~if var.storage_service.s3.secure != null~}
              secure: ${var.storage_service.s3.secure}
              %{~endif~}
              %{~if var.storage_service.s3.v4auth != null~}
              v4auth: ${var.storage_service.s3.v4auth}
              %{~endif~}
              %{~if var.storage_service.s3.chunksize != null~}
              chunksize: ${var.storage_service.s3.chunksize}
              %{~endif~}
              %{~if var.storage_service.s3.multipartcopychunksize != null~}
              multipartcopychunksize: ${var.storage_service.s3.multipartcopychunksize}
              %{~endif~}
              %{~if var.storage_service.s3.multipartcopymaxconcurrency != null~}
              multipartcopymaxconcurrency: ${var.storage_service.s3.multipartcopymaxconcurrency}
              %{~endif~}
              %{~if var.storage_service.s3.multipartcopythresholdsize != null~}
              multipartcopythresholdsize: ${var.storage_service.s3.multipartcopythresholdsize}
              %{~endif~}
              %{~if var.storage_service.s3.rootdirectory != null~}
              rootdirectory: ${var.storage_service.s3.rootdirectory}
              %{~endif~}
            %{~endif~}
            %{~if var.storage_service.redirect != null~}
            redirect:
              disable: ${var.storage_service.redirect ? "false" : "true"}
            %{~endif~}
          %{~endif~}

          #   # storage backend, default is filesystem, options include filesystem, azure, gcs, s3, swift and oss
          #   # for more info about this configuration please refer https://docs.docker.com/registry/configuration/
          #   filesystem:
          #     maxthreads: 100
          #   # set disable to true when you want to disable registry redirect
          #   redirect:
          #     disable: false

          # Trivy configuration
          #
          # Trivy DB contains vulnerability information from NVD, Red Hat, and many other upstream vulnerability databases.
          # It is downloaded by Trivy from the GitHub release page https://github.com/aquasecurity/trivy-db/releases and cached
          # in the local file system. In addition, the database contains the update timestamp so Trivy can detect whether it
          # should download a newer version from the Internet or use the cached one. Currently, the database is updated every
          # 12 hours and published as a new release to GitHub.
          trivy:
            # ignoreUnfixed The flag to display only fixed vulnerabilities
            ignore_unfixed: false
            # skipUpdate The flag to enable or disable Trivy DB downloads from GitHub
            #
            # You might want to enable this flag in test or CI/CD environments to avoid GitHub rate limiting issues.
            # If the flag is enabled you have to download the `trivy-offline.tar.gz` archive manually, extract `trivy.db` and
            # `metadata.json` files and mount them in the `/home/scanner/.cache/trivy/db` path.
            skip_update: false
            #
            # The offline_scan option prevents Trivy from sending API requests to identify dependencies.
            # Scanning JAR files and pom.xml may require Internet access for better detection, but this option tries to avoid it.
            # For example, the offline mode will not try to resolve transitive dependencies in pom.xml when the dependency doesn't
            # exist in the local repositories. It means a number of detected vulnerabilities might be fewer in offline mode.
            # It would work if all the dependencies are in local.
            # This option doesn't affect DB download. You need to specify "skip-update" as well as "offline-scan" in an air-gapped environment.
            offline_scan: false
            #
            # Comma-separated list of what security issues to detect. Possible values are `vuln`, `config` and `secret`. Defaults to `vuln`.
            security_check: vuln
            #
            # insecure The flag to skip verifying registry certificate
            insecure: false
            # github_token The GitHub access token to download Trivy DB
            #
            # Anonymous downloads from GitHub are subject to the limit of 60 requests per hour. Normally such rate limit is enough
            # for production operations. If, for any reason, it's not enough, you could increase the rate limit to 5000
            # requests per hour by specifying the GitHub access token. For more details on GitHub rate limiting please consult
            # https://developer.github.com/v3/#rate-limiting
            #
            # You can create a GitHub token by following the instructions in
            # https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
            #
            # github_token: xxx

          jobservice:
            # Maximum number of job workers in job service
            max_job_workers: 10
            # The jobLogger sweeper duration (ignored if `jobLogger` is `stdout`)
            logger_sweeper_duration: 1 #days

          notification:
            # Maximum retry count for webhook job
            webhook_job_max_retry: 3
            # HTTP client timeout for webhook job
            webhook_job_http_client_timeout: 3 #seconds

          # Log configurations
          log:
            # options are debug, info, warning, error, fatal
            level: info
            # configs for logs in local storage
            local:
              # Log files are rotated log_rotate_count times before being removed. If count is 0, old versions are removed rather than rotated.
              rotate_count: 50
              # Log files are rotated only if they grow bigger than log_rotate_size bytes. If size is followed by k, the size is assumed to be in kilobytes.
              # If the M is used, the size is in megabytes, and if G is used, the size is in gigabytes. So size 100, size 100k, size 100M and size 100G
              # are all valid.
              rotate_size: 200M
              # The directory on your host that store log
              location: /var/log/harbor

            # Uncomment following lines to enable external syslog endpoint.
            # external_endpoint:
            #   # protocol used to transmit log to external endpoint, options is tcp or udp
            #   protocol: tcp
            #   # The host of external endpoint
            #   host: localhost
            #   # Port of external endpoint
            #   port: 5140

          #This attribute is for migrator to detect the version of the .cfg file, DO NOT MODIFY!
          _version: 2.8.0

          # Uncomment external_database if using external database.
          # external_database:
          #   harbor:
          #     host: harbor_db_host
          #     port: harbor_db_port
          #     db_name: harbor_db_name
          #     username: harbor_db_username
          #     password: harbor_db_password
          #     ssl_mode: disable
          #     max_idle_conns: 2
          #     max_open_conns: 0
          #   notary_signer:
          #     host: notary_signer_db_host
          #     port: notary_signer_db_port
          #     db_name: notary_signer_db_name
          #     username: notary_signer_db_username
          #     password: notary_signer_db_password
          #     ssl_mode: disable
          #   notary_server:
          #     host: notary_server_db_host
          #     port: notary_server_db_port
          #     db_name: notary_server_db_name
          #     username: notary_server_db_username
          #     password: notary_server_db_password
          #     ssl_mode: disable

          # Uncomment external_redis if using external Redis server
          # external_redis:
          #   # support redis, redis+sentinel
          #   # host for redis: <host_redis>:<port_redis>
          #   # host for redis+sentinel:
          #   #  <host_sentinel1>:<port_sentinel1>,<host_sentinel2>:<port_sentinel2>,<host_sentinel3>:<port_sentinel3>
          #   host: redis:6379
          #   password:
          #   # Redis AUTH command was extended in Redis 6, it is possible to use it in the two-arguments AUTH <username> <password> form.
          #   # username:
          #   # sentinel_master_set must be set to support redis+sentinel
          #   #sentinel_master_set:
          #   # db_index 0 is for core, it's unchangeable
          #   registry_db_index: 1
          #   jobservice_db_index: 2
          #   trivy_db_index: 5
          #   idle_timeout_seconds: 30

          # Uncomment uaa for trusting the certificate of uaa instance that is hosted via self-signed cert.
          # uaa:
          #   ca_file: /path/to/ca

          # Global proxy
          # Config http proxy for components, e.g. http://my.proxy.com:3128
          # Components doesn't need to connect to each others via http proxy.
          # Remove component from `components` array if want disable proxy
          # for it. If you want use proxy for replication, MUST enable proxy
          # for core and jobservice, and set `http_proxy` and `https_proxy`.
          # Add domain to the `no_proxy` field, when you want disable proxy
          # for some special registry.
          proxy:
            http_proxy:
            https_proxy:
            no_proxy:
            components:
              - core
              - jobservice
              - trivy

          # metric:
          #   enabled: false
          #   port: 9090
          #   path: /metrics

          # Trace related config
          # only can enable one trace provider(jaeger or otel) at the same time,
          # and when using jaeger as provider, can only enable it with agent mode or collector mode.
          # if using jaeger collector mode, uncomment endpoint and uncomment username, password if needed
          # if using jaeger agetn mode uncomment agent_host and agent_port
          # trace:
          #   enabled: true
          #   # set sample_rate to 1 if you wanna sampling 100% of trace data; set 0.5 if you wanna sampling 50% of trace data, and so forth
          #   sample_rate: 1
          #   # # namespace used to differenciate different harbor services
          #   # namespace:
          #   # # attributes is a key value dict contains user defined attributes used to initialize trace provider
          #   # attributes:
          #   #   application: harbor
          #   # # jaeger should be 1.26 or newer.
          #   # jaeger:
          #   #   endpoint: http://hostname:14268/api/traces
          #   #   username:
          #   #   password:
          #   #   agent_host: hostname
          #   #   # export trace data by jaeger.thrift in compact mode
          #   #   agent_port: 6831
          #   # otel:
          #   #   endpoint: hostname:4318
          #   #   url_path: /v1/traces
          #   #   compression: false
          #   #   insecure: true
          #   #   timeout: 10s

          # Enable purge _upload directories
          upload_purging:
            enabled: true
            # remove files in _upload directories which exist for a period of time, default is one week.
            age: 168h
            # the interval of the purge operations
            interval: 24h
            dryrun: false

          # Cache layer configurations
          # If this feature enabled, harbor will cache the resource
          # `project/project_metadata/repository/artifact/manifest` in the redis
          # which can especially help to improve the performance of high concurrent
          # manifest pulling.
          # NOTICE
          # If you are deploying Harbor in HA mode, make sure that all the harbor
          # instances have the same behaviour, all with caching enabled or disabled,
          # otherwise it can lead to potential data inconsistency.
          cache:
            # not enabled by default
            enabled: true
            # keep cache for one day by default
            expire_hours: 24
    - path: /usr/local/bin/harbor-installer.sh
      mode: 0754
      overwrite: true
      contents:
        inline: |
          #!/bin/bash -e
          # vars
          harbor_installer_tmp_dir="/tmp"
          harbor_installer_filename="$$${harbor_installer_tmp_dir}/harbor-installer.tgz"

          ## firewalld rules
          if ! systemctl is-active firewalld &> /dev/null
          then
            echo "Enabling firewalld..."
            systemctl restart dbus.service
            restorecon -rv /etc/firewalld
            systemctl enable --now firewalld
            echo "Firewalld enabled..."
          fi
          # Add firewalld rules
          echo "Adding firewalld rules..."
          firewall-cmd --zone=public --permanent --add-port=80/tcp
          firewall-cmd --zone=public --permanent --add-port=443/tcp
          firewall-cmd --zone=public --permanent --add-port=4443/tcp
          # firewall-cmd --zone=public --add-masquerade
          firewall-cmd --reload
          echo "Firewalld rules added..."

          # download
          echo "Downloading Harbor installer..."
          curl -L ${var.installer.url} -o $$${harbor_installer_filename}
          echo "${var.installer.sha256sum} $$${harbor_installer_filename}" | sha256sum -c
          tar xzvf $$${harbor_installer_filename} -C /tmp
          rsync -a $$${harbor_installer_tmp_dir}/harbor/ ${local.harbor_dir_path}
          echo "Harbor installer downloaded ..."

          # workaround
          # https://github.com/goharbor/harbor/issues/18083
          sed -i "s@-v \$config_dir:/config \\\@-v \$config_dir:/config:z \\\@" ${local.harbor_dir_path}/prepare

          # install
          echo "Installing Harbor..."
          ${local.harbor_dir_path}/install.sh ${join(" ", var.installer.parameters)}
          echo "Harbor installed..."
systemd:
  units:
    - name: install-harbor.service
      enabled: true
      contents: |
        [Unit]
        Description=Install Harbor
        # We run before `zincati.service` to avoid conflicting rpm-ostree
        # transactions.
        Before=zincati.service
        Wants=network-online.target
        After=network-online.target
        After=additional-rpms.service
        After=install-certbot.service
        ConditionPathExists=/usr/local/bin/harbor-installer.sh
        ConditionPathExists=!/var/lib/%N.done
        StartLimitInterval=30
        StartLimitBurst=3

        [Service]
        Type=oneshot
        RemainAfterExit=yes
        Restart=on-failure
        RestartSec=5
        TimeoutStartSec=20
        ExecStart=/usr/local/bin/harbor-installer.sh
        ExecStart=/bin/touch /var/lib/%N.done

        [Install]
        WantedBy=multi-user.target
TEMPLATE
}

module "butane_snippet_install_certbot" {
  count = var.certbot != null ? 1 : 0

  source  = "krestomatio/butane-snippets/ct//modules/certbot"
  version = "0.0.12"

  domain       = var.external_fqdn
  http_01_port = var.certbot.http_01_port
  post_hook    = local.post_hook
  agree_tos    = var.certbot.agree_tos
  staging      = var.certbot.staging
  email        = var.certbot.email
}
