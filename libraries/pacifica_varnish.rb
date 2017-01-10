require 'digest'
# pacifica cookbook module
module PacificaCookbook
  # Manages the Pacifica varnish service
  class PacificaVarnish < ChefCompat::Resource
    property :name, String, name_property: true
    property :backend_hosts, Array, default: []
    property :listen_port, Integer, default: 6081
    property :repo_opts, Hash, default: {}
    property :config_opts, Hash, default: {}
    property :template_opts, Hash, default: {}

    def vlc_hosts
      ret = {}
      backend_hosts.each do |host|
        unique = Digest.hexencode Digest::MD5.new.digest host
        ret["host#{unique[0..5]}"] = host
      end
      ret
    end

    resource_name :pacifica_varnish

    default_action :create

    action :create do
      include_recipe 'chef-sugar'
      include_recipe 'selinux_policy::install'
      varnish_repo name do
        repo_opts.each do |key, attr|
          send(key, attr)
        end
      end
      package 'varnish'
      varnish_config 'default' do
        listen_address '0.0.0.0'
        admin_listen_address '127.0.0.1'
        listen_port new_resource.listen_port
        config_opts.each do |key, attr|
          send(key, attr)
        end
      end
      selinux_policy_port listen_port do
        protocol 'tcp'
        secontext 'varnishd_port_t'
        only_if { rhel? }
      end
      selinux_policy_boolean 'varnishd_connect_any' do
        value true
        only_if { rhel? }
      end
      vcl_template 'default.vcl' do
        cookbook 'pacifica'
        source 'backends.vcl.erb'
        variables(
          endpoint_name: new_resource.name,
          backend_hosts: vlc_hosts
        )
        template_opts.each do |key, attr|
          send(key, attr)
        end
      end
      service 'varnish' do
        action [:enable, :start]
      end
      file '/var/log/varnish/varnishlog.log' do
        action [:create_if_missing]
      end
      execute 'restorecon /var/log/varnish/*' do
        only_if { rhel? }
      end
      varnish_log 'default'
    end
  end
end
