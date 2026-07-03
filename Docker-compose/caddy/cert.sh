mkdir -p certs
# 生成自签名证书（仅示例，可根据需求修改参数）
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/key.pem \
  -out certs/cert.pem \
  -subj "/CN=*.xxx.com"
