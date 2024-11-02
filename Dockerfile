FROM public.ecr.aws/lambda/nodejs:20

COPY src/lambda-function.js ${LAMBDA_TASK_ROOT}
