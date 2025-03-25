FROM golang:latest
WORKDIR /go/src/github.com/google/huproxy
COPY . .
RUN mkdir /app
RUN CGO_ENABLED=0 GOOS=linux go build -a -o /app ./cmd/huproxy
RUN CGO_ENABLED=0 GOOS=linux go build -a -o /app ./cmd/huproxyclient

FROM quay.io/jupyter/scipy-notebook:lab-4.3.6

USER root

# Supervisor and sshd
RUN apt-get update && apt-get install -yq supervisor openssh-server \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Server Proxy
RUN pip --no-cache-dir install jupyter-server-proxy && \
    jupyter server extension enable --sys-prefix jupyter_server_proxy

COPY . /tmp/resource

# Scripts for Jenkins/Supervisor
RUN mkdir -p /usr/local/bin/before-notebook.d && \
    cp /tmp/resource/conf/onboot/* /usr/local/bin/before-notebook.d/ && \
    chmod +x /usr/local/bin/before-notebook.d/* && \
    cp -fr /tmp/resource/conf/supervisor /opt/

# Boot scripts to perform /usr/local/bin/before-notebook.d/* on JupyterHub
RUN mkdir -p /opt/huproxy/original/bin/ && \
    mkdir -p /opt/huproxy/bin/ && \
    mv /opt/conda/bin/jupyterhub-singleuser /opt/huproxy/original/bin/jupyterhub-singleuser && \
    mv /opt/conda/bin/jupyter-notebook /opt/huproxy/original/bin/jupyter-notebook && \
    mv /opt/conda/bin/jupyter-lab /opt/huproxy/original/bin/jupyter-lab && \
    cp /tmp/resource/conf/bin/jupyter* /opt/conda/bin/ && \
    cp /tmp/resource/conf/bin/*.sh /opt/huproxy/bin/ && \
    chmod +x /opt/conda/bin/jupyterhub-singleuser /opt/conda/bin/jupyter-notebook /opt/conda/bin/jupyter-lab \
        /opt/huproxy/bin/*

# Configuration for Server Proxy
RUN cat /tmp/resource/conf/jupyter_notebook_config.py >> $CONDA_DIR/etc/jupyter/jupyter_notebook_config.py
# RUN chown $NB_USER /tmp/resource/*.ipynb

COPY --from=0 /app/ /opt/huproxy/bin/

USER $NB_USER

# # Replace contents
# RUN rm /home/$NB_USER/*.ipynb /home/$NB_USER/*.md && \
#     rm -fr /home/$NB_USER/images /home/$NB_USER/resources && \
#     cp /tmp/resource/*.md /home/$NB_USER/ && \
#     cp /tmp/resource/*.ipynb /home/$NB_USER/ && \
#     cp -fr /tmp/resource/images /home/$NB_USER/
