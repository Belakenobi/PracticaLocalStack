# Bucket S3 seguro con Terraform + LocalStack

Práctica de Ciberseguridad · Fase 1 · Infraestructura como Código (IaC).

Se despliega un bucket S3 **simulado** con Terraform sobre LocalStack (Docker), con cifrado AES-256 (SSE-S3) y los cuatro controles de bloqueo de acceso público. Todo corre en `localhost`: no se usa AWS real ni se necesita cuenta AWS.

## Recursos que crea Terraform (3)

| Recurso | Configuración |
|---|---|
| `aws_s3_bucket` | `actividad3-seguro-local` |
| `aws_s3_bucket_server_side_encryption_configuration` | SSE-S3 `AES256` |
| `aws_s3_bucket_public_access_block` | `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets` = `true` |

## Requisitos

- Docker y Docker Compose v2
- Terraform
- AWS CLI v2
- Cuenta gratuita de LocalStack (plan **Hobby**) y su token de autenticación

## Archivos

- `compose.yaml`: levanta LocalStack con el puerto 4566 expuesto solo en `127.0.0.1` y S3 habilitado.
- `providers.tf`: provider AWS con región `us-east-1`, credenciales ficticias y endpoint `http://localhost:4566`.
- `main.tf`: bucket, cifrado y bloqueo de acceso público.
- `.env.example`: plantilla de la variable del token (vacía).
- `.gitignore`: excluye `.env`, `.terraform/`, `*.tfstate*` y `prueba.txt`.

## Ejecución

1. Crear el archivo `.env` con tu token (no se sube al repositorio):

```bash
read -s "LS_TOKEN?Pega tu token y presiona Enter: "
echo "LOCALSTACK_AUTH_TOKEN=$LS_TOKEN" > .env
unset LS_TOKEN
```

2. Levantar LocalStack y comprobar que esté saludable:

```bash
docker compose up -d
sleep 30
docker ps
curl -s http://localhost:4566/_localstack/health | jq .services.s3
```

3. Desplegar con Terraform:

```bash
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

4. Verificar con AWS CLI (credenciales ficticias):

```bash
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="us-east-1"
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 s3api get-bucket-encryption --bucket actividad3-seguro-local
aws --endpoint-url=http://localhost:4566 s3api get-public-access-block --bucket actividad3-seguro-local
echo "Prueba de seguridad" > prueba.txt
aws --endpoint-url=http://localhost:4566 s3 cp prueba.txt s3://actividad3-seguro-local/
aws --endpoint-url=http://localhost:4566 s3 ls s3://actividad3-seguro-local/
curl -i http://localhost:4566/actividad3-seguro-local/prueba.txt
aws --endpoint-url=http://localhost:4566 s3api get-bucket-policy --bucket actividad3-seguro-local
```

5. Dashboard: abrir `https://app.localstack.cloud`, crear una instancia con `http://localhost:4566` y entrar a Resource Browser → S3.

6. Limpiar:

```bash
docker compose down -v
```

## Resultados y observaciones

- El plan crea **3 recursos** y el `apply` termina con `3 added`.
- El cifrado consultado es `AES256` y los **cuatro** controles de bloqueo público aparecen en `true`.
- La descarga **anónima** (sin firmar) devolvió `200 OK`. En AWS real, con estos bloqueos activos, se esperaría `403 AccessDenied`. Se trata como una **limitación del simulador**, no como confirmación de que el bucket sea público.
- `NoSuchBucketPolicy` solo indica que el bucket no tiene política adjunta; no confirma ni descarta exposición pública.
- LocalStack guarda el estado en memoria: al reiniciar el contenedor hay que volver a ejecutar `terraform apply`.

## Seguridad

- No se publican tokens, contraseñas, `.env` ni archivos `*.tfstate`.
- Las credenciales usadas en `providers.tf` y en la CLI son ficticias.
- Ningún comando apunta a AWS real.
