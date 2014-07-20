# 負荷の高いユーザリストも通常のユーザも
# レスポンスを返した後は次のリクエストに
# 備える必要があり、プロセスは使いまわす
# ので一旦ここで通常のリソースグループに
# 全てのユーザを参加させるようにする

c = Cgroup::CPU.new "httpd"
if c.exist?
  c.modify
else
  c.create
end
c.attach
