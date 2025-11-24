# External Secrets Setup עם AWS Secrets Manager

## מה נוצר:

1. **External Secrets Operator** - Helm chart שמוסיף את ה-operator לקלאסטר
2. **IRSA Role** - IAM role עם הרשאות ל-Secrets Manager
3. **ServiceAccount** - ב-namespace `ecommerce` עם IRSA annotation
4. **SecretStore** - מגדיר איך להתחבר ל-AWS Secrets Manager
5. **ExternalSecret** - מגדיר איזה secret לקחת ומה לעשות איתו

## מה צריך לעשות:

### 1. ודא שה-secret קיים ב-AWS Secrets Manager:

```bash
aws secretsmanager describe-secret \
  --secret-id dohelmoto/ecommerce/dev/secrets \
  --region us-east-1
```

אם הוא לא קיים, צור אותו:

```bash
aws secretsmanager create-secret \
  --name dohelmoto/ecommerce/dev/secrets \
  --description "Ecommerce application secrets for dev environment" \
  --secret-string '{
    "DATABASE_URL": "postgresql://ecommerce_user:password@postgres-service:5432/ecommerce_db",
    "SECRET_KEY": "your-secret-key-here",
    "GOOGLE_CLIENT_ID": "your-google-client-id",
    "GOOGLE_CLIENT_SECRET": "your-google-client-secret",
    "AWS_ACCESS_KEY_ID": "your-aws-access-key",
    "AWS_SECRET_ACCESS_KEY": "your-aws-secret-key",
    "AWS_BUCKET_NAME": "your-s3-bucket-name",
    "OPENAI_API_KEY": "your-openai-key",
    "STRIPE_SECRET_KEY": "your-stripe-secret-key",
    "STRIPE_PUBLISHABLE_KEY": "your-stripe-publishable-key",
    "POSTGRES_PASSWORD": "your-postgres-password",
    "REACT_APP_STRIPE_PUBLISHABLE_KEY": "your-stripe-publishable-key"
  }' \
  --region us-east-1
```

### 2. הרץ terraform apply:

```bash
cd ~/Terraform/dev
terraform init
terraform plan
terraform apply
```

זה ייצור:
- External Secrets Operator
- IRSA role
- Namespace `ecommerce`
- ServiceAccount עם IRSA annotation
- SecretStore
- ExternalSecret

### 3. בדוק שהכל עובד:

```bash
# בדוק שה-External Secrets Operator רץ
kubectl get pods -n external-secrets

# בדוק שה-SecretStore נוצר
kubectl get secretstore -n ecommerce

# בדוק שה-ExternalSecret נוצר
kubectl get externalsecret -n ecommerce

# בדוק שה-Kubernetes Secret נוצר (זה יקרה אוטומטית)
kubectl get secret ecommerce-secrets -n ecommerce

# בדוק את ה-logs של External Secrets
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

### 4. האפליקציה תשתמש ב-Secret אוטומטית:

ה-`backend.yaml` כבר מוגדר להשתמש ב-`ecommerce-secrets`, אז הוא יעבוד אוטומטית אחרי שה-ExternalSecret ייצור את ה-Secret.

## איך זה עובד:

1. **External Secrets Operator** רץ בקלאסטר
2. **ExternalSecret** resource מגדיר איזה secret לקחת מ-AWS Secrets Manager
3. ה-Operator קורא את ה-secret מ-AWS דרך ה-IRSA role
4. ה-Operator יוצר Kubernetes Secret בשם `ecommerce-secrets`
5. ה-Deployment משתמש ב-Secret כרגיל דרך `secretKeyRef`

## עדכון Secrets:

כדי לעדכן secret:
1. עדכן את ה-secret ב-AWS Secrets Manager (דרך Console או CLI)
2. ה-ExternalSecret יתרענן אוטומטית (כל שעה לפי `refreshInterval`)
3. או סנכרן ידנית:
```bash
kubectl annotate externalsecret ecommerce-secrets -n ecommerce force-sync=$(date +%s) --overwrite
```

## פתרון בעיות:

### אם ה-Secret לא נוצר:
```bash
# בדוק את ה-logs
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets

# בדוק את ה-ExternalSecret status
kubectl describe externalsecret ecommerce-secrets -n ecommerce

# בדוק שה-IRSA role קיים
kubectl describe serviceaccount external-secrets -n ecommerce
```

### אם יש בעיות הרשאות:
```bash
# בדוק שה-IRSA role יש לו את ה-policy
aws iam get-role-policy --role-name external-secrets-... --policy-name SecretsManagerReadWrite

# בדוק שה-secret קיים ב-AWS
aws secretsmanager describe-secret --secret-id dohelmoto/ecommerce/dev/secrets
```

