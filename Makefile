.PHONY: docker link setup gateway ci

docker:
	docker build -t fractalnetworks/selfhosted-gateway:latest ./src/gateway/
	docker build -t fractalnetworks/gateway-link:latest ./src/gateway-link/
	docker build -t fractalnetworks/gateway-client:latest ./src/client-link/
	docker build -t fractalnetworks/gateway-cli:latest ./src/create-link/

setup:
	docker network create gateway

gateway: docker
	docker run --network gateway --restart unless-stopped -p 80:80 -p 443:443 -e NGINX_ENVSUBST_OUTPUT_DIR=/etc/nginx -it -d fractalnetworks/selfhosted-gateway:latest

link:
	docker run -e SSH_AGENT_PID=$$SSH_AGENT_PID -e SSH_AUTH_SOCK=$$SSH_AUTH_SOCK -v $$SSH_AUTH_SOCK:$$SSH_AUTH_SOCK --rm -it fractalnetworks/gateway-cli:latest $(GATEWAY) $(FQDN) $(EXPOSE)

link-macos:
	docker run -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock -e SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" --rm -it fractalnetworks/gateway-cli:latest $(GATEWAY) $(FQDN) $(EXPOSE}

ci:
	ssh-keygen -t ed25519 -f ./ci/gateway-sim-key -N ""
	docker build -t fractalnetworks/gateway-sim -f ./ci/Dockerfile ./ci
