#!/bin/bash

rpath="$(readlink ${BASH_SOURCE})"
if [ -z "$rpath" ];then
    rpath="${BASH_SOURCE}"
fi

this="$(cd $(dirname $rpath) && pwd)"
cd $this

dest=/etc/v2ray
service=/etc/systemd/system


usage(){
    cat<<-EOF
		Usage: $(basename $0) client|server options

		client options:
    		mkconfig

		server options:
    		ws|websocket
    		kcp|mkcp
    		tls
    		tls-ws-web
			EOF
    exit 0
}
installV2ray(){
    if [ ! -e /usr/bin/v2ray ];then
        bash <(curl -L -s https://install.direct/go.sh)
    fi
}

installPem(){
    if [ ! -e v2ray.pem ];then
        echo "tls need v2ray.pem file"
        exit 1
    fi
    if [ ! -e v2ray.key ];then
        echo "tls need v2ray.key file"
        exit 1
    fi
    cp v2ray.pem $dest
    cp v2ray.key $dest
}
installNginx(){
    if ! command -v nginx >/dev/null 2>&1;then
        echo "need nginx"
        exit 1
    fi
    cp tls-ws-web/v2ray-nginx.conf /etc/nginx/conf.d
    echo "You may need to delete PIDFile option in nginx.service file"
}
#TODO generate uuid for config file
server(){
    case $1 in
        ws|websocket)
            installV2ray
            cp ws/server-ws.json $dest
            cp ws/v2ray-ws.service $service
            ;;
        kcp|mkcp)
            installV2ray
            cp kcp/server-kcp.json $dest
            cp kcp/v2ray-kcp.service $service
            ;;
        tls)
            installV2ray
            installPem
            cp tls/server-tls.json $dest
            cp tls/v2ray-tls.service $service
            ;;
        tls-ws-web)
            installV2ray
            installPem
            installNginx
            cp tls-ws-web/server-tls-ws-web.json $dest
            cp tls-ws-web/v2ray-tls-ws-web.service $service
            ;;
        *)
            usage
            ;;
    esac

}

client(){
    case $1 in
        mkconfig)
            echo TODO
            ;;
        *)
            usage
            ;;
    esac
}
if [ -z $2 ];then
    usage
fi

case $1 in
    server)
        server $2
        ;;
    client)
        client $2
        ;;
    *)
        usage
esac
