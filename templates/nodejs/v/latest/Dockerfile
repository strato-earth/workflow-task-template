FROM public.ecr.aws/lambda/nodejs:20 AS builder
WORKDIR /build
COPY . .
RUN npm install
RUN npm run format
RUN npm run lint
RUN npm run build
RUN npm run test

FROM public.ecr.aws/lambda/nodejs:20

COPY --from=builder /build/dist/strato_task.mjs /var/task/
COPY src/*.sh /var/task/
COPY entrypoint.sh /var/task/entrypoint.sh
RUN chmod +x /var/task/*.sh

ENTRYPOINT ["/var/task/entrypoint.sh"]
