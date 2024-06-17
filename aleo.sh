#!/bin/bash

# 节点安装功能
function install_node() {

	read -p "请输入客户端名称:" client_name
	sudo apt update && sudo apt upgrade
	sudo apt install -y npm snap screen
	# 安装 Rust v1.66+
	sudo snap install rustup --classic
	rustup default stable
	
	# 克隆snarkOS库
	git clone https://github.com/AleoHQ/snarkOS.git --depth 1
	cd $HOME/snarkOS
	./build_ubuntu.sh
	cargo install --locked --path .
	
	# 运行客户端
	screen -dmS aleo_$client_name bash -c "./run-client.sh"
	export PATH=$HOME/.cargo/bin/snarkos:$PATH
	echo 'export PATH=$HOME/.cargo/bin/snarkos:$PATH' >> $HOME/.bashrc
	source $HOME/.bashrc
	echo "部署完成..."
	
}

# 生成 Aleo 帐户地址
function create_account(){
	echo "请保存好以下密钥："
	source $HOME/.bashrc
	snarkos account new
}

function start_prover(){
    read -p "请输入证明者名称:" prover_name
    read -p "请输入秘钥:" input_string
    screen -dmS aleo_$prover_name bash -c "cd $HOME/snarkOS; echo \"$input_string\" | ./run-prover.sh"
    echo "证明者节点已启动..."
}

# 查看日志
function view_logs(){
	# 获取当前运行的screen会话列表
	screens=$(screen -ls | grep -oP '\t\K[\d]+\.[^\s]+')
	# 检查是否有screen会话
	if [ -z "$screens" ]; then
	    echo "没有找到正在运行的screen会话。"
	    exit 1
	fi
	
	# 显示screen会话列表供用户选择
	echo "检测到以下screen会话："
	echo "$screens"
	echo ""
	
	# 提示用户输入
	read -p "请输入您想查看的screen会话名称: " choice
	
	# 检查用户输入是否为有效会话
	if [[ $screens == *$choice* ]]; then
	    # 连接到用户选择的screen会话
	    echo "3秒后显示，按键盘 Ctra + a + d 退出"; sleep 3
	    screen -r $choice
	else
	    echo "输入错误或会话不存在。"
	    exit 1
	fi
}

# 卸载节点
function uninstall_node(){
    echo "你确定要卸载nubit节点程序吗？这将会删除所有相关的数据。[Y/N]"
    read -r -p "请确认: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "开始卸载节点程序..."
            screen -ls | grep 'aleo_' | cut -d. -f1 | awk '{print $1}' | xargs -I {} screen -X -S {} quit
			rm -rf .cargo 
            echo "节点程序卸载完成。"
            ;;
        *)
            echo "取消卸载操作。"
            ;;
    esac
}

# 主菜单
function main_menu() {
	while true; do
	    clear
	    echo "===================Aleo Foundation 一键部署脚本==================="
		echo "沟通电报群：https://t.me/lumaogogogo"
		echo "官方推荐：32C32G128G；推荐配置：4C4G100G"
	    echo "请选择要执行的操作:"
	    echo "1. 部署节点 install_node"
	    echo "2. 创建账号 create_account"
	    echo "3. 启动证明者节点 start_prover"
	    echo "4. 查看日志 view_logs"
	    echo "1618. 卸载节点 uninstall_node"
	    echo "0. 退出脚本 exit"
	    read -p "请输入选项: " OPTION
	
	    case $OPTION in
	    1) install_node ;;
	    2) create_account ;;
	    3) start_prover ;;
	    4) view_logs ;;
	    1618) uninstall_node ;;
	    0) echo "退出脚本。"; exit 0 ;;
	    *) echo "无效选项，请重新输入。"; sleep 3 ;;
	    esac
	    echo "按任意键返回主菜单..."
        read -n 1
    done
}

main_menu