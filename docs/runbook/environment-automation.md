# Environment Variable Automation

This note summarizes how the chaos-lab stack injects sensitive configuration
(such as the RDS master password) across the three execution environments.

## 1. Local development (.env + Makefile)

1. Copy `.env.example` to `.env` and adjust the values.
2. Run make targets as usual (`make onoff-apply`, `make onoff-destroy`, etc.).

The Makefile automatically loads `.env` (if present) and exports every variable
so that child processes (Terraform, kubectl, aws CLI) inherit them. The file is
already ignored via `.gitignore`, so credentials never reach the repository.

```bash
cp .env.example .env
aws ssm put-parameter --name /chaos-lab/rds/password \
  --type SecureString --value 'super-secret' --overwrite
make onoff-apply
```

## 2. Dashboard EC2 (systemd EnvironmentFile)

The dashboard EC2 instance usually runs as a systemd service. You can attach the
same variables by creating an override file:

```bash
sudo mkdir -p /etc/systemd/system/dashboard.service.d
cat <<'ENV' | sudo tee /etc/systemd/system/dashboard.service.d/env.conf
[Service]
Environment="AWS_REGION=ap-northeast-2"
Environment="DEFAULT_EKS_REGION=ap-northeast-2"
Environment="RDS_PASSWORD_SSM_PARAMETER=/chaos-lab/rds/password"
ENV

sudo systemctl daemon-reload
sudo systemctl restart dashboard
```

The service (and any subprocess calling `scripts/onoff/apply.sh` or
`scripts/onoff/destroy.sh`) receives the values automatically on every restart.

If you prefer session-based exports, drop a shell snippet in
`/etc/profile.d/chaoslab.sh` instead.

## 3. GitHub Actions

Both toggle workflows already read `RDS_PASSWORD_SSM_PARAMETER` from repository
secrets/variables:

```yaml
env:
  AWS_REGION: ${{ vars.AWS_REGION }}
  DEFAULT_EKS_REGION: ${{ vars.AWS_REGION }}
  RDS_PASSWORD_SSM_PARAMETER: ${{ secrets.RDS_PASSWORD_SSM_PARAMETER || vars.RDS_PASSWORD_SSM_PARAMETER }}
```

To enable the flow:

1. Store the secure string in SSM (`/chaos-lab/rds/password`).
2. Create a secret (or repository variable) named `RDS_PASSWORD_SSM_PARAMETER`
   whose value is the parameter path.

The scripts will resolve the SSM parameter at runtime and export
`TF_VAR_rds_password` automatically. When running locally you can override the
value by exporting `TF_VAR_rds_password` if SSM access is not available.

---

With this setup the same script works in all environments, and the password
never needs to live in version control.
