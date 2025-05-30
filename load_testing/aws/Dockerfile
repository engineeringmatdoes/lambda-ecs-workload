FROM public.ecr.aws/aws-cli/aws-cli

ENTRYPOINT [ "/entrypoint.sh" ]

RUN yum install -y tar gzip \
    && yum clean all \
    && curl https://github.com/grafana/k6/releases/download/v0.55.0/k6-v0.55.0-linux-arm64.tar.gz -L | tar -zx \
    && mv k6*/k6 /usr/local/bin/k6 \
    && rm -rf k6*

COPY entrypoint.sh /entrypoint.sh

COPY *.js /aws
