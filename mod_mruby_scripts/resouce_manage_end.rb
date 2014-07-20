# 負荷の高いユーザリストも通常のユーザもレスポンスを返した後は次のリクエストに
# 備える必要があり、プロセスは使いまわすので一旦ここで通常のリソースグループに
# 全てのユーザを参加させるようにする
# ここであえてhttpdグループに再度参加させるようにしているのはlibcgroupのバグ？
# によりrootグループに参加できないため

c = Cgroup::CPU.new "httpd"
if c.exist?
  c.modify
else
  c.create
end
c.attach
