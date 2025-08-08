# web-ssh

一个支持ipv6的在线webssh服务.


原仓库地址：

```
https://github.com/huashengdun/webssh
```




## 推荐安装 ##

建议自建一个目录再来运行一键命令。

**一键命令**

```
curl -fsSL https://raw.githubusercontent.com/xymn2023/web-ssh/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh
```

**说明**

本人为对原项目做任何信息的修改，只是为了减少安装时的步骤做了个一键脚本，放心食用。

**看到如下提示：**

```
Finished processing dependencies for webssh==1.6.3
[SUCCESS] WebSSH 安装完成
[INFO] 创建启动脚本...
[SUCCESS] 启动脚本创建完成: start_webssh.sh
[INFO] 创建后台启动脚本...
[SUCCESS] 后台启动脚本创建完成: start_webssh_background.sh
[SUCCESS] WebSSH 安装完成！

使用说明:
1. 前台启动: ./start_webssh.sh
2. 后台启动: ./start_webssh_background.sh
3. 直接启动: wssh --fbidhttp=False
4. 后台启动: nohup wssh --fbidhttp=False &

访问地址: http://103.103.103.103:8888

注意事项:
- 确保 8888 端口未被占用
- 如果遇到 403 错误，使用 --fbidhttp=False 参数
- 后台运行时，日志保存在 webssh.log 文件中

```

那就说明项目安装好了，可自行选择使用说明进行启动，需要进入webssh目录执行启动命令。
