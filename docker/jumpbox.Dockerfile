FROM rustlang/rust:nightly-bullseye-slim
ARG ZK_EVM_BRANCH_OR_COMMIT
RUN apt-get update \
  && apt-get install --yes build-essential curl git procps libjemalloc-dev libjemalloc2 make libssl-dev pkg-config \
  && curl --location --output /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 \
  && chmod +x /usr/local/bin/jq \
  && git clone https://github.com/0xPolygonZero/zk_evm.git /opt/zk_evm \
  && cd /opt/zk_evm \
  && git checkout $ZK_EVM_BRANCH_OR_COMMIT \
  && env RUSTFLAGS='-C target-cpu=native -Zlinker-features=-lld' cargo build --release \
  && cp \
    /opt/zk_evm/target/release/leader \
    /opt/zk_evm/target/release/rpc \
    /opt/zk_evm/target/release/verifier \
    /opt/zk_evm/target/release/worker \
    /usr/local/bin/ \
  && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && apt-get update \
  && apt-get install -y python3 python3-pip python3-venv screen google-cloud-cli google-cloud-cli-gke-gcloud-auth-plugin \
  && git clone https://github.com/rebelArtists/prover_cli.git /opt/prover_cli \  
  && cd /opt/prover_cli \
  && pip install -r requirements.txt && pip install -e .
