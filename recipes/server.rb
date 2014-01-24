# Set up the package repository.
case node["platform"].downcase
when "ubuntu", "debian"
    include_recipe "apt"

    apt_repository "rstudio-cran" do
        uri node['rstudio']['apt']['uri']
        keyserver node['rstudio']['apt']['keyserver']
        key node['rstudio']['apt']['key']
        distribution "#{node['lsb']['codename']}/"
    end

    package "r-base" do
        action :install
    end

    package "psmisc"
    package "libssl0.9.8"
    package "libapparmor1"

    if node["kernel"]["machine"] == "x86_64"

        remote_file "#{Chef::Config[:file_cache_path]}/#{node['rstudio']['downloadURL'].split('/').last}" do
          source "#{node['rstudio']['downloadURL']}"
          checksum node['rstudio']['downloadchecksum']
          mode "0644"
        end


        dpkg_package "rstudio-server" do
                    source "#{Chef::Config[:file_cache_path]}/#{node['rstudio']['downloadURL'].split('/').last}"
            action :install
        end

    else

        raise ArgumentError, "Only 64bit currently supported."

    end

end

service "rstudio-server" do
    provider Chef::Provider::Service::Upstart
    supports :start => true, :stop => true, :restart => true
    action :start
end

template "/etc/rstudio/rserver.conf" do
    source "etc/rstudio/rserver.conf.erb"
    mode 0644
    owner "root"
    group "root"
    notifies :restart, "service[rstudio-server]"
end

template "/etc/rstudio/rsession.conf" do
    source "etc/rstudio/rsession.conf.erb"
    mode 0644
    owner "root"
    group "root"
    notifies :restart, "service[rstudio-server]"
end
