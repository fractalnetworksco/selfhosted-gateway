.PHONY: docker link setup gateway

docker:
	docker build -t fractalnetworks/selfhosted-gateway:latest -f ./gateway/Dockerfile.gateway gateway/
	docker build -t fractalnetworks/gateway-link:latest -f ./gateway/Dockerfile.gateway-link gateway/
	docker build -t fractalnetworks/gateway-client:latest -f ./gateway/Dockerfile.gateway-client gateway/
	docker build -t fractalnetworks/gateway-cli:latest -f ./gateway/Dockerfile gateway/

setup:
	docker network create gateway

gateway: docker
	docker run --network gateway --restart unless-stopped -p 80:80 -p 443:443 -e NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx -it -d fractalnetworks/selfhosted-gateway:latest

link:
	docker run -e SSH_AGENT_PID=$$SSH_AGENT_PID -e SSH_AUTH_SOCK=$$SSH_AUTH_SOCK -v $$SSH_AUTH_SOCK:$$SSH_AUTH_SOCK --rm -it fractalnetworks/gateway-cli:latest $(GATEWAY) $(FQDN) $(EXPOSE)


