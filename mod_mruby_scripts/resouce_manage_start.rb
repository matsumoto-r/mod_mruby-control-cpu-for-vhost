# とりあえずはCPUのみ実装、必要であればI/Oも実装

class Apache
  class Resource
    attr_reader :heavy_hosts, :most_heavy_hosts

    def initialize config
      @heavy_hosts = create_list config[:heavy_host_file]
      @most_heavy_hosts = create_list config[:most_heavy_host_file]
    end

    def self.attach_cgroup c, name=nil
      if c.exist?
        c.modify
      else
        c.create
      end
      c.attach
      Apache.log Apache::APLOG_INFO, "attached #{name} cgroup" if ! name.nil?
    end

    def create_list filename
      list = Array.new
      if File.exists? filename
        File.open filename do |f|
          while line = f.gets
            list << line.chomp
          end
        end
      else
        Apache.log Apache::APLOG_NOTICE, "not found list file: #{filename}"
      end
      list
    end
  end
end

list_dir = "/etc/httpd/conf.d/mod_mruby_scripts/list/"
heavy_host_file = File.join list_dir, "heavy_host.list"
most_heavy_host_file = File.join list_dir, "most_heavy_host.list"

config = {
  :heavy_host_file => heavy_host_file,
  :most_heavy_host_file => most_heavy_host_file,
}

resource = Apache::Resource.new config
r = Apache::Request.new

if resource.most_heavy_hosts.include? r.hostname
  # most_heavy_hosts
  # 特に負荷の高いユーザリストが参加させられるリソースグループ
  # 1コアの100％固定でしか使えない、全タスクが1コア内で処理
  c = Cgroup::CPU.new "httpd-static-limited"
  c.cfs_quota_us = 100000
  Apache::Resource.attach_cgroup c, "httpd-static-limited"
elsif resource.heavy_hosts.include? r.hostname
  # heavy_hosts
  # 負荷の高いユーザリストが参加させられるリソースグループの設定
  # 全CPUの25%（コア含む）のリソースを分配、コアが24個の場合最大6コア内で分配
  # httpd グループと競合しない場合は100％(全コア)使用
  c = Cgroup::CPU.new "httpd-limited"
  c.shares = 25
  Apache::Resource.attach_cgroup c, "httpd-limited"
else
  # 通常のユーザが参加させられるリソースグループの設定
  # 全CPUの75%（コア含む）のリソースを分配、コアが24個の場合最大18コア内で分配
  # httpd-limited グループと競合しない場合は100％(全コア)使用
  c = Cgroup::CPU.new "httpd"
  c.shares = 75
  Apache::Resource.attach_cgroup c, "httpd"
end

