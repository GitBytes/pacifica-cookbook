include_recipe 'apache2'
include_recipe 'apache2::mod_rewrite'
include_recipe 'apache2::mod_proxy'
include_recipe 'apache2::mod_proxy_fcgi'
apache_site '000-default' do
  enable false
end
template "#{node['apache']['dir']}/sites-available/pacifica.conf" do
  source 'pacifica.conf.erb'
  mode '0644'
  if File.symlink?("#{node['apache']['dir']}/sites-enabled/pacifica.conf")
    notifies :reload, 'service[apache2]'
  end
end
apache_site 'pacifica'
