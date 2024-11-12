FROM public.ecr.aws/lambda/nodejs:20

RUN dnf install -y nginx && dnf clean all

COPY src/nginx-start.sh /nginx-start.sh

COPY src/nginx.conf /etc/nginx/nginx.conf

COPY src/lambda-function.js ${LAMBDA_TASK_ROOT}

COPY src/static-app/build /static
